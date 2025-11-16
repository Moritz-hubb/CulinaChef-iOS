# ImageCache Usage Guide

## Overview

`ImageCache` provides automatic memory + disk caching for images with:
- **Memory cache**: 100 images, 50 MB limit (NSCache, automatic eviction)
- **Disk cache**: 200 MB limit, 7-day expiration
- **Three-tier loading**: Memory → Disk → Network
- **Automatic cleanup**: Expired images removed on init

## Basic Usage

### SwiftUI with CachedAsyncImage

```swift
import SwiftUI

// Simple usage with default placeholder
CachedAsyncImage(url: recipeImageURL)
    .frame(width: 300, height: 200)
    .clipped()

// Custom content and placeholder
CachedAsyncImage(url: recipe.photoURL) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}
.frame(width: 200, height: 200)
.clipShape(RoundedRectangle(cornerRadius: 12))
```

### Programmatic Loading

```swift
// Load single image
Task {
    if let image = await ImageCache.shared.image(for: imageURL) {
        // Use UIImage
    }
}

// Preload multiple images (e.g., for recipe list)
let recipeImageURLs = recipes.compactMap { $0.photoURL }
ImageCache.shared.preload(urls: recipeImageURLs)
```

## Migration from AsyncImage

### Before
```swift
AsyncImage(url: recipe.photoURL) { image in
    image.resizable()
} placeholder: {
    Color.gray.opacity(0.2)
}
```

### After
```swift
CachedAsyncImage(url: recipe.photoURL) { image in
    image.resizable()
} placeholder: {
    Color.gray.opacity(0.2)
}
```

## Advanced Usage

### Cache Management

```swift
// Clear all cache (e.g., on sign-out)
ImageCache.shared.clearAll()

// Remove specific image
ImageCache.shared.remove(url: imageURL)

// Manual cleanup (automatic on init)
await ImageCache.shared.cleanupExpiredCache()
```

### Performance Optimization

```swift
// List preloading (onAppear)
.onAppear {
    let urls = recipes.compactMap { $0.photoURL }
    ImageCache.shared.preload(urls: urls)
}
```

## Example: Recipe List with Caching

```swift
struct RecipeListView: View {
    let recipes: [Recipe]
    
    var body: some View {
        List(recipes) { recipe in
            HStack {
                // Cached thumbnail
                CachedAsyncImage(url: recipe.photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .font(.headline)
                    Text(recipe.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            // Preload images in background
            let urls = recipes.compactMap { $0.photoURL }
            ImageCache.shared.preload(urls: urls)
        }
    }
}
```

## Example: Recipe Detail with Full-Size Image

```swift
struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack {
                // Full-size cached image
                CachedAsyncImage(url: recipe.fullSizePhotoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                    }
                }
                .frame(height: 300)
                .clipped()
                
                // Recipe content...
            }
        }
    }
}
```

## Cache Configuration

Default limits (hardcoded in `ImageCache.swift`):
- Memory: 100 images, 50 MB
- Disk: 200 MB
- Expiration: 7 days

To adjust, modify `ImageCache.swift` constants:
```swift
private let memoryCacheCountLimit = 100
private let memoryCacheTotalCostLimit = 50 * 1024 * 1024
private let diskCacheSizeLimit = 200 * 1024 * 1024
private let cacheExpirationInterval: TimeInterval = 7 * 24 * 60 * 60
```

## Logging

ImageCache logs to Logger with `.data` category:
- `[ImageCache] Memory hit: filename.jpg` - Found in RAM
- `[ImageCache] Disk hit: filename.jpg` - Found on disk
- `[ImageCache] Downloading: filename.jpg` - Fetching from network
- `[ImageCache] Cleared all cache` - Manual cache clear
- `[ImageCache] Cleaned up 5 expired images (12 MB)` - Automatic cleanup

## Best Practices

1. **Use CachedAsyncImage for all remote images** - Replace AsyncImage everywhere
2. **Preload list images** - Call `preload()` in `.onAppear` for smooth scrolling
3. **Clear cache on sign-out** - Prevent cache bleeding: `ImageCache.shared.clearAll()`
4. **Don't cache placeholders** - Only pass remote URLs, not bundled assets
5. **Test memory warnings** - Cache automatically evicts under memory pressure (NSCache)

## Troubleshooting

**Images not loading?**
- Check URL validity with Logger (category: `.data`)
- Verify network connectivity
- Check disk space (cache needs ~200 MB)

**Cache too aggressive?**
- Reduce `memoryCacheCountLimit` or `diskCacheSizeLimit`
- Lower `cacheExpirationInterval` (e.g., 3 days)

**Memory warnings?**
- NSCache automatically evicts under pressure
- Reduce `memoryCacheTotalCostLimit` (e.g., 25 MB)
