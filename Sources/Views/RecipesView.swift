import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            // MVP: nur persönliche Rezepte (Teilen über Rezept-Detail / Share)
                    PersonalRecipesView()
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .id(localizationManager.currentLanguage) // Force re-render on language change
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L.done.localized) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
            }
        }
    }
}

// MARK: - Average Rating View (fetches from Supabase)
// MARK: - Search Bar
private struct SearchBar: View {
    @Binding var query: String
    var placeholder: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField(placeholder, text: $query)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityLabel("Suche")
                .accessibilityHint("Geben Sie einen Suchbegriff ein")
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
                .accessibilityLabel("Suche löschen")
                .accessibilityHint("Löscht den Suchtext")
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Tag Chips
private struct TagChips: View {
    let tags: [String]
    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags.filter { !$0.hasPrefix("_") }, id: \.self) { tag in
                Text(tag)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Filter Chips Bar
private struct FilterChipsBar: View {
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    let isOn = selection.contains(opt)
                    Text(opt)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isOn ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                        .foregroundColor(isOn ? .white : .black.opacity(0.7))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
                        .onTapGesture {
                            if isOn { selection.remove(opt) } else { selection.insert(opt) }
                        }
                }
                if !selection.isEmpty {
                    Button(action: { selection.removeAll() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text(L.recipe_filter_löschen.localized)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Menus Bar
private struct MenusBar: View {
    let menus: [Menu]
    @Binding var selected: Menu?
    var onAdd: () -> Void
    var onRenameSelected: () -> Void
    var onDeleteSelected: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onAdd) {
                HStack(spacing: 6) { Image(systemName: "plus"); Text(L.recipe_menü_539e.localized) }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    MenuChip(title: L.label_all.localized, isOn: selected == nil) { selected = nil }
                    ForEach(menus) { m in
                        MenuChip(title: m.title, isOn: selected?.id == m.id) { selected = m }
                    }
                }
            }
            if selected != nil {
                Button(action: onRenameSelected) {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.recipes_renameMenuHeadline.localized)
                Button(role: .destructive, action: onDeleteSelected) {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct MenuChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(isOn ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                .foregroundColor(isOn ? .white : .black.opacity(0.7))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct NewMenuSheet: View {
    @Binding var title: String
    var onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.96, green: 0.78, blue: 0.68),
                Color(red: 0.95, green: 0.74, blue: 0.64),
                Color(red: 0.93, green: 0.66, blue: 0.55)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text(L.recipe_neues_menü.localized)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L.recipe_menüname.localized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    TextField(L.placeholder_menuName.localized, text: $title)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text(L.button_cancel.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial.opacity(0.25))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { onCreate(title) }) {
                        Text(L.button_create.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading, endPoint: .trailing
                                ), in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.2)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
} 

private struct RenameMenuSheet: View {
    @Binding var title: String
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.96, green: 0.78, blue: 0.68),
                Color(red: 0.95, green: 0.74, blue: 0.64),
                Color(red: 0.93, green: 0.66, blue: 0.55)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text(L.recipes_renameMenuHeadline.localized)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L.recipe_menüname.localized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    TextField(L.placeholder_menuName.localized, text: $title)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text(L.button_cancel.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial.opacity(0.25))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { onSave(title) }) {
                        Text(L.button_save.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ), in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.2)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}

// MARK: - Personal Recipes View
struct PersonalRecipesView: View {
    @EnvironmentObject var app: AppState
    @State private var recipes: [Recipe] = []
    @State private var loading = true
    @State private var error: String?
    @State private var toDelete: Recipe? = nil
    @State private var showDeleteAlert = false
    @State private var deleting = false
    @State private var menus: [Menu] = []
    @State private var selectedMenu: Menu? = nil
    @State private var selectedMenuRecipeIds: Set<String> = []
    @State private var menuRecipeIdsCache: [String: Set<String>] = [:] // Cache für alle Menü-Rezept-IDs
    @State private var menuRecipeIdsLoading: Set<String> = [] // Track welche Menüs gerade geladen werden
    @State private var showNewMenuSheet = false
    @State private var newMenuTitle: String = ""
    @State private var showRenameMenuSheet = false
    @State private var renameMenuTitle: String = ""
    @State private var assigningRecipe: Recipe? = nil
    @State private var pushRecipe: Recipe? = nil
    @State private var navigationRecipeId: String? = nil
    @State private var selectedMenuLoaded: Bool = true
    @State private var showDeleteMenuAlert: Bool = false
    @State private var menuPlaceholders: [AppState.MenuSuggestion] = []
    @State private var menuCourseMap: [String: String] = [:]
    @State private var showManualRecipeBuilder = false
    @State private var showSocialImport = false
    @State private var deletedRecipeIds: Set<String> = [] // Track locally deleted recipes
    
    private var visibleRecipes: [Recipe] {
        let filteredRecipes = recipes.filter { !deletedRecipeIds.contains($0.id) }
        
        if let menuId = selectedMenu?.id {
            // Verwende Cache, wenn verfügbar, sonst selectedMenuRecipeIds (für Backward Compatibility)
            let ids = menuRecipeIdsCache[menuId] ?? selectedMenuRecipeIds
            // Wenn IDs noch nicht geladen sind, zeige optimistisch alle Rezepte
            if ids.isEmpty && menuRecipeIdsLoading.contains(menuId) {
                return filteredRecipes // Zeige alle während des Ladens
            }
            return filteredRecipes.filter { ids.contains($0.id) }
        }
        return filteredRecipes
    }
    
    private var loadingView: some View {
        ProgressView()
            .tint(Color(red: 0.85, green: 0.4, blue: 0.2))
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.6))
            Text(error)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    var body: some View {
        mainContentWithModifiers
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if loading { 
            loadingView
        }
        else if let error { 
            errorView(error: error)
        }
        else if recipes.isEmpty {
            emptyStateView
        }
        else {
            recipesListView
        }
    }
    
    private var emptyStateView: some View {
                ScrollView {
                    VStack(spacing: 16) {
                        MenusBar(
                            menus: menus,
                            selected: $selectedMenu,
                            onAdd: { showNewMenuSheet = true },
                            onRenameSelected: {
                                renameMenuTitle = selectedMenu?.title ?? ""
                                showRenameMenuSheet = true
                            },
                            onDeleteSelected: { showDeleteMenuAlert = true }
                        )
                            .onChange(of: selectedMenu?.id) { _, _ in
                                if let mid = selectedMenu?.id {
                                    menuPlaceholders = app.getMenuSuggestions(menuId: mid)
                                    menuCourseMap = app.getMenuCourseMap(menuId: mid)
                                } else {
                                    menuPlaceholders = []
                                    menuCourseMap = [:]
                                }
                            }
                            .onChange(of: app.lastCreatedMenu?.id) { _, _ in
                                if let m = app.lastCreatedMenu {
                                    if !menus.contains(where: { $0.id == m.id }) { menus.insert(m, at: 0) }
                                    selectedMenu = m
                                    menuPlaceholders = app.getMenuSuggestions(menuId: m.id)
                                    menuCourseMap = app.getMenuCourseMap(menuId: m.id)
                                    app.lastCreatedMenu = nil
                                }
                            }
                            .task(id: menus.count) {
                                if let wanted = app.pendingSelectMenuId, let m = menus.first(where: { $0.id == wanted }) {
                                    selectedMenu = m
                                    app.pendingSelectMenuId = nil
                                    menuPlaceholders = app.getMenuSuggestions(menuId: m.id)
                                }
                            }
                            .onChange(of: app.lastCreatedRecipe?.id) { _, _ in
                                if let r = app.lastCreatedRecipe {
                                    if !recipes.contains(where: { $0.id == r.id }) { recipes.insert(r, at: 0) }
                                    if let mid = app.lastCreatedRecipeMenuId, let sel = selectedMenu, sel.id == mid {
                                        selectedMenuRecipeIds.insert(r.id)
                                        menuCourseMap = app.getMenuCourseMap(menuId: mid)
                                        menuPlaceholders = app.getMenuSuggestions(menuId: mid)
                                    }
                                    app.lastCreatedRecipe = nil
                                    app.lastCreatedRecipeMenuId = nil
                                }
                            }
                        
                        // In-progress status when KI noch generiert
                        if let _ = selectedMenu?.id, !menuPlaceholders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                CulinaThinkingPenguinView()
                                Text(L.recipe_ich_bin_dabei_deine.localized)
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding(12)
                            .background(Color(UIColor.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        VStack(spacing: 16) {
                            // Neuer Empty-State Pinguin
                            if let bundlePath = Bundle.main.path(forResource: "penguin-empty", ofType: "png", inDirectory: "Assets.xcassets/penguin-empty.imageset"),
                               let uiImage = UIImage(contentsOfFile: bundlePath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 140, height: 140)
                            } else if let uiImage = UIImage(named: "penguin-empty") {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 140, height: 140)
                            } else {
                                Text("🐧")
                                    .font(.system(size: 80))
                            }
                            
                            Text(L.text_prettyEmptyHere.localized)
                                .font(.title3.bold())
                                .foregroundColor(.black.opacity(0.7))
                            Text(L.recipe_erstelle_jetzt_dein_erstes.localized)
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.5))
                                .multilineTextAlignment(.center)
                            
                            VStack(spacing: 12) {
                                Button(action: { showManualRecipeBuilder = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.pencil")
                                        Text(L.button_ownRecipeCreate.localized)
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                            startPoint: .leading, endPoint: .trailing
                                        ), in: Capsule()
                                    )
                                }
                                
                                Button(action: { app.selectedTab = 1 }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "wand.and.stars")
                                        Text(L.recipe_mit_ki_erstellen.localized)
                                    }
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color(red: 0.85, green: 0.4, blue: 0.2), lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(action: { showSocialImport = true }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.headline)
                                        .foregroundColor(Color(red: 0.2, green: 0.45, blue: 0.85))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(Color(red: 0.2, green: 0.45, blue: 0.85), lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(L.import_social_title.localized)
                            }
                        }
                        .padding(.vertical, 40)
                    }
                    .padding(16)
                }
    }
    
    private var recipesListView: some View {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Create Recipe Button
                            HStack(spacing: 8) {
                                Button(action: { showManualRecipeBuilder = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.pencil")
                                        Text(L.button_ownRecipe.localized)
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                            startPoint: .leading, endPoint: .trailing
                                        ), in: Capsule()
                                    )
                                }
                                
                                Button(action: { app.selectedTab = 1 }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "wand.and.stars")
                                        Text(L.button_kiGenerator.localized)
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .stroke(Color(red: 0.85, green: 0.4, blue: 0.2), lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(action: { showSocialImport = true }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color(red: 0.2, green: 0.45, blue: 0.85))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 10)
                                        .background(
                                            Capsule()
                                                .stroke(Color(red: 0.2, green: 0.45, blue: 0.85), lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(L.import_social_title.localized)
                                
                                Spacer()
                            }
                            
                            MenusBar(
                            menus: menus,
                            selected: $selectedMenu,
                            onAdd: { showNewMenuSheet = true },
                            onRenameSelected: {
                                renameMenuTitle = selectedMenu?.title ?? ""
                                showRenameMenuSheet = true
                            },
                            onDeleteSelected: { showDeleteMenuAlert = true }
                        )
                                .onChange(of: app.lastCreatedRecipe?.id) { _, _ in
                                    if let r = app.lastCreatedRecipe {
                                        // Insert recipe into local list if not present
                                        if !recipes.contains(where: { $0.id == r.id }) { recipes.insert(r, at: 0) }
                                        // If matches current menu, include id and refresh course map
                                        if let mid = app.lastCreatedRecipeMenuId, let sel = selectedMenu, sel.id == mid {
                                            selectedMenuRecipeIds.insert(r.id)
                                            menuCourseMap = app.getMenuCourseMap(menuId: mid)
                                            menuPlaceholders = app.getMenuSuggestions(menuId: mid)
                                        }
                                        app.lastCreatedRecipe = nil
                                        app.lastCreatedRecipeMenuId = nil
                                    }
                                }
                                .task(id: menus.count) {
                                    if let m = app.lastCreatedMenu {
                                        if !menus.contains(where: { $0.id == m.id }) { menus.insert(m, at: 0) }
                                        selectedMenu = m
                                        menuPlaceholders = app.getMenuSuggestions(menuId: m.id)
                                        menuCourseMap = app.getMenuCourseMap(menuId: m.id)
                                        app.lastCreatedMenu = nil
                                    }
                                }
                                .task(id: menus.count) {
                                    // When menus load/update, preselect requested menu once
                                    if let wanted = app.pendingSelectMenuId, let m = menus.first(where: { $0.id == wanted }) {
                                        selectedMenu = m
                                        app.pendingSelectMenuId = nil
                                        menuPlaceholders = app.getMenuSuggestions(menuId: m.id)
                                        menuCourseMap = app.getMenuCourseMap(menuId: m.id)
                                    }
                                }
                                .onChange(of: selectedMenu?.id) { _, newId in
                                    if let menuId = newId {
                                        // Verwende Cache wenn verfügbar, sonst lade
                                        if let token = app.accessToken {
                                            Task { await loadMenuRecipeIds(menuId: menuId, token: token, updateSelected: true) }
                                        }
                                    }
                                    // Load local placeholders for this menu
                                    if let mid = selectedMenu?.id {
                                        menuPlaceholders = app.getMenuSuggestions(menuId: mid)
                                        menuCourseMap = app.getMenuCourseMap(menuId: mid)
                                    } else {
                                        menuPlaceholders = []
                                        menuCourseMap = [:]
                                    }
                                }
                                .onAppear {
                                    // Preselect a menu if requested by another screen
                                    if let wanted = app.pendingSelectMenuId, let m = menus.first(where: { $0.id == wanted }) {
                                        selectedMenu = m
                                        app.pendingSelectMenuId = nil
                                        menuPlaceholders = app.getMenuSuggestions(menuId: m.id)
                                    }
                                }
                            
                            // In-progress status when KI noch generiert
                            if let _ = selectedMenu?.id, !menuPlaceholders.isEmpty {
                                HStack(alignment: .center, spacing: 12) {
                                    CulinaThinkingPenguinView()
                                    Text(L.recipe_ich_bin_dabei_deine_d9e2.localized)
                                        .font(.subheadline)
                                        .foregroundColor(.black.opacity(0.7))
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(UIColor.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            LazyVStack(spacing: 12) {
                                if let mid = selectedMenu?.id {
                                    let groups = groupedByCourse(menuId: mid)
                                    ForEach(groups, id: \.course) { group in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(group.course)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            ForEach(group.recipes) { recipe in
                                                RecipeCard(
                                                    recipe: recipe,
                                                    onDelete: { toDelete = recipe; showDeleteAlert = true },
                                                    onAssign: { assigningRecipe = recipe }
                                                )
                                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                                .onTapGesture { navigationRecipeId = recipe.id }
                                            }
                                        }
                                    }
                                } else {
                                    ForEach(visibleRecipes) { recipe in
                                        RecipeCard(
                                            recipe: recipe,
                                            onDelete: { toDelete = recipe; showDeleteAlert = true },
                                            onAssign: { assigningRecipe = recipe }
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .onTapGesture { navigationRecipeId = recipe.id }
                                    }
                                }
                            }
                            if let recipeId = navigationRecipeId {
                                let allRecipes: [Recipe] = {
                                    if let menuId = selectedMenu?.id {
                                        return groupedByCourse(menuId: menuId).flatMap { $0.recipes }
                                    } else {
                                        return visibleRecipes
                                    }
                                }()
                                if let recipe = allRecipes.first(where: { $0.id == recipeId }) {
                                    NavigationLink(
                                        destination: RecipeDetailView(recipe: recipe),
                                        isActive: Binding(
                                            get: { navigationRecipeId == recipeId },
                                            set: { if !$0 { navigationRecipeId = nil } }
                                        )
                                    ) {
                                        EmptyView()
                                    }
                                    .hidden()
                                }
                            }
                        }
                        .padding(16)
                    }
    }
    
    @ViewBuilder
    private var mainContentWithModifiers: some View {
        mainContent
            .navigationBarHidden(true)
            .task { 
                // OPTIMIZATION: Lade zuerst gecachte Rezepte für sofortige Anzeige
                await loadCachedRecipesIfAvailable()
                // Dann im Hintergrund aktualisieren (nur wenn Cache älter als 5 Minuten)
                if app.recipesCacheTimestamp == nil || 
                   Date().timeIntervalSince(app.recipesCacheTimestamp ?? Date.distantPast) > 300 {
                    await loadRecipes(keepVisible: true)
                }
            }
            .onAppear {
                let appearTime = Date()
                print("📱 [PERFORMANCE] PersonalRecipesView APPEARED at \(appearTime)")
                print("📱 [PERFORMANCE] Current state: loading=\(loading), recipes=\(recipes.count), menus=\(menus.count)")
            }
            .task {
                let taskStartTime = Date()
                print("📱 [PERFORMANCE] PersonalRecipesView .task STARTED at \(taskStartTime)")
                await loadRecipes(keepVisible: false)
                let taskDuration = Date().timeIntervalSince(taskStartTime)
                print("✅ [PERFORMANCE] PersonalRecipesView .task COMPLETED in \(String(format: "%.3f", taskDuration))s")
            }
            .refreshable { 
                let refreshStartTime = Date()
                print("🔄 [PERFORMANCE] Pull-to-refresh STARTED")
                await loadRecipes(keepVisible: true)
                let refreshDuration = Date().timeIntervalSince(refreshStartTime)
                print("✅ [PERFORMANCE] Pull-to-refresh COMPLETED in \(String(format: "%.3f", refreshDuration))s")
            }
            .sheet(isPresented: $showNewMenuSheet) {
            NewMenuSheet(title: $newMenuTitle, onCreate: { t in Task { await createMenu(title: t) } })
                .presentationDetents([.height(260), .medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRenameMenuSheet) {
            RenameMenuSheet(title: $renameMenuTitle, onSave: { t in Task { await renameSelectedMenu(title: t) } })
                .presentationDetents([.height(260), .medium])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Zu Menü hinzufügen", isPresented: Binding(get: { assigningRecipe != nil }, set: { if !$0 { assigningRecipe = nil } })) {
            if let r = assigningRecipe {
                ForEach(menus) { m in
                    Button(m.title) { Task { await add(recipe: r, to: m) } }
                }
            }
            Button(L.cancel.localized, role: .cancel) {}
        }
        .alert(L.deleteRecipeTitle.localized, isPresented: $showDeleteAlert) {
            Button(L.delete.localized, role: .destructive) {
                let r = toDelete
                Task { await confirmDelete(recipe: r) }
            }
            Button(L.cancel.localized, role: .cancel) { toDelete = nil }
        } message: {
            Text(L.recipe_dieses_rezept_wird_dauerhaft.localized)
        }
        .alert(L.deleteMenuTitle.localized, isPresented: $showDeleteMenuAlert) {
            Button(L.delete.localized, role: .destructive) {
                Task { await confirmDeleteSelectedMenu() }
            }
            Button(L.cancel.localized, role: .cancel) {}
        } message: {
            Text(L.recipe_dieses_menü_ohne_rezepte.localized)
        }
        .sheet(isPresented: $showManualRecipeBuilder) {
            ManualRecipeBuilderView()
                .environmentObject(app)
        }
        .sheet(isPresented: $showSocialImport) {
            SocialRecipeImportView(onFinished: { recipe in
                if !recipes.contains(where: { $0.id == recipe.id }) { recipes.insert(recipe, at: 0) }
                navigationRecipeId = recipe.id
            })
            .environmentObject(app)
        }
    }
    
    func confirmDeleteSelectedMenu() async {
        guard let token = app.accessToken, let menu = selectedMenu else { return }
        do {
            try await app.deleteMenu(menuId: menu.id, accessToken: token)
            await MainActor.run {
                menus.removeAll { $0.id == menu.id }
                selectedMenu = nil
                selectedMenuRecipeIds = []
                showDeleteMenuAlert = false
            }
        } catch {
            await MainActor.run { showDeleteMenuAlert = false }
        }
    }
    
    struct CourseGroup { let course: String; let recipes: [Recipe] }

    func groupedByCourse(menuId: String) -> [CourseGroup] {
        let order = ["Vorspeise", "Hauptspeise", "Nachspeise", "Beilage", "Getränk", "Sonstiges"]
        let ids = selectedMenuRecipeIds
        let items = recipes.filter { ids.contains($0.id) }
        var buckets: [String: [Recipe]] = [:]
        for r in items {
            let c = menuCourseMap[r.id] ?? "Sonstiges"
            buckets[c, default: []].append(r)
        }
        var result: [CourseGroup] = []
        for key in order {
            if let arr = buckets[key], !arr.isEmpty { result.append(CourseGroup(course: key, recipes: arr)) }
            buckets.removeValue(forKey: key)
        }
        for (key, arr) in buckets where !arr.isEmpty { result.append(CourseGroup(course: key, recipes: arr)) }
        return result
    }

    func reloadSelectedMenuRecipes() async {
        guard let token = app.accessToken else { return }
        if let menu = selectedMenu {
            await loadMenuRecipeIds(menuId: menu.id, token: token, updateSelected: true)
        } else {
            await MainActor.run {
                self.selectedMenuRecipeIds = []
                self.selectedMenuLoaded = true
            }
        }
    }
    
    // Lade Menü-Rezept-IDs für ein spezifisches Menü (mit Caching)
    private func loadMenuRecipeIds(menuId: String, token: String, updateSelected: Bool = false) async {
        // Prüfe Cache zuerst
        if let cached = menuRecipeIdsCache[menuId] {
            if updateSelected {
                await MainActor.run {
                    self.selectedMenuRecipeIds = cached
                    self.selectedMenuLoaded = true
                }
            }
            return
        }
        
        // Verhindere doppeltes Laden
        if menuRecipeIdsLoading.contains(menuId) {
            return
        }
        
        await MainActor.run {
            self.menuRecipeIdsLoading.insert(menuId)
            if updateSelected {
                self.selectedMenuLoaded = false
            }
        }
        
        if let ids = try? await app.fetchMenuRecipeIds(menuId: menuId, accessToken: token) {
            await MainActor.run {
                let idSet = Set(ids)
                self.menuRecipeIdsCache[menuId] = idSet
                if updateSelected {
                    self.selectedMenuRecipeIds = idSet
                    self.selectedMenuLoaded = true
                }
                self.menuRecipeIdsLoading.remove(menuId)
            }
        } else {
            // Fehler: markiere als geladen, damit UI nicht leer bleibt
            await MainActor.run {
                if updateSelected {
                    self.selectedMenuLoaded = true
                }
                self.menuRecipeIdsLoading.remove(menuId)
            }
        }
    }
    
    // Preload Menü-Rezept-IDs für alle Menüs parallel
    private func preloadAllMenuRecipeIds(token: String) async {
        let menuIds = menus.map { $0.id }
        
        // Lade alle IDs parallel
        await withTaskGroup(of: Void.self) { group in
            for menuId in menuIds {
                // Skip wenn bereits im Cache oder wird gerade geladen
                if menuRecipeIdsCache[menuId] != nil || menuRecipeIdsLoading.contains(menuId) {
                    continue
                }
                
                group.addTask {
                    await loadMenuRecipeIds(menuId: menuId, token: token, updateSelected: false)
                }
            }
        }
    }
    
    func createMenu(title: String) async {
        guard let token = app.accessToken, let userId = KeychainManager.get(key: "user_id") else { return }
        do {
            let created = try await app.createMenu(title: title, accessToken: token, userId: userId)
            await MainActor.run {
                self.menus.insert(created, at: 0)
                self.newMenuTitle = ""
                self.showNewMenuSheet = false
            }
        } catch {
            await MainActor.run { self.error = "Menü konnte nicht erstellt werden" }
        }
    }
    
    func renameSelectedMenu(title: String) async {
        guard let token = app.accessToken, let menu = selectedMenu else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let updated = try await app.renameMenu(menuId: menu.id, newTitle: trimmed, accessToken: token)
            await MainActor.run {
                if let idx = menus.firstIndex(where: { $0.id == updated.id }) {
                    menus[idx] = updated
                }
                selectedMenu = updated
                renameMenuTitle = ""
                showRenameMenuSheet = false
            }
        } catch {
            await MainActor.run { self.error = L.recipes_renameMenuFailed.localized }
        }
    }
    
    func add(recipe: Recipe, to menu: Menu) async {
        guard let token = app.accessToken else { return }
        do {
            try await app.addRecipeToMenu(menuId: menu.id, recipeId: recipe.id, accessToken: token)
            // Update cache
            await MainActor.run {
                if var ids = menuRecipeIdsCache[menu.id] {
                    ids.insert(recipe.id)
                    menuRecipeIdsCache[menu.id] = ids
                }
            }
            await reloadSelectedMenuRecipes()
            await MainActor.run { assigningRecipe = nil }
        } catch {}
    }
    
    func confirmDelete(recipe: Recipe?) async {
        guard let recipe = recipe else { return }
        deleting = true
        defer { deleting = false }
        
        let recipeId = recipe.id
        
        // Markiere als gelöscht, damit es nicht wieder erscheint
        await MainActor.run {
            deletedRecipeIds.insert(recipeId)
            recipes.removeAll { $0.id == recipeId }
            selectedMenuRecipeIds.remove(recipeId)
            // Entferne auch aus allen Menü-Caches
            for menuId in menuRecipeIdsCache.keys {
                menuRecipeIdsCache[menuId]?.remove(recipeId)
            }
            toDelete = nil
            showDeleteAlert = false
        }
        
        // Entferne auch aus dem Cache
        await MainActor.run {
            app.cachedRecipes.removeAll { $0.id == recipeId }
            app.saveCachedRecipesToDisk(recipes: app.cachedRecipes, menus: app.cachedMenus)
            Logger.info("[PersonalRecipesView] Removed recipe \(recipeId) from cache", category: .data)
        }
        
        // Versuche das Rezept zu löschen
        await app.deleteRecipeOrQueue(recipeId: recipeId)
        
        // Lade die Liste im Hintergrund neu (nur wenn online), um sicherzustellen, dass alles synchron ist
        // Das gelöschte Rezept wird durch deletedRecipeIds gefiltert und erscheint nicht wieder
        if selectedMenu == nil {
        await loadRecipes(keepVisible: true)
        } else {
            // Bei Menü-Filter: Nur die Menü-Rezepte neu laden
            await reloadSelectedMenuRecipes()
        }
        
        // Entferne aus deletedRecipeIds nach erfolgreichem Neuladen (wenn Server bestätigt, dass es gelöscht ist)
        // Das passiert automatisch, wenn loadRecipes die aktualisierte Liste lädt
        await MainActor.run {
            // Prüfe ob das Rezept noch in der geladenen Liste ist
            if !recipes.contains(where: { $0.id == recipeId }) {
                // Rezept wurde erfolgreich gelöscht, entferne aus deletedRecipeIds
                deletedRecipeIds.remove(recipeId)
            }
        }
    }
    
    /// Lädt gecachte Rezepte sofort, falls verfügbar
    func loadCachedRecipesIfAvailable() async {
        // Lade gecachte Rezepte und Menüs sofort für instant display
        await MainActor.run {
            if !app.cachedRecipes.isEmpty {
                // Zeige sofort an, auch wenn nur 1 Rezept im Cache ist
                self.recipes = app.cachedRecipes
                self.menus = app.cachedMenus
                self.loading = false
                Logger.info("[PersonalRecipesView] Loaded \(app.cachedRecipes.count) cached recipes for instant display", category: .data)
            } else {
                // Cache ist leer - starte sofortiges Laden vom Netzwerk
                Logger.info("[PersonalRecipesView] No cached recipes available, will load from network", category: .data)
            }
        }
    }
    
    func loadRecipes(keepVisible: Bool = false) async {
        let tabOpenTime = Date()
        print("📱 [PERFORMANCE] ========================================")
        print("📱 [PERFORMANCE] 'Meine Rezepte' Tab OPENED at \(tabOpenTime)")
        print("📱 [PERFORMANCE] keepVisible: \(keepVisible)")
        
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = app.accessToken else {
            await MainActor.run { 
                self.error = "Nicht angemeldet"
                self.loading = false
            }
            print("❌ [PERFORMANCE] Not authenticated")
            return
        }
        
        // OPTIMIZATION: Wenn Cache vorhanden ist, zeige Cache sofort (auch wenn alt)
        // Background refresh lädt dann im Hintergrund neue Daten
        if !keepVisible {
            if !app.cachedRecipes.isEmpty {
                let cacheAge = app.recipesCacheTimestamp.map { Date().timeIntervalSince($0) } ?? 0
                print("💾 [PERFORMANCE] Cache found: \(app.cachedRecipes.count) recipes, \(app.cachedMenus.count) menus")
                print("💾 [PERFORMANCE] Cache age: \(String(format: "%.1f", cacheAge))s")
                
                let uiUpdateStartTime = Date()
                await MainActor.run {
                    self.recipes = app.cachedRecipes
                    self.menus = app.cachedMenus
                    self.loading = false // Seite sofort anzeigen!
                    let uiUpdateDuration = Date().timeIntervalSince(uiUpdateStartTime)
                    let totalDuration = Date().timeIntervalSince(tabOpenTime)
                    print("⚡ [PERFORMANCE] UI updated from cache in \(String(format: "%.3f", uiUpdateDuration))s")
                    print("⚡ [PERFORMANCE] Total time to display: \(String(format: "%.3f", totalDuration))s")
                    print("✅ [PERFORMANCE] Recipes displayed INSTANTLY from cache")
                    Logger.info("[PersonalRecipesView] Using cache (\(app.cachedRecipes.count) recipes) - instant display", category: .data)
                }
                
                // Lade im Hintergrund aktualisiert (auch wenn Cache frisch ist, für Background-Refresh)
                print("🔄 [PERFORMANCE] Starting background refresh...")
                Task.detached(priority: .utility) {
                    await self.loadRecipesFromNetwork(userId: userId, token: token, keepVisible: true)
                }
                return
            } else {
                print("⚠️ [PERFORMANCE] No cache available - loading from network")
            }
        }
        
        // Kein Cache vorhanden: Lade sofort
        if !keepVisible { 
            loading = true
            print("⏳ [PERFORMANCE] Loading state set to true - showing loading indicator")
        }
        
        await loadRecipesFromNetwork(userId: userId, token: token, keepVisible: keepVisible)
    }
    
    private func loadRecipesFromNetwork(userId: String, token: String, keepVisible: Bool) async {
        let networkStartTime = Date()
        print("📡 [PERFORMANCE] Network load STARTED at \(networkStartTime)")
        print("📡 [PERFORMANCE] Mode: \(keepVisible ? "Background refresh" : "Foreground load")")
        
        do {
            // Wenn ein Menü aktiv ist, markiere als nicht geladen bis IDs neu geladen wurden
            if selectedMenu != nil { await MainActor.run { self.selectedMenuLoaded = false } }
            
            // OPTIMIZATION: Lade alle Rezepte und Menüs in einem einzigen parallelen Call
            // Keine separaten Calls mehr - alles auf einmal
            let parallelStartTime = Date()
            print("📡 [PERFORMANCE] Starting parallel requests (recipes + menus)...")
            async let recipesTask = loadRecipesFromSupabase(userId: userId, token: token)
            async let menusTask = app.fetchMenus(accessToken: token, userId: userId)
            
            // Warte auf beide Calls parallel
            let (allRecipes, menusResult) = try await (recipesTask, menusTask)
            let parallelDuration = Date().timeIntervalSince(parallelStartTime)
            print("📡 [PERFORMANCE] Parallel requests completed in \(String(format: "%.3f", parallelDuration))s")
            print("📡 [PERFORMANCE] Received: \(allRecipes.count) recipes, \(menusResult.count) menus")
            
            let list = allRecipes
            
            let uiUpdateStartTime = Date()
            await MainActor.run { 
                self.recipes = list
                self.error = nil
                self.menus = menusResult
                // CRITICAL: Always set loading = false after loading completes
                self.loading = false
                // Entferne gelöschte Rezepte aus deletedRecipeIds, die nicht mehr in der Liste sind
                // (d.h. die erfolgreich vom Server gelöscht wurden)
                self.deletedRecipeIds = self.deletedRecipeIds.filter { recipeId in
                    list.contains(where: { $0.id == recipeId })
                }
                if let cur = self.selectedMenu, let updated = menusResult.first(where: { $0.id == cur.id }) {
                        self.selectedMenu = updated
                    }
                let uiUpdateDuration = Date().timeIntervalSince(uiUpdateStartTime)
                let totalDuration = Date().timeIntervalSince(networkStartTime)
                print("⚡ [PERFORMANCE] UI updated in \(String(format: "%.3f", uiUpdateDuration))s")
                print("✅ [PERFORMANCE] Network load COMPLETED in \(String(format: "%.3f", totalDuration))s")
                print("✅ [PERFORMANCE] Displaying \(list.count) recipes and \(menusResult.count) menus")
                Logger.info("[PersonalRecipesView] Loaded \(list.count) recipes and \(menusResult.count) menus", category: .data)
                }
            
            // OPTIMIZATION: Update cache with fresh data for next time
            let cacheUpdateStartTime = Date()
            await MainActor.run {
                app.cachedRecipes = list
                app.cachedMenus = menusResult
                app.recipesCacheTimestamp = Date()
                let cacheUpdateDuration = Date().timeIntervalSince(cacheUpdateStartTime)
                print("💾 [PERFORMANCE] Cache updated in \(String(format: "%.3f", cacheUpdateDuration))s")
                print("💾 [PERFORMANCE] Cached \(list.count) recipes and \(menusResult.count) menus")
            }
            
            // Speichere auch auf Disk für Persistenz
            let diskSaveStartTime = Date()
            app.saveCachedRecipesToDisk(recipes: list, menus: menusResult)
            let diskSaveDuration = Date().timeIntervalSince(diskSaveStartTime)
            print("💿 [PERFORMANCE] Disk save completed in \(String(format: "%.3f", diskSaveDuration))s")
            
            // OPTIMIZATION: Preload Menü-Rezept-IDs für alle Menüs parallel im Hintergrund
            // Dies macht das Wechseln zwischen Menüs viel schneller
            Task.detached(priority: .userInitiated) {
                await self.preloadAllMenuRecipeIds(token: token)
            }
            
            // Lade sofort IDs für das aktuell ausgewählte Menü (falls vorhanden)
            if let menuId = selectedMenu?.id {
                await loadMenuRecipeIds(menuId: menuId, token: token, updateSelected: true)
            }
        } catch {
            let errorDuration = Date().timeIntervalSince(networkStartTime)
            print("❌ [PERFORMANCE] Network load FAILED after \(String(format: "%.3f", errorDuration))s")
            print("❌ [PERFORMANCE] Error: \(error.localizedDescription)")
            Logger.error("Failed to load personal recipes", error: error, category: .data)
            await MainActor.run {
                // CRITICAL: Always set loading = false so empty state can be shown
                self.loading = false
                
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.error = "Keine Internetverbindung"
                    case .timedOut:
                        // Bei Timeout: Zeige leeren State statt Fehler - App bleibt nutzbar
                        self.recipes = []
                        self.menus = []
                        self.error = nil
                        print("⚠️ [PERFORMANCE] Personal recipes timed out - showing empty state")
                    default:
                        // Bei Fehlern Liste beibehalten, keine Leerstates forcieren
                        self.error = nil
                    }
                } else {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    // Helper function to load the first recipe immediately
    // Helper function to load all recipes from Supabase
    private func loadRecipesFromSupabase(userId: String, token: String) async throws -> [Recipe] {
        let requestStartTime = Date()
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // Aggressive timeout - Query sollte schnell sein
        request.timeoutInterval = 5.0
        
        let networkStartTime = Date()
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        let networkDuration = Date().timeIntervalSince(networkStartTime)
        let dataSizeKB = Double(data.count) / 1024.0
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let totalDuration = Date().timeIntervalSince(requestStartTime)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("❌ [PERFORMANCE] Recipes request FAILED after \(String(format: "%.3f", totalDuration))s (HTTP \(statusCode))")
            throw URLError(.badServerResponse)
        }
        
        let decodeStartTime = Date()
        let recipes = try JSONDecoder().decode([Recipe].self, from: data)
        let decodeDuration = Date().timeIntervalSince(decodeStartTime)
        let totalDuration = Date().timeIntervalSince(requestStartTime)
        
        print("📡 [PERFORMANCE] Recipes API: Network=\(String(format: "%.3f", networkDuration))s, Decode=\(String(format: "%.3f", decodeDuration))s, Total=\(String(format: "%.3f", totalDuration))s, Size=\(String(format: "%.2f", dataSizeKB))KB, Recipes=\(recipes.count)")
        
        return recipes
    }
}



// MARK: - Share Recipe Sheet
private struct ShareRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let privateRecipes: [Recipe]
    let onSelect: (Recipe) -> Void
    
    var body: some View {
        NavigationView {
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
                
                if privateRecipes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(L.recipe_keine_privaten_rezepte.localized)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text(L.recipe_alle_deine_rezepte_sind.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(privateRecipes) { recipe in
                                Button(action: {
                                    onSelect(recipe)
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        // Recipe thumbnail placeholder
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(.ultraThinMaterial.opacity(0.5))
                                            Image(systemName: "fork.knife")
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                        .frame(width: 60, height: 60)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.title)
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            if let tags = recipe.tags, !tags.isEmpty {
                                                let visibleTags = tags.filter { !$0.hasPrefix("_") }
                                                if !visibleTags.isEmpty {
                                                    Text(visibleTags.prefix(2).joined(separator: ", "))
                                                        .font(.caption)
                                                        .foregroundStyle(.white.opacity(0.7))
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundStyle(.white)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(.ultraThinMaterial.opacity(0.3))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
.navigationTitle(L.shareRecipeTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.done.localized) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Recipe Card
struct RecipeCard: View {
    @EnvironmentObject var app: AppState
    let recipe: Recipe
    var onDelete: (() -> Void)? = nil
    var onAssign: (() -> Void)? = nil
    
    // OPTIMIZATION: Pre-compute image URLs once (lazy evaluation)
    private var imageURLs: [URL] {
        guard let imageUrl = recipe.image_url, !imageUrl.isEmpty else {
            Logger.debug("[RecipeCard] No image_url for recipe: \(recipe.title)", category: .data)
            return []
        }
        
        // Filter out Base64 images (should not happen, but safety check)
        if imageUrl.hasPrefix("data:image/") {
            Logger.warning("[RecipeCard] Base64 image detected for recipe: \(recipe.title) - skipping", category: .data)
            return []
        }
        
        // Validate URL format
        guard let first = URL(string: imageUrl), first.scheme != nil, first.scheme == "http" || first.scheme == "https" else {
            Logger.warning("[RecipeCard] Invalid image URL format for recipe: \(recipe.title) - URL: \(imageUrl.prefix(50))", category: .data)
            return []
        }
        
        if imageUrl.contains("_0.") {
            var arr = [first]
            if let u1 = URL(string: imageUrl.replacingOccurrences(of: "_0.", with: "_1.")) { arr.append(u1) }
            if let u2 = URL(string: imageUrl.replacingOccurrences(of: "_0.", with: "_2.")) { arr.append(u2) }
            return arr
        }
        return [first]
    }
    
    private var visibleTags: [String] {
        guard let tags = recipe.tags, !tags.isEmpty else { return [] }
        return tags.filter { !$0.hasPrefix("_") }
    }
    
    var body: some View {
        // OPTIMIZATION: Use @ViewBuilder to reduce view hierarchy complexity
        VStack(alignment: .leading, spacing: 0) {
            // Recipe Image(s) with swipe
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomLeading) {
                    // Image - OPTIMIZATION: Simplified view hierarchy
                    if !imageURLs.isEmpty {
                        // OPTIMIZATION: Single image doesn't need TabView (better performance)
                        if imageURLs.count == 1 {
                            CachedAsyncImage(url: imageURLs[0]) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipped()
                            } placeholder: {
                                placeholderImage
                            }
                        } else {
                            TabView {
                                ForEach(imageURLs, id: \.self) { url in
                                    CachedAsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 180)
                                            .clipped()
                                    } placeholder: {
                                        placeholderImage
                                    }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        }
                    } else {
                        placeholderImage
                    }
                
                    // Gradient overlay for better text readability
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                    
                    // Recipe title overlay
                    Text(recipe.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped()
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3),
                        Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Recipe Info
            VStack(alignment: .leading, spacing: 8) {
                if !visibleTags.isEmpty {
                    TagChips(tags: Array(visibleTags.prefix(3)))
                }
                
                HStack(spacing: 12) {
                    if let cookTime = recipe.cooking_time {
                        Label(cookTime, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    Spacer()
                    
                        HStack(spacing: 6) {
                            if let onAssign {
                                Button(action: onAssign) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            if let onDelete {
                                Button(action: onDelete) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3),
                    Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "frying.pan.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.5))
        }
        .frame(height: 180)
    }
}
