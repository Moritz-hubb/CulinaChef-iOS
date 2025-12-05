import Foundation
import UIKit
import SwiftUI
import CryptoKit

/// Singleton image cache with memory and disk persistence
/// Provides efficient image loading and caching for recipe photos and other images
@MainActor
final class ImageCache {
    static let shared = ImageCache()
    
    // MARK: - Configuration
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    /// Memory cache capacity (100 images max)
    private let memoryCacheCountLimit = 100
    /// Total memory cost limit (50 MB)
    private let memoryCacheTotalCostLimit = 50 * 1024 * 1024
    /// Disk cache size limit (200 MB)
    private let diskCacheSizeLimit = 200 * 1024 * 1024
    /// Cache expiration (7 days)
    private let cacheExpirationInterval: TimeInterval = 7 * 24 * 60 * 60
    
    // MARK: - Initialization
    
    private init() {
        // Setup memory cache limits
        memoryCache.countLimit = memoryCacheCountLimit
        memoryCache.totalCostLimit = memoryCacheTotalCostLimit
        
        // Setup disk cache directory
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesURL.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Create cache directory if needed
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Cleanup old cache on init
        Task {
            await cleanupExpiredCache()
        }
    }
    
    // MARK: - Public API
    
    /// Load image from cache or download if not cached
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Optional placeholder image while loading
    /// - Returns: Cached or downloaded UIImage, or nil if failed
    func image(for url: URL) async -> UIImage? {
        let cacheKey = cacheKey(for: url)
        
        // 1. Check memory cache first (fastest)
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            Logger.debug("[ImageCache] Memory hit: \(url.lastPathComponent)", category: .data)
            return cachedImage
        }
        
        // 2. Check disk cache (fast)
        if let diskImage = loadFromDisk(cacheKey: cacheKey) {
            Logger.debug("[ImageCache] Disk hit: \(url.lastPathComponent)", category: .data)
            // Store in memory for faster access next time
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString, cost: diskImage.memoryCost)
            return diskImage
        }
        
        // 3. Download from network (slow)
        Logger.debug("[ImageCache] Downloading: \(url.lastPathComponent)", category: .data)
        return await downloadAndCache(url: url, cacheKey: cacheKey)
    }
    
    /// Preload images in background (for recipe lists, etc.)
    /// Uses concurrent loading for better performance
    func preload(urls: [URL]) {
        Task {
            // Load images concurrently (up to 5 at a time)
            await withTaskGroup(of: Void.self) { group in
                for url in urls.prefix(20) { // Limit to first 20 images to avoid overwhelming
                    group.addTask {
                        _ = await self.image(for: url)
                    }
                }
            }
        }
    }
    
    /// Preload images with priority (for immediate display)
    /// Loads first N images immediately, rest in background
    func preloadPriority(urls: [URL], immediateCount: Int = 8) async {
        guard !urls.isEmpty else { return }
        
        // Split into immediate and background
        let immediateUrls = Array(urls.prefix(immediateCount))
        let backgroundUrls = Array(urls.dropFirst(immediateCount))
        
        // Load immediate images with high priority (concurrent, but wait for completion)
        await withTaskGroup(of: Void.self) { group in
            for url in immediateUrls {
                group.addTask(priority: .userInitiated) {
                    _ = await self.image(for: url)
                }
            }
        }
        
        // Load remaining images in background (don't wait)
        if !backgroundUrls.isEmpty {
            Task.detached(priority: .utility) {
                await withTaskGroup(of: Void.self) { group in
                    for url in backgroundUrls.prefix(20) {
                        group.addTask {
                            _ = await ImageCache.shared.image(for: url)
                        }
                    }
                }
            }
        }
    }
    
    /// Clear all cached images (memory + disk)
    func clearAll() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        Logger.info("[ImageCache] Cleared all cache", category: .data)
    }
    
    /// Clear expired cache entries (older than 7 days)
    func cleanupExpiredCache() async {
        let now = Date()
        let expirationDate = now.addingTimeInterval(-cacheExpirationInterval)
        
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }
        
        // Convert enumerator to array to avoid async context issues
        let fileURLs = Array(enumerator.compactMap { $0 as? URL })
        
        var deletedCount = 0
        var deletedSize = 0
        
        for fileURL in fileURLs {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modificationDate = attributes[.modificationDate] as? Date else {
                continue
            }
            
            if modificationDate < expirationDate {
                if let size = attributes[.size] as? Int {
                    deletedSize += size
                }
                try? fileManager.removeItem(at: fileURL)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            Logger.info("[ImageCache] Cleaned up \(deletedCount) expired images (\(deletedSize / 1024 / 1024) MB)", category: .data)
        }
        
        // Also check total disk cache size and remove oldest if needed
        await enforceDiskCacheLimit()
    }
    
    /// Remove image from cache
    func remove(url: URL) {
        let cacheKey = cacheKey(for: url)
        memoryCache.removeObject(forKey: cacheKey as NSString)
        let diskURL = diskCacheURL(for: cacheKey)
        try? fileManager.removeItem(at: diskURL)
    }
    
    // MARK: - Private Helpers
    
    private func cacheKey(for url: URL) -> String {
        // Use URL as cache key (MD5 hash for safety)
        return url.absoluteString.md5
    }
    
    private func diskCacheURL(for cacheKey: String) -> URL {
        return cacheDirectory.appendingPathComponent(cacheKey)
    }
    
    private func loadFromDisk(cacheKey: String) -> UIImage? {
        let fileURL = diskCacheURL(for: cacheKey)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    private func saveToDisk(image: UIImage, cacheKey: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let fileURL = diskCacheURL(for: cacheKey)
        try? data.write(to: fileURL)
    }
    
    private func downloadAndCache(url: URL, cacheKey: String) async -> UIImage? {
        do {
            // Use URLSession with optimized configuration for faster downloads
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 30
            configuration.requestCachePolicy = .returnCacheDataElseLoad
            let session = URLSession(configuration: configuration)
            
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else {
                Logger.error("[ImageCache] Invalid image data from: \(url.lastPathComponent)", category: .data)
                return nil
            }
            
            // Cache in memory immediately
            memoryCache.setObject(image, forKey: cacheKey as NSString, cost: image.memoryCost)
            
            // Cache on disk (background, non-blocking)
            Task.detached(priority: .utility) {
                await self.saveToDisk(image: image, cacheKey: cacheKey)
            }
            
            return image
        } catch {
            Logger.error("[ImageCache] Download failed: \(url.lastPathComponent)", error: error, category: .data)
            return nil
        }
    }
    
    private func enforceDiskCacheLimit() async {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else {
            return
        }
        
        // Convert enumerator to array to avoid async context issues
        let fileURLs = Array(enumerator.compactMap { $0 as? URL })
        
        var files: [(url: URL, modificationDate: Date, size: Int)] = []
        var totalSize = 0
        
        for fileURL in fileURLs {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modificationDate = attributes[.modificationDate] as? Date,
                  let size = attributes[.size] as? Int else {
                continue
            }
            
            files.append((fileURL, modificationDate, size))
            totalSize += size
        }
        
        // If total size exceeds limit, remove oldest files
        if totalSize > diskCacheSizeLimit {
            let sortedFiles = files.sorted { $0.modificationDate < $1.modificationDate }
            var removedSize = 0
            var removedCount = 0
            
            for file in sortedFiles {
                if totalSize - removedSize <= diskCacheSizeLimit {
                    break
                }
                try? fileManager.removeItem(at: file.url)
                removedSize += file.size
                removedCount += 1
            }
            
            Logger.info("[ImageCache] Disk limit enforced: removed \(removedCount) files (\(removedSize / 1024 / 1024) MB)", category: .data)
        }
    }
}

// MARK: - UIImage Extensions

private extension UIImage {
    /// Approximate memory cost of image in bytes
    var memoryCost: Int {
        guard let cgImage = cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

// MARK: - String SHA256 Extension

private extension String {
    /// Simple SHA256 hash for cache keys (using CryptoKit)
    var md5: String {
        guard let data = self.data(using: .utf8) else { return self }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - SwiftUI AsyncImage Wrapper with Caching

/// Cached async image view that uses ImageCache
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        isLoading = true
        
        // Use userInitiated priority for visible images to load faster
        Task(priority: .userInitiated) {
            if let cachedImage = await ImageCache.shared.image(for: url) {
                await MainActor.run {
                    self.image = cachedImage
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Convenience Init

extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(
            url: url,
            content: { image in image.resizable() },
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}
