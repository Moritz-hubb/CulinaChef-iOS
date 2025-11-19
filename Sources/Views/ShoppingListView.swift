import SwiftUI

struct ShoppingListView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @State private var showAddItemSheet = false
    @State private var showClearConfirmation = false
    
    private var shoppingListManager: ShoppingListManager {
        app.shoppingListManager
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.78, blue: 0.68),
                    Color(red: 0.95, green: 0.74, blue: 0.64),
                    Color(red: 0.93, green: 0.66, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if shoppingListManager.shoppingList.items.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: { showAddItemSheet = true }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text(L.shopping_hinzufügen.localized)
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                            }
                            
                            Button(action: { shoppingListManager.clearCompleted() }) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text(L.shopping_erledigte_löschen.localized)
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Shopping list items grouped by category
                        ForEach(shoppingListManager.sortedCategories(), id: \.self) { category in
                            CategorySection(
                                category: category,
                                manager: shoppingListManager
                            )
                        }
                        .id(shoppingListManager.shoppingList.items.count)
                        
                        // Clear all button
                        Button(action: { showClearConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text(L.shopping_alle_löschen.localized)
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddItemSheet(manager: shoppingListManager)
                .presentationDetents([.height(400), .medium])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(L.alert_clearAllEntries.localized, isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button(L.button_clearAll.localized, role: .destructive) {
                shoppingListManager.clearAll()
            }
            Button(L.button_cancel.localized, role: .cancel) { }
        }
        .onChange(of: app.isAuthenticated) { _, isAuth in
            if isAuth {
                shoppingListManager.loadShoppingList()
            } else {
                shoppingListManager.clearShoppingList()
            }
        }
        .id(localizationManager.currentLanguage) // Force re-render on language change
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.6))
            
            Text(L.shopping_einkaufsliste_ist_leer.localized)
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text(L.shopping_füge_zutaten_aus_rezepten.localized)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showAddItemSheet = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text(L.shopping_eintrag_hinzufügen.localized)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: ItemCategory
    @ObservedObject var manager: ShoppingListManager
    @State private var isExpanded = true
    
    private var items: [ShoppingListItem] {
        manager.itemsGroupedByCategory()[category] ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                HStack {
                    Text(category.localizedName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("\(items.count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.4))
                )
            }
            .buttonStyle(.plain)
            
            // Items list
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        ShoppingListItemRow(item: item, manager: manager)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Shopping List Item Row

struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    @ObservedObject var manager: ShoppingListManager
    @State private var showCheckAnimation = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showCheckAnimation = true
                manager.toggleItemCompletion(item: item)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showCheckAnimation = false
            }
        }) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if item.isCompleted {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(showCheckAnimation ? 1.3 : 1.0)
                    }
                }
                
                // Item info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body)
                        .foregroundStyle(.white)
                        .strikethrough(item.isCompleted, color: .white)
                    
                    if let quantity = item.quantity, !quantity.isEmpty {
                        Text(quantity)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .strikethrough(item.isCompleted, color: .white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        manager.deleteItem(item: item)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(item.isCompleted ? 0.2 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .opacity(item.isCompleted ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Item Sheet

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: ShoppingListManager
    
    @State private var itemName = ""
    @State private var itemQuantity = ""
    @State private var selectedCategory: ItemCategory = .other
    @State private var hasManuallyChangedCategory = false
    
    var body: some View {
        NavigationView {
            formContent
            .navigationTitle(L.nav_addEntry.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                }
            }
        }
    }
    
    private var categoryPicker: some View {
        Picker(L.label_category.localized, selection: $selectedCategory) {
            ForEach(ItemCategory.allCases, id: \.self) { category in
                Text(category.localizedName).tag(category)
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            hasManuallyChangedCategory = true
        }
        .pickerStyle(.menu)
        .accentColor(.white)
        .colorScheme(.dark)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var formContent: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.78, blue: 0.68),
                    Color(red: 0.95, green: 0.74, blue: 0.64),
                    Color(red: 0.93, green: 0.66, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.label_name.localized)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        
                        TextField(L.placeholder_itemName.localized, text: $itemName)
                            .onChange(of: itemName) { _, newValue in
                                // Auto-update category only if user hasn't manually changed it
                                if !hasManuallyChangedCategory {
                                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty {
                                        selectedCategory = ItemCategory.categorize(ingredient: trimmed)
                                    }
                                }
                            }
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.ultraThinMaterial.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                            .tint(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.label_quantityOptional.localized)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        
                        TextField(L.placeholder_quantity.localized, text: $itemQuantity)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.ultraThinMaterial.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                            .tint(.white)
                    }
                    
                    // Category selector with auto-detection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L.label_category.localized)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                            
                            if !hasManuallyChangedCategory && !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(L.label_autoDetected.localized)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        
                        categoryPicker
                    }
                    
                    Button(action: addItem) {
                        Text(L.shopping_hinzufügen_5f41.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(20)
        }
    }
    
    private func addItem() {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let trimmedQuantity = itemQuantity.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantity = trimmedQuantity.isEmpty ? nil : trimmedQuantity
        
        // Use selected category (either auto-detected or manually changed)
        manager.addItem(name: trimmedName, quantity: quantity, category: selectedCategory)
        dismiss()
    }
}
