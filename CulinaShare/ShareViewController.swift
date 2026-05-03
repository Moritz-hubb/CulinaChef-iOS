import os
import UIKit
import UniformTypeIdentifiers
import UserNotifications

private let shareLog = Logger(subsystem: "com.moritzserrin.culinachef.share", category: "CulinaShare")

/// Share Extension: In Apps wie TikTok unter **Teilen → Mehr → CulinaChef** erscheinen
/// (nach erstem Start ggf. „Bearbeiten" und CulinaChef aktivieren).
@objc(ShareViewController)
final class ShareViewController: UIViewController {

    private let appGroupId = "group.com.moritzserrin.culinachef.share"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        extractAndOpen()
    }

    // MARK: - URL Extraction

    private func extractAndOpen() {
        shareLog.debug("[CulinaShare] extractAndOpen started")
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {
            shareLog.error("[CulinaShare] no NSExtensionItem in inputItems")
            finishWithError(message: "Keine Inhalte")
            return
        }

        let providers = item.attachments ?? []
        shareLog.debug("[CulinaShare] attachment providers count=\(providers.count)")
        let group = DispatchGroup()
        var foundURL: String?
        let lock = NSLock()

        func setURL(_ raw: String?) {
            guard let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
            lock.lock()
            defer { lock.unlock() }
            guard foundURL == nil else { return }
            if text.hasPrefix("http") {
                foundURL = text
            } else if let extracted = Self.extractFirstHTTPURL(from: text) {
                foundURL = extracted
            }
        }

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let url = item as? URL {
                    setURL(url.absoluteString)
                } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    setURL(url.absoluteString)
                }
            }
        }

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let text = item as? String {
                    setURL(text)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            guard let link = foundURL else {
                shareLog.error("[CulinaShare] no http URL in attachments (plain/url types)")
                self.finishWithError(message: "Kein Link gefunden")
                return
            }

            shareLog.debug("[CulinaShare] resolved link len=\(link.count) prefix=\(String(link.prefix(120)))")
            self.persistAndOpenApp(link: link)
        }
    }

    /// Uses NSDataDetector to find the first http(s) URL within arbitrary text.
    private static func extractFirstHTTPURL(from text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        for match in matches {
            guard let url = match.url, let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else { continue }
            return url.absoluteString
        }
        return nil
    }

    // MARK: - Open Host App

    private func persistAndOpenApp(link: String) {
        if let defaults = UserDefaults(suiteName: appGroupId) {
            defaults.set(link, forKey: "pending_social_import_url")
            defaults.synchronize()
            shareLog.debug("[CulinaShare] wrote pending_social_import_url to App Group")
        } else {
            shareLog.error("[CulinaShare] UserDefaults(suiteName:) failed — App Group entitlements?")
        }

        var components = URLComponents()
        components.scheme = "culinachef"
        components.host = "import"
        components.queryItems = [URLQueryItem(name: "url", value: link)]

        guard let openURL = components.url else {
            shareLog.error("[CulinaShare] failed to build culinachef://import URL")
            showSuccessAndClose()
            return
        }

        shareLog.debug("[CulinaShare] attempting to open host app: \(openURL.absoluteString.prefix(200))")

        extensionContext?.open(openURL) { [weak self] opened in
            guard let self else { return }
            shareLog.debug("[CulinaShare] extensionContext.open completed opened=\(opened)")
            if opened {
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } else {
                shareLog.warning("[CulinaShare] open() failed — falling back to notification + UI")
                DispatchQueue.main.async {
                    self.scheduleReminderNotification(link: link)
                    self.showSuccessAndClose()
                }
            }
        }
    }

    // MARK: - Local Notification Fallback

    private func scheduleReminderNotification(link: String) {
        let content = UNMutableNotificationContent()
        content.title = "Rezept bereit zum Import"
        content.body = "Tippe hier um das Rezept in CulinaChef zu importieren."
        content.sound = .default
        content.userInfo = ["deep_link": "culinachef://import?url=\(link)"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "culinashare-import-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                shareLog.error("[CulinaShare] notification scheduling failed: \(error.localizedDescription)")
            } else {
                shareLog.debug("[CulinaShare] notification scheduled successfully")
            }
        }
    }

    // MARK: - Success UI + Auto-Close

    private func showSuccessAndClose() {
        view.subviews.forEach { $0.removeFromSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        icon.tintColor = .systemGreen
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.heightAnchor.constraint(equalToConstant: 52).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 52).isActive = true

        let title = UILabel()
        title.text = "Link gespeichert!"
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Öffne CulinaChef — der Import startet automatisch."
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    // MARK: - Error Handling

    private func finishWithError(message: String) {
        shareLog.error("[CulinaShare] finishWithError: \(message)")
        let err = NSError(
            domain: "com.moritzserrin.culinachef.share",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        extensionContext?.cancelRequest(withError: err)
    }
}
