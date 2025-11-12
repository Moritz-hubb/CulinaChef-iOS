import SwiftUI
import UIKit

enum UIAppearanceConfigurator {
    static func configure() {
        // Navigation bar - glass/transparent style
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundEffect = nil
        nav.backgroundColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = nav
        navigationBar.scrollEdgeAppearance = nav
        navigationBar.compactAppearance = nav
        navigationBar.tintColor = .white

        // Tab bar - glass/transparent style
        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        tab.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        tab.backgroundColor = .clear
// Unselected icons/titles: white; selected icon: peach orange, title remains white
        let normalColor = UIColor.white
        let selectedIconColor = UIColor(red: 0.95, green: 0.5, blue: 0.3, alpha: 1.0)
        let normalAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: normalColor]
        let selectedTitleAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        // Stacked (iPhone portrait)
        tab.stackedLayoutAppearance.normal.iconColor = normalColor
        tab.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        tab.stackedLayoutAppearance.selected.iconColor = selectedIconColor
        tab.stackedLayoutAppearance.selected.titleTextAttributes = selectedTitleAttrs
        // Inline (iPad)
        tab.inlineLayoutAppearance.normal.iconColor = normalColor
        tab.inlineLayoutAppearance.normal.titleTextAttributes = normalAttrs
        tab.inlineLayoutAppearance.selected.iconColor = selectedIconColor
        tab.inlineLayoutAppearance.selected.titleTextAttributes = selectedTitleAttrs
        // Compact inline
        tab.compactInlineLayoutAppearance.normal.iconColor = normalColor
        tab.compactInlineLayoutAppearance.normal.titleTextAttributes = normalAttrs
        tab.compactInlineLayoutAppearance.selected.iconColor = selectedIconColor
        tab.compactInlineLayoutAppearance.selected.titleTextAttributes = selectedTitleAttrs
        // Selection indicator with gray capsule stroke
        tab.selectionIndicatorTintColor = .clear
        tab.selectionIndicatorImage = makeSelectionIndicator()

        // Also enforce title color via UITabBarItem appearance
        let itemAppearance = UITabBarItem.appearance()
itemAppearance.setTitleTextAttributes(normalAttrs, for: .normal)
        itemAppearance.setTitleTextAttributes(selectedTitleAttrs, for: .selected)

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tab
        tabBar.scrollEdgeAppearance = tab
        tabBar.isTranslucent = true
        tabBar.overrideUserInterfaceStyle = .dark
        tabBar.tintColor = selectedIconColor
        tabBar.unselectedItemTintColor = normalColor
    }

    private static func makeSelectionIndicator() -> UIImage? {
        let size = CGSize(width: 60, height: 30)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height/2)
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor(white: 1.0, alpha: 0.15).setStroke()
            path.lineWidth = 2
            path.stroke()
        }
        return img.resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 29, bottom: 14, right: 29))
    }
}
