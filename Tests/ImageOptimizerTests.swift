import XCTest
import UIKit
@testable import CulinaChef

final class ImageOptimizerTests: XCTestCase {
    func testOptimizeForAIShrinksTwelveMegapixelBelowBackendPixelCap() {
        let image = solidImage(width: 4032, height: 3024)
        XCTAssertGreaterThan(Int(image.size.width * image.size.height), 12_000_000)
        let data = try! ImageOptimizer.optimizeForAI(image)
        let out = UIImage(data: data)!
        XCTAssertLessThanOrEqual(Int(out.size.width * out.size.height), 12_000_000)
        XCTAssertLessThanOrEqual(max(out.size.width, out.size.height), ImageOptimizer.aiMaxEdge + 1)
        XCTAssertLessThanOrEqual(data.count, ImageOptimizer.aiMaxFileSize)
        XCTAssertEqual(data.prefix(3), Data([0xFF, 0xD8, 0xFF]))
    }

    func testOptimizeForAIPreservesPortraitAspect() {
        let image = solidImage(width: 3024, height: 4032)
        let data = try! ImageOptimizer.optimizeForAI(image)
        let out = UIImage(data: data)!
        let inRatio = image.size.width / image.size.height
        let outRatio = out.size.width / out.size.height
        XCTAssertEqual(inRatio, outRatio, accuracy: 0.02)
        XCTAssertLessThanOrEqual(max(out.size.width, out.size.height), ImageOptimizer.aiMaxEdge + 1)
    }

    func testSmallImageStaysDecodableJpeg() {
        let image = solidImage(width: 64, height: 48)
        let data = try! ImageOptimizer.optimizeForAI(image)
        XCTAssertNotNil(UIImage(data: data))
        XCTAssertEqual(data.prefix(3), Data([0xFF, 0xD8, 0xFF]))
    }

    func testPngBytesBecomeJpegUnderPixelCap() {
        let png = pngData(width: 2000, height: 2000)
        let data = try! ImageOptimizer.optimizeForAI(png)
        let out = UIImage(data: data)!
        XCTAssertLessThanOrEqual(max(out.size.width, out.size.height), ImageOptimizer.aiMaxEdge + 1)
        XCTAssertEqual(data.prefix(3), Data([0xFF, 0xD8, 0xFF]))
    }

    func testInvalidBytesThrow() {
        XCTAssertThrowsError(try ImageOptimizer.optimizeForAI(Data("not-an-image".utf8)))
    }

    func testFortyEightMegapixelLongEdgeIs1920() {
        let image = solidImage(width: 8064, height: 6048)
        let data = try! ImageOptimizer.optimizeForAI(image)
        let out = UIImage(data: data)!
        XCTAssertLessThanOrEqual(max(out.size.width, out.size.height), ImageOptimizer.aiMaxEdge + 1)
        XCTAssertLessThanOrEqual(Int(out.size.width * out.size.height), 12_000_000)
    }

    private func solidImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func pngData(width: Int, height: Int) -> Data {
        solidImage(width: width, height: height).pngData()!
    }
}
