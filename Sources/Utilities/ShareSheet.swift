import SwiftUI
import UIKit
import LinkPresentation

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    /// Presents the system share sheet immediately on the visible view controller.
    /// Using SwiftUI `.sheet` around `UIActivityViewController` often swallows the first tap
    /// when the recipe is already inside navigation/sheets.
    @MainActor
    static func present(items: [Any]) {
        guard let presenter = topViewController() else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.safeAreaInsets.top + 28,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }
        
        presenter.present(activityVC, animated: true)
    }
    
    @MainActor
    static func presentRecipe(title: String, text: String) {
        present(items: [RecipeShareItem(title: title, text: text)])
    }
    
    private static func topViewController(from base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        return root
    }
}

/// Supplies share-sheet preview metadata so iOS shows the app icon instead of a generic copy glyph.
private final class RecipeShareItem: NSObject, UIActivityItemSource {
    let title: String
    let text: String
    
    init(title: String, text: String) {
        self.title = title
        self.text = text
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        text
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.originalURL = URL(fileURLWithPath: "CulinaAi/\(sanitizedFileName).md")
        if let icon = Self.appIcon {
            let provider = NSItemProvider(object: icon)
            metadata.iconProvider = provider
            metadata.imageProvider = provider
        }
        return metadata
    }
    
    private var sanitizedFileName: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let safe = trimmed.replacingOccurrences(of: "/", with: "-")
        return safe.isEmpty ? "Rezept" : safe
    }
    
    private static var appIcon: UIImage? {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String] {
            for name in files.reversed() {
                if let image = UIImage(named: name) {
                    return image
                }
            }
        }
        if let image = UIImage(named: "AppIcon") {
            return image
        }
        return UIImage(named: "penguin-chef")
    }
}
