import Foundation
import UIKit

/// Best-effort Jailbreak Detection ohne private APIs.
///
/// WICHTIG:
/// - Diese Heuristiken sind nicht 100% zuverlässig.
/// - Ziel ist es, offensichtliche Jailbreaks zu erkennen und ggf. zu warnen
///   oder bestimmte Features einzuschränken.
/// - Auf dem Simulator wird immer `false` zurückgegeben.
enum JailbreakDetector {
    /// Prüft, ob das Gerät wahrscheinlich gejailbreaked ist.
    static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        // Jailbreak-Erkennung ist auf dem Simulator nicht sinnvoll
        return false
        #else
        if hasSuspiciousFiles() { return true }
        if canWriteOutsideSandbox() { return true }
        return false
        #endif
    }

    /// Typische Pfade, die auf Jailbreak-Umgebungen hinweisen.
    private static func hasSuspiciousFiles() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/stash"
        ]

        let fileManager = FileManager.default
        for path in suspiciousPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    /// Versucht, außerhalb des App-Sandbox-Verzeichnisses zu schreiben.
    ///
    /// Auf einem normalen Gerät sollte dies vom Sandbox-System verhindert werden.
    private static func canWriteOutsideSandbox() -> Bool {
        let testPath = "/private/jb_test_\(UUID().uuidString).txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            // Aufgeräumt wird best-effort – wichtig ist die Tatsache, DASS es geklappt hat.
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
}
