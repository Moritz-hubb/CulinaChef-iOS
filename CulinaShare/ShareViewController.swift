import os
import UIKit
import UniformTypeIdentifiers

private let shareLog = Logger(subsystem: "com.moritzserrin.culinachef.share", category: "CulinaShare")

/// Share Extension: In Apps wie TikTok unter **Teilen → Mehr → CulinaChef** erscheinen
/// (nach erstem Start ggf. „Bearbeiten“ und CulinaChef aktivieren).
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

        func setURL(_ s: String?) {
            guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return }
            lock.lock()
            defer { lock.unlock() }
            if foundURL == nil, s.hasPrefix("http") {
                foundURL = s
            }
        }

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let u = item as? URL {
                        setURL(u.absoluteString)
                    } else if let data = item as? Data, let u = URL(dataRepresentation: data, relativeTo: nil) {
                        setURL(u.absoluteString)
                    }
                }
            }
        }

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let s = item as? String {
                        setURL(s)
                    }
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

            var components = URLComponents()
            components.scheme = "culinachef"
            components.host = "import"
            components.queryItems = [URLQueryItem(name: "url", value: link)]

            guard let openURL = components.url else {
                shareLog.error("[CulinaShare] failed to build culinachef://import URL")
                self.finishWithError(message: "Ungültiger Link")
                return
            }

            shareLog.debug("[CulinaShare] opening host app: \(openURL.absoluteString.prefix(200))")

            if let defaults = UserDefaults(suiteName: self.appGroupId) {
                defaults.set(link, forKey: "pending_social_import_url")
                defaults.synchronize()
                shareLog.debug("[CulinaShare] wrote pending_social_import_url to App Group")
            } else {
                shareLog.error("[CulinaShare] UserDefaults(suiteName:) failed — App Group entitlements?")
            }

            self.extensionContext?.open(openURL, completionHandler: { opened in
                shareLog.debug("[CulinaShare] extensionContext.open completed opened=\(opened)")
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        }
    }

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
