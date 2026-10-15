import UIKit

/// Utility für Bildoptimierung vor dem Upload.
/// 
/// **Ziele:**
/// - Maximale Dateigröße: 2MB
/// - Maximale Auflösung: 1920x1080 (Full HD)
/// - Intelligente Komprimierung mit schrittweiser Qualitätsreduzierung
struct ImageOptimizer {
    /// Maximale Dateigröße in Bytes (2MB)
    static let maxFileSize: Int = 2 * 1024 * 1024
    
    /// Maximale Bildbreite in Pixeln
    static let maxWidth: CGFloat = 1920
    
    /// Maximale Bildhöhe in Pixeln
    static let maxHeight: CGFloat = 1080
    
    /// Optimiert ein Bild für den Upload:
    /// 1. Skaliert auf max. 1920x1080 (aspect fit)
    /// 2. Komprimiert mit intelligenter Qualitätsanpassung bis max. 2MB
    ///
    /// - Parameter image: Das zu optimierende UIImage
    /// - Returns: Optimierte JPEG-Daten (max. 2MB)
    /// - Throws: URLError wenn das Bild nicht verarbeitet werden kann
    static func optimizeImage(_ image: UIImage) throws -> Data {
        // Schritt 1: Skaliere Bild auf max. Dimensionen (aspect fit)
        let resizedImage = resizeImageToFit(image, maxWidth: maxWidth, maxHeight: maxHeight)
        
        // Schritt 2: Intelligente Komprimierung mit schrittweiser Qualitätsreduzierung
        var compressionQuality: CGFloat = 0.85  // Start mit 85% Qualität
        var imageData: Data?
        var attempts = 0
        let maxAttempts = 10
        
        // Versuche verschiedene Qualitätsstufen, bis Datei unter 2MB ist
        while attempts < maxAttempts {
            guard let data = resizedImage.jpegData(compressionQuality: compressionQuality) else {
                throw URLError(.cannotDecodeContentData)
            }
            
            // Wenn Datei klein genug ist, fertig
            if data.count <= maxFileSize {
                imageData = data
                break
            }
            
            // Reduziere Qualität für nächsten Versuch
            compressionQuality -= 0.1
            attempts += 1
        }
        
        // Falls immer noch zu groß, verwende minimale Qualität (0.1)
        if imageData == nil || (imageData?.count ?? 0) > maxFileSize {
            guard let finalData = resizedImage.jpegData(compressionQuality: 0.1) else {
                throw URLError(.cannotDecodeContentData)
            }
            
            // Wenn selbst bei 0.1 zu groß, muss das Bild noch weiter skaliert werden
            if finalData.count > maxFileSize {
                // Skaliere auf kleinere Dimensionen (z.B. 1280x720)
                let smallerImage = resizeImageToFit(image, maxWidth: 1280, maxHeight: 720)
                guard let smallerData = smallerImage.jpegData(compressionQuality: 0.1) else {
                    throw URLError(.cannotDecodeContentData)
                }
                imageData = smallerData
            } else {
                imageData = finalData
            }
        }
        
        guard let optimizedData = imageData else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return optimizedData
    }

    /// Long-edge cap for images sent to the AI vision endpoints.
    /// 4032×3024 (12.19 MP) exceeds the backend's 12_000_000 pixel limit; 1920 on the long edge stays well under it.
    static let aiMaxEdge: CGFloat = 1920
    static let aiMaxFileSize: Int = 2 * 1024 * 1024

    /// Resizes (aspect-preserving) and JPEG-encodes an image for `/ai/chat` and `/ai/analyze-image`.
    /// Does not replace `optimizeImage` (recipe Storage uploads still use 1920×1080).
    static func optimizeForAI(_ image: UIImage) throws -> Data {
        let resized = resizeToMaxEdge(image, maxEdge: aiMaxEdge)
        return try jpegUnderLimit(resized, maxBytes: aiMaxFileSize)
    }

    /// Same as `optimizeForAI(_:UIImage)` for camera/gallery bytes (JPEG, PNG, HEIC, WebP).
    static func optimizeForAI(_ data: Data) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        return try optimizeForAI(image)
    }

    static func jpegUnderLimit(_ image: UIImage, maxBytes: Int) throws -> Data {
        var quality: CGFloat = 0.85
        var last: Data?
        for _ in 0..<8 {
            guard let data = image.jpegData(compressionQuality: quality) else {
                throw URLError(.cannotDecodeContentData)
            }
            last = data
            if data.count <= maxBytes {
                return data
            }
            quality -= 0.1
        }
        if let last, last.count <= maxBytes {
            return last
        }
        let smaller = resizeToMaxEdge(image, maxEdge: 1280)
        guard let fallback = smaller.jpegData(compressionQuality: 0.1) else {
            throw URLError(.cannotDecodeContentData)
        }
        return fallback
    }

    static func resizeToMaxEdge(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxEdge, longest > 0 else { return image }
        let scale = maxEdge / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Skaliert ein Bild auf maximale Dimensionen (aspect fit).
    /// Wenn das Bild bereits kleiner ist, wird es unverändert zurückgegeben.
    ///
    /// - Parameters:
    ///   - image: Das zu skalierende Bild
    ///   - maxWidth: Maximale Breite
    ///   - maxHeight: Maximale Höhe
    /// - Returns: Skaliertes Bild oder Original, falls bereits kleiner
    private static func resizeImageToFit(_ image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let originalSize = image.size
        
        // Wenn Bild bereits kleiner als max. Dimensionen, zurückgeben
        if originalSize.width <= maxWidth && originalSize.height <= maxHeight {
            return image
        }
        
        // Berechne Skalierungsfaktor (aspect fit)
        let widthRatio = maxWidth / originalSize.width
        let heightRatio = maxHeight / originalSize.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: originalSize.width * scaleFactor,
            height: originalSize.height * scaleFactor
        )
        
        // Rendere das skalierte Bild
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

