import WidgetKit
import SwiftUI
import os.log
import AppIntents

// MARK: - Toggle Shopping List Item Intent

@available(iOS 17.0, *)
struct ToggleShoppingListItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Einkaufsliste Eintrag umschalten"
    static var description = IntentDescription("Markiert einen Eintrag in der Einkaufsliste als erledigt oder nicht erledigt.")
    
    @Parameter(title: "Item ID")
    var itemId: String
    
    @Parameter(title: "Item Name")
    var itemName: String
    
    init(itemId: String, itemName: String) {
        self.itemId = itemId
        self.itemName = itemName
    }
    
    init() {
        // Default initializer for App Intents
        self.itemId = ""
        self.itemName = ""
    }
    
    func perform() async throws -> some IntentResult {
        let appGroupID = "group.com.moritzserrin.culinachef"
        
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            throw IntentError.couldNotAccessAppGroup
        }
        
        guard let data = defaults.data(forKey: "shopping_list") else {
            throw IntentError.shoppingListNotFound
        }
        
        // Decode shopping list
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var itemsArray = json["items"] as? [[String: Any]] else {
            throw IntentError.couldNotDecodeShoppingList
        }
        
        // Find and toggle the item
        if let index = itemsArray.firstIndex(where: { ($0["id"] as? String) == itemId }) {
            var item = itemsArray[index]
            let currentStatus = item["isCompleted"] as? Bool ?? false
            item["isCompleted"] = !currentStatus
            itemsArray[index] = item
            
            // Save back to App Group
            let updatedData: [String: Any] = [
                "items": itemsArray,
                "lastUpdated": Date().timeIntervalSince1970
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: updatedData) {
                defaults.set(jsonData, forKey: "shopping_list")
                defaults.synchronize()
                
                // Set animation flags for checkmark animation (only if item is being completed)
                if !currentStatus {
                    // Item is being marked as completed - start animation
                    defaults.set(itemId, forKey: "widget_animating_item_id")
                    defaults.set(Date().timeIntervalSince1970, forKey: "widget_animation_start_time")
                    defaults.synchronize()
                } else {
                    // Item is being uncompleted - no animation needed
                    defaults.removeObject(forKey: "widget_animating_item_id")
                    defaults.removeObject(forKey: "widget_animation_start_time")
                    defaults.synchronize()
                }
                
                // Reload widget timeline immediately to show the change
                WidgetCenter.shared.reloadTimelines(ofKind: "CulinaChefShoppingListWidget")
                
                return .result()
            } else {
                throw IntentError.couldNotSaveShoppingList
            }
        } else {
            throw IntentError.itemNotFound
        }
    }
}

// MARK: - Intent Errors

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case couldNotAccessAppGroup
    case shoppingListNotFound
    case couldNotDecodeShoppingList
    case couldNotSaveShoppingList
    case itemNotFound
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .couldNotAccessAppGroup:
            return "Konnte nicht auf App Group zugreifen"
        case .shoppingListNotFound:
            return "Einkaufsliste nicht gefunden"
        case .couldNotDecodeShoppingList:
            return "Einkaufsliste konnte nicht gelesen werden"
        case .couldNotSaveShoppingList:
            return "Einkaufsliste konnte nicht gespeichert werden"
        case .itemNotFound:
            return "Eintrag nicht gefunden"
        }
    }
}

// MARK: - Shopping List Widget

struct CulinaChefShoppingListWidget: Widget {
    let kind: String = "CulinaChefShoppingListWidget"
    
    private static let log = OSLog(subsystem: "com.moritzserrin.culinachef.widget", category: "ShoppingListWidget")
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShoppingListProvider()) { entry in
            ShoppingListWidgetEntryView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.78, blue: 0.68),
                            Color(red: 0.95, green: 0.74, blue: 0.64),
                            Color(red: 0.93, green: 0.66, blue: 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("Einkaufsliste")
        .description("Zeigt deine Einkaufsliste auf dem Home Screen an.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ShoppingListProvider: TimelineProvider {
    typealias Entry = ShoppingListEntry
    
    private static let log = OSLog(subsystem: "com.moritzserrin.culinachef.widget", category: "ShoppingListProvider")
    
    func placeholder(in context: Context) -> ShoppingListEntry {
        os_log("[ShoppingListWidget] placeholder() called", log: Self.log, type: .info)
        let items = [
            ShoppingListItemInfo(id: "1", name: "Tomaten", quantity: "500g", category: "vegetables", isCompleted: false),
            ShoppingListItemInfo(id: "2", name: "Milch", quantity: "1L", category: "dairy", isCompleted: false),
            ShoppingListItemInfo(id: "3", name: "Brot", quantity: "1", category: "bakery", isCompleted: true)
        ]
        return ShoppingListEntry(date: Date(), items: items, animatingItemId: nil, checkmarkScale: 1.0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ShoppingListEntry) -> Void) {
        os_log("[ShoppingListWidget] getSnapshot() called - context.isPreview: %{public}@", log: Self.log, type: .info, String(context.isPreview))
        let items = loadShoppingList()
        os_log("[ShoppingListWidget] getSnapshot() loaded %d items", log: Self.log, type: .info, items.count)
        let entry = ShoppingListEntry(date: Date(), items: items, animatingItemId: nil, checkmarkScale: 1.0)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ShoppingListEntry>) -> Void) {
        os_log("[ShoppingListWidget] getTimeline() called", log: Self.log, type: .info)
        let currentDate = Date()
        let items = loadShoppingList()
        os_log("[ShoppingListWidget] getTimeline() loaded %d items", log: Self.log, type: .info, items.count)
        
        // Check if there's an animating item (stored in UserDefaults by the Intent)
        let appGroupID = "group.com.moritzserrin.culinachef"
        let defaults = UserDefaults(suiteName: appGroupID)
        let animatingItemId = defaults?.string(forKey: "widget_animating_item_id")
        let animationStartTime = defaults?.double(forKey: "widget_animation_start_time") ?? 0
        
        var entries: [ShoppingListEntry] = []
        
        // If there's an animating item, create animation timeline entries
        if let animatingId = animatingItemId, animationStartTime > 0 {
            let startTime = Date(timeIntervalSince1970: animationStartTime)
            let elapsed = currentDate.timeIntervalSince(startTime)
            
            // Create immediate entry with checkmark visible (scale 1.0)
            entries.append(ShoppingListEntry(date: currentDate, items: items, animatingItemId: animatingId, checkmarkScale: 1.0))
            
            // Create animation entries: scale 1.0 → 1.3 → 1.0 over 0.4 seconds (matching app)
            // Create 8 entries for smooth animation (20 updates per second)
            for i in 0..<8 {
                let progress = Double(i) / 7.0 // 0.0 to 1.0
                let scale: Double
                if progress < 0.5 {
                    // Scale up: 1.0 → 1.3 (first half)
                    scale = 1.0 + (0.3 * (progress * 2))
                } else {
                    // Scale down: 1.3 → 1.0 (second half)
                    scale = 1.3 - (0.3 * ((progress - 0.5) * 2))
                }
                
                // Calculate entry date (startTime + progress * 0.4 seconds)
                let timeOffset = progress * 0.4 // Time in seconds
                let preciseDate = startTime.addingTimeInterval(timeOffset)
                entries.append(ShoppingListEntry(date: preciseDate, items: items, animatingItemId: animatingId, checkmarkScale: scale))
            }
            
            // Clear animation flags after animation completes (0.5 seconds after start)
            let preciseFinalDate = startTime.addingTimeInterval(0.5)
            entries.append(ShoppingListEntry(date: preciseFinalDate, items: items, animatingItemId: nil, checkmarkScale: 1.0))
            defaults?.removeObject(forKey: "widget_animating_item_id")
            defaults?.removeObject(forKey: "widget_animation_start_time")
            defaults?.synchronize()
        } else {
            // No animation, just create normal entry
            entries.append(ShoppingListEntry(date: currentDate, items: items, animatingItemId: nil, checkmarkScale: 1.0))
        }
        
        // Update every 30 seconds
        let updateInterval: TimeInterval = 30
        guard let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(updateInterval), to: currentDate) else {
            os_log("[ShoppingListWidget] getTimeline() ERROR: Could not calculate nextUpdate", log: Self.log, type: .error)
            let timeline = Timeline(entries: entries.isEmpty ? [ShoppingListEntry(date: currentDate, items: items)] : entries, policy: .never)
            completion(timeline)
            return
        }
        
        os_log("[ShoppingListWidget] getTimeline() nextUpdate: %{public}@, created %d entries", log: Self.log, type: .info, nextUpdate.description, entries.count)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        os_log("[ShoppingListWidget] getTimeline() completing with %d items, next update in %.0f seconds", log: Self.log, type: .info, items.count, updateInterval)
        completion(timeline)
    }
    
    private func loadShoppingList() -> [ShoppingListItemInfo] {
        let appGroupID = "group.com.moritzserrin.culinachef"
        os_log("[ShoppingListWidget] loadShoppingList() called, appGroupID: %{public}@", log: Self.log, type: .debug, appGroupID)
        
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            os_log("[ShoppingListWidget] loadShoppingList() ERROR: Could not access UserDefaults with suiteName: %{public}@", log: Self.log, type: .error, appGroupID)
            return []
        }
        
        os_log("[ShoppingListWidget] loadShoppingList() UserDefaults accessed successfully", log: Self.log, type: .debug)
        
        guard let data = defaults.data(forKey: "shopping_list") else {
            os_log("[ShoppingListWidget] loadShoppingList() No shopping list data found in UserDefaults", log: Self.log, type: .info)
            return []
        }
        
        do {
            // Try to decode as WidgetShoppingList first (Codable format)
            if let shoppingList = try? JSONDecoder().decode(WidgetShoppingList.self, from: data) {
                let items = shoppingList.items.map { item in
                    ShoppingListItemInfo(
                        id: item.id,
                        name: item.name,
                        quantity: item.quantity,
                        category: item.category,
                        isCompleted: item.isCompleted
                    )
                }
                os_log("[ShoppingListWidget] loadShoppingList() loaded %d items (Codable)", log: Self.log, type: .info, items.count)
                return items
            }
            
            // Fallback: decode as Dictionary format
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let itemsArray = json["items"] as? [[String: Any]] {
                let items = itemsArray.compactMap { dict -> ShoppingListItemInfo? in
                    guard let id = dict["id"] as? String,
                          let name = dict["name"] as? String,
                          let category = dict["category"] as? String,
                          let isCompleted = dict["isCompleted"] as? Bool else {
                        return nil
                    }
                    let quantity = dict["quantity"] as? String
                    return ShoppingListItemInfo(
                        id: id,
                        name: name,
                        quantity: quantity?.isEmpty == false ? quantity : nil,
                        category: category,
                        isCompleted: isCompleted
                    )
                }
                os_log("[ShoppingListWidget] loadShoppingList() loaded %d items (Dictionary)", log: Self.log, type: .info, items.count)
                return items
            }
            
            os_log("[ShoppingListWidget] loadShoppingList() ERROR: Unknown data format", log: Self.log, type: .error)
            return []
        } catch {
            os_log("[ShoppingListWidget] loadShoppingList() ERROR: Failed to decode shopping list: %{public}@", log: Self.log, type: .error, error.localizedDescription)
            return []
        }
    }
}

struct ShoppingListEntry: TimelineEntry {
    let date: Date
    let items: [ShoppingListItemInfo]
    let animatingItemId: String? // ID of item currently animating checkmark
    let checkmarkScale: Double // Scale of checkmark (1.0 = normal, 1.3 = animated)
    
    init(date: Date, items: [ShoppingListItemInfo], animatingItemId: String? = nil, checkmarkScale: Double = 1.0) {
        self.date = date
        self.items = items
        self.animatingItemId = animatingItemId
        self.checkmarkScale = checkmarkScale
    }
}

struct ShoppingListItemInfo {
    let id: String
    let name: String
    let quantity: String?
    let category: String
    let isCompleted: Bool
}

// Widget-compatible models (simplified versions)
struct WidgetShoppingList: Codable {
    let items: [WidgetShoppingListItem]
    let lastUpdated: Date
}

struct WidgetShoppingListItem: Codable {
    let id: String
    let name: String
    let quantity: String?
    let category: String  // Use String instead of ItemCategory enum for widget compatibility
    let isCompleted: Bool
}

struct ShoppingListWidgetEntryView: View {
    var entry: ShoppingListProvider.Entry
    @Environment(\.widgetFamily) var family
    
    private static let log = OSLog(subsystem: "com.moritzserrin.culinachef.widget", category: "ShoppingListWidgetEntryView")
    
    var body: some View {
        Group {
            if entry.items.isEmpty {
                emptyStateView
            } else {
                switch family {
                case .systemMedium:
                    mediumWidgetView
                case .systemLarge:
                    largeWidgetView
                default:
                    mediumWidgetView
                }
            }
        }
        .onAppear {
            logWidgetRender()
        }
    }
    
    private func logWidgetRender() {
        os_log("[ShoppingListWidget] ShoppingListWidgetEntryView rendering - family: %{public}@, items: %d", log: Self.log, type: .info, String(describing: family), entry.items.count)
        for (index, item) in entry.items.enumerated() {
            os_log("[ShoppingListWidget] Item %d: name='%{public}@', completed=%{public}@", log: Self.log, type: .debug, index, item.name, String(item.isCompleted))
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.8))
            Text("Einkaufsliste leer")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Füge Einträge in der App hinzu")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Medium Widget
    
    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            let incompleteItems = entry.items.filter { !$0.isCompleted }
            
            if incompleteItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Alles erledigt!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    // Fixed 2 slots for items
                    ForEach(0..<2, id: \.self) { index in
                        if index < incompleteItems.count {
                            shoppingListItemRow(item: incompleteItems[index], isCompleted: false, entry: entry)
                        } else {
                            // Empty slot to maintain fixed position (invisible but takes space)
                            Color.clear
                                .frame(height: 36) // Height of item row (8 padding top + 8 padding bottom + ~20 content)
                        }
                    }
                    
                    let remainingCount = incompleteItems.count - 2
                    if remainingCount > 0 {
                        Text("+ \(remainingCount) weitere")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Large Widget
    
    private var largeWidgetView: some View {
        VStack(alignment: .leading, spacing: 10) {
            let incompleteItems = entry.items.filter { !$0.isCompleted }
            
            if incompleteItems.isEmpty {
                emptyStateView
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    // Fixed 5 slots for incomplete items
                    ForEach(0..<5, id: \.self) { index in
                        if index < incompleteItems.count {
                            shoppingListItemRow(item: incompleteItems[index], isCompleted: false, entry: entry)
                        } else {
                            // Empty slot to maintain fixed position (invisible but takes space)
                            Color.clear
                                .frame(height: 36) // Height of item row (8 padding top + 8 padding bottom + ~20 content)
                        }
                    }
                    
                    let remainingCount = incompleteItems.count - 5
                    if remainingCount > 0 {
                        Text("+ \(remainingCount) weitere")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
    
    // MARK: - Shopping List Item Row (App-inspired design)
    
    @ViewBuilder
    private func shoppingListItemRow(item: ShoppingListItemInfo, isCompleted: Bool, entry: ShoppingListEntry) -> some View {
        if #available(iOS 17.0, *) {
            Button(intent: ToggleShoppingListItemIntent(itemId: item.id, itemName: item.name)) {
                HStack(spacing: 10) {
                    // Checkbox (matching app design exactly)
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        if isCompleted {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .scaleEffect(entry.animatingItemId == item.id ? entry.checkmarkScale : 1.0) // Animate scale like in app (1.0 → 1.3 → 1.0)
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isCompleted)
                    
                    // Item info (smaller, matching app)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.name)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .strikethrough(isCompleted, color: .white)
                            .lineLimit(1)
                        
                        if let quantity = item.quantity, !quantity.isEmpty {
                            Text(quantity)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.7))
                                .strikethrough(isCompleted, color: .white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(isCompleted ? 0.2 : 0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .opacity(isCompleted ? 0.6 : 1.0)
            }
            .buttonStyle(.plain)
        } else {
            // Fallback for iOS 16 and earlier (non-interactive)
            HStack(spacing: 10) {
                // Checkbox (matching app design exactly)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isCompleted {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                
                // Item info (smaller, matching app)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .strikethrough(isCompleted, color: .white)
                        .lineLimit(1)
                    
                    if let quantity = item.quantity, !quantity.isEmpty {
                        Text(quantity)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                            .strikethrough(isCompleted, color: .white.opacity(0.7))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(isCompleted ? 0.2 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .opacity(isCompleted ? 0.6 : 1.0)
        }
    }
}



































