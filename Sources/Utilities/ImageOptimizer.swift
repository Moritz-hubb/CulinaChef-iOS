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
