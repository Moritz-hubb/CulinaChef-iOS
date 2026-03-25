import UIKit
import UniformTypeIdentifiers

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
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {
            finishWithError(message: "Keine Inhalte")
            return
        }

        let providers = item.attachments ?? []
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
                self.finishWithError(message: "Kein Link gefunden")
                return
            }

            var components = URLComponents()
            components.scheme = "culinachef"
            components.host = "import"
            components.queryItems = [URLQueryItem(name: "url", value: link)]

            guard let openURL = components.url else {
                self.finishWithError(message: "Ungültiger Link")
                return
            }

            if let defaults = UserDefaults(suiteName: self.appGroupId) {
                defaults.set(link, forKey: "pending_social_import_url")
                defaults.synchronize()
            }

            self.extensionContext?.open(openURL, completionHandler: { _ in
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        }
    }

    private func finishWithError(message: String) {
        let err = NSError(
            domain: "com.moritzserrin.culinachef.share",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        extensionContext?.cancelRequest(withError: err)
    }
}
