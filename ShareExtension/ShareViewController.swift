import UIKit
import Social
import UniformTypeIdentifiers

/// Vorlage für ein Share-Extension-Target (in Xcode hinzufügen).
/// Liest URL oder Text aus dem Share Sheet und übergibt sie an die Haupt-App (URL Scheme + App Group).
final class ShareViewController: SLComposeServiceViewController {

    private let appGroupId = "group.app.culinachef" // Mit Haupt-App abgleichen
    private let urlSchemeImport = "culinachef://import"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CulinaChef"
    }

    override func isContentValid() -> Bool { true }

    override func didSelectPost() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }
        var foundURL: URL?
        var plainText: String?

        for provider in item.attachments ?? [] {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, _ in
                    if let u = data as? URL { foundURL = u }
                }
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
                    if let s = data as? String { plainText = s }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.finishImport(url: foundURL, text: plainText)
        }
    }

    private func finishImport(url: URL?, text: String?) {
        defer { extensionContext?.completeRequest(returningItems: nil) }

        let resolved: String? = {
            if let u = url { return u.absoluteString }
            if let t = text?.trimmingCharacters(in: .whitespacesAndNewlines),
               t.hasPrefix("http") { return t }
            return nil
        }()

        guard let link = resolved, let encoded = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }

        if let defaults = UserDefaults(suiteName: appGroupId) {
            defaults.set(link, forKey: "pending_social_import_url")
            if let t = text, !t.isEmpty { defaults.set(t, forKey: "pending_social_import_extra") }
        }

        guard let open = URL(string: "\(urlSchemeImport)?url=\(encoded)") else { return }
        extensionContext?.open(open) { _, _ in }
    }

    override func configurationItems() -> [Any]! { [] }
}
