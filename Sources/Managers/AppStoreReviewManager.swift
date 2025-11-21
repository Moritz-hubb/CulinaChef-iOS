import Foundation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

/// Manager für App Store Review-Anfragen
/// 
/// Best Practices:
/// - Fragt nicht zu oft (max. 3x pro Jahr)
/// - Nur nach positiven Erfahrungen (erfolgreiche Aktionen)
/// - Respektiert Apple's Rate Limiting
enum AppStoreReviewManager {
    private static let userDefaults = UserDefaults.standard
    
    // Keys für UserDefaults
    private static let appLaunchCountKey = "app_store_review_launch_count"
    private static let lastReviewRequestDateKey = "app_store_review_last_request_date"
    private static let reviewRequestCountKey = "app_store_review_request_count"
    private static let lastPositiveActionDateKey = "app_store_review_last_positive_action_date"
    
    // Thresholds
    private static let minLaunchesBeforeFirstRequest = 5 // Mindestens 5 App-Öffnungen
    private static let minDaysBetweenRequests = 90 // Mindestens 90 Tage zwischen Anfragen
    private static let maxRequestsPerYear = 3 // Max. 3 Anfragen pro Jahr
    private static let maxDaysSinceLastPositiveAction = 7 // Max. 7 Tage seit letzter positiver Aktion
    
    /// Sollte aufgerufen werden, wenn die App geöffnet wird
    static func incrementLaunchCount() {
        let currentCount = userDefaults.integer(forKey: appLaunchCountKey)
        userDefaults.set(currentCount + 1, forKey: appLaunchCountKey)
        Logger.debug("[AppStoreReview] Launch count: \(currentCount + 1)", category: Logger.Category.ui)
    }
    
    /// Sollte aufgerufen werden nach positiven Aktionen (z.B. erfolgreiches Rezept erstellen)
    static func recordPositiveAction() {
        userDefaults.set(Date(), forKey: lastPositiveActionDateKey)
        Logger.debug("[AppStoreReview] Positive action recorded", category: Logger.Category.ui)
    }
    
    /// Zeigt die Review-Anfrage direkt an (für manuelle Buttons)
    /// 
    /// Diese Methode zeigt die Review-Anfrage immer an, wenn der User manuell darauf tippt.
    /// Apple's Rate Limiting wird trotzdem respektiert (Apple kann die Anfrage ignorieren).
    static func requestReviewDirectly() {
        Logger.info("[AppStoreReview] Direct review request from user", category: Logger.Category.ui)
        requestReview()
    }
    
    /// Prüft ob eine Review-Anfrage angezeigt werden sollte und zeigt sie ggf. an
    /// 
    /// - Parameter force: Wenn `true`, wird die Anfrage angezeigt, unabhängig von den Limits (nur für Debug)
    static func requestReviewIfAppropriate(force: Bool = false) {
        guard !force else {
            // Force mode nur für Debug/Testing
            #if DEBUG
            Logger.debug("[AppStoreReview] Force mode - requesting review", category: Logger.Category.ui)
            requestReview()
            #endif
            return
        }
        
        // Prüfe ob alle Bedingungen erfüllt sind
        guard shouldRequestReview() else {
            Logger.debug("[AppStoreReview] Conditions not met for review request", category: Logger.Category.ui)
            return
        }
        
        Logger.info("[AppStoreReview] Requesting App Store review", category: Logger.Category.ui)
        requestReview()
        
        // Update tracking
        userDefaults.set(Date(), forKey: lastReviewRequestDateKey)
        let currentCount = userDefaults.integer(forKey: reviewRequestCountKey)
        userDefaults.set(currentCount + 1, forKey: reviewRequestCountKey)
    }
    
    /// Prüft ob eine Review-Anfrage angezeigt werden sollte
    private static func shouldRequestReview() -> Bool {
        // 1. Prüfe Launch Count
        let launchCount = userDefaults.integer(forKey: appLaunchCountKey)
        guard launchCount >= minLaunchesBeforeFirstRequest else {
            Logger.debug("[AppStoreReview] Launch count too low: \(launchCount)", category: Logger.Category.ui)
            return false
        }
        
        // 2. Prüfe ob bereits zu viele Anfragen gestellt wurden
        let requestCount = userDefaults.integer(forKey: reviewRequestCountKey)
        guard requestCount < maxRequestsPerYear else {
            Logger.debug("[AppStoreReview] Max requests per year reached: \(requestCount)", category: Logger.Category.ui)
            return false
        }
        
        // 3. Prüfe Zeit seit letzter Anfrage
        if let lastRequestDate = userDefaults.object(forKey: lastReviewRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            guard daysSinceLastRequest >= minDaysBetweenRequests else {
                Logger.debug("[AppStoreReview] Too soon since last request: \(daysSinceLastRequest) days", category: Logger.Category.ui)
                return false
            }
        }
        
        // 4. Prüfe ob es eine positive Aktion gab (nicht zu lange her)
        // WICHTIG: Prüfe zuerst, ob gerade eine positive Aktion aufgezeichnet wurde
        // (kann passieren, wenn recordPositiveAction() direkt vor requestReviewIfAppropriate() aufgerufen wird)
        if let lastPositiveActionDate = userDefaults.object(forKey: lastPositiveActionDateKey) as? Date {
            let daysSincePositiveAction = Calendar.current.dateComponents([.day], from: lastPositiveActionDate, to: Date()).day ?? 0
            // Erlaube auch wenn die Aktion heute war (0 Tage)
            guard daysSincePositiveAction <= maxDaysSinceLastPositiveAction else {
                Logger.debug("[AppStoreReview] Too long since last positive action: \(daysSincePositiveAction) days", category: Logger.Category.ui)
                return false
            }
        } else {
            // Keine positive Aktion aufgezeichnet - nicht fragen
            Logger.debug("[AppStoreReview] No positive action recorded", category: Logger.Category.ui)
            return false
        }
        
        return true
    }
    
    /// Zeigt die App Store Review-Anfrage an
    /// 
    /// Hinweis: Apple's `SKStoreReviewController.requestReview()` zeigt die Review-Anfrage
    /// nur an, wenn Apple es für angemessen hält (Rate Limiting). Die Anfrage kann auch
    /// ignoriert werden, wenn der User kürzlich bereits eine Review abgegeben hat.
    private static func requestReview() {
        // Wichtig: Muss auf dem Main Thread aufgerufen werden
        DispatchQueue.main.async {
            // Versuche zuerst die aktive WindowScene zu finden
            let windowScene: UIWindowScene? = {
                // Methode 1: Suche nach aktiver Scene
                if let activeScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }) {
                    return activeScene
                }
                // Methode 2: Fallback auf erste WindowScene
                if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    return firstScene
                }
                return nil
            }()
            
            if let windowScene = windowScene {
                SKStoreReviewController.requestReview(in: windowScene)
                Logger.info("[AppStoreReview] Review request sent to StoreKit", category: Logger.Category.ui)
            } else {
                Logger.error("[AppStoreReview] Could not get window scene for review request", category: Logger.Category.ui)
                // Retry nach kurzer Verzögerung, falls die Scene noch nicht bereit war
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let retryScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: retryScene)
                        Logger.info("[AppStoreReview] Review request sent to StoreKit (retry)", category: Logger.Category.ui)
                    } else {
                        Logger.error("[AppStoreReview] Retry also failed - window scene still not available", category: Logger.Category.ui)
                    }
                }
            }
        }
    }
    
    /// Reset alle Review-Daten (nur für Debug/Testing)
    #if DEBUG
    static func resetReviewData() {
        userDefaults.removeObject(forKey: appLaunchCountKey)
        userDefaults.removeObject(forKey: lastReviewRequestDateKey)
        userDefaults.removeObject(forKey: reviewRequestCountKey)
        userDefaults.removeObject(forKey: lastPositiveActionDateKey)
        Logger.debug("[AppStoreReview] Review data reset", category: Logger.Category.ui)
    }
    #endif
}

