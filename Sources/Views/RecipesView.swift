import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var selectedTab = 0
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Selector
                HStack(spacing: 0) {
                    TabButton(title: L.myRecipes.localized, isSelected: selectedTab == 0) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = 0
                        }
                    }
                    .accessibilityLabel(L.myRecipes.localized)
                    .accessibilityHint(selectedTab == 0 ? "Aktuell ausgewählt" : "Wechselt zu Meine Rezepte")
                    TabButton(title: L.community.localized, isSelected: selectedTab == 1) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = 1
                        }
                    }
                    .accessibilityLabel(L.community.localized)
                    .accessibilityHint(selectedTab == 1 ? "Aktuell ausgewählt" : "Wechselt zu Community")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(.white)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    PersonalRecipesView()
                        .tag(0)
                    CommunityTabView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
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
            // Filter out invisible tags (those starting with _filter:)
            ForEach(tags.filter { !$0.hasPrefix("_filter:") }, id: \.self) { tag in
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

// MARK: - Menus Bar With Liked (Pinned)
private struct MenusBarWithLiked: View {
    let menus: [Menu]
    @Binding var selected: Menu?
    let likedCount: Int
    var onAdd: () -> Void
    var onDeleteSelected: () -> Void
    
    // Virtual "Liked" menu
    private var likedMenu: Menu {
        Menu(id: "__liked__", user_id: "", title: "Likes", created_at: nil)
    }
    
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
                    
                    // Pinned Liked menu (always first)
                    Text(L.label_likes.localized)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(selected?.id == likedMenu.id ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                        .foregroundColor(selected?.id == likedMenu.id ? .white : .black.opacity(0.7))
                        .clipShape(Capsule())
                        .onTapGesture { selected = likedMenu }
                    
                    ForEach(menus) { m in
                        MenuChip(title: m.title, isOn: selected?.id == m.id) { selected = m }
                    }
                }
            }
            if selected != nil && selected?.id != "__liked__" {
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

private struct AverageRatingView: View {
    @EnvironmentObject var app: AppState
    let recipeId: String
    
    // Get rating from cache (no API call needed)
    private var ratingStats: (average: Double?, count: Int)? {
        app.getCachedRatingStats(recipeId: recipeId)
    }

    var body: some View {
        HStack(spacing: 6) {
            let avg = ratingStats?.average
            let count = ratingStats?.count
            let full = Int(floor(avg ?? 0))
            let hasHalf = ((avg ?? 0) - Double(full)) >= 0.5
            ForEach(1...5, id: \.self) { i in
                let name: String = {
                    if avg == nil { return "star" }
                    if i <= full { return "star.fill" }
                    if hasHalf && i == full + 1 { return "star.leadinghalf.filled" }
                    return "star"
                }()
                Image(systemName: name)
                    .font(.system(size: 10))
                    .foregroundColor(avg == nil ? .gray.opacity(0.4) : .orange)
            }
            if let avg = avg {
                let label: String = {
                    if let c = count { return String(format: "%.1f (%d)", avg, c) }
                    else { return String(format: "%.1f", avg) }
                }()
                Text(label)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color(red: 0.85, green: 0.4, blue: 0.2) : .black.opacity(0.5))
                
                Rectangle()
                    .fill(isSelected ? 
                          LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
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
    @State private var showNewMenuSheet = false
    @State private var newMenuTitle: String = ""
    @State private var assigningRecipe: Recipe? = nil
    @State private var pushRecipe: Recipe? = nil
    @State private var selectedMenuLoaded: Bool = true
    @State private var showDeleteMenuAlert: Bool = false
    @State private var menuPlaceholders: [AppState.MenuSuggestion] = []
    @State private var menuCourseMap: [String: String] = [:]
    @State private var showManualRecipeBuilder = false
    @State private var deletedRecipeIds: Set<String> = [] // Track locally deleted recipes
    
    private var visibleRecipes: [Recipe] {
        // Filter out deleted recipes
        let filteredRecipes = recipes.filter { !deletedRecipeIds.contains($0.id) }
        
        // Special case: Liked recipes menu
        if selectedMenu?.id == "__liked__" {
            let likedIds = app.likedRecipesManager.likedRecipeIds
            return filteredRecipes.filter { likedIds.contains($0.id) }
        }
        
        if let _ = selectedMenu {
            // Until IDs sind geladen, zeige alle Rezepte statt leer
            if selectedMenuLoaded {
                return filteredRecipes.filter { selectedMenuRecipeIds.contains($0.id) }
            } else {
                return filteredRecipes
            }
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
                        // Menus bar should be available even in empty state
                        MenusBarWithLiked(menus: menus, selected: $selectedMenu, likedCount: app.likedRecipesManager.likedRecipeIds.count, onAdd: { showNewMenuSheet = true }, onDeleteSelected: { showDeleteMenuAlert = true })
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
                                
                                Spacer()
                            }
                            
                            // Menus bar with Liked
                            MenusBarWithLiked(menus: menus, selected: $selectedMenu, likedCount: app.likedRecipesManager.likedRecipeIds.count, onAdd: { showNewMenuSheet = true }, onDeleteSelected: { showDeleteMenuAlert = true })
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
                                    // Reload recipes if switching to liked menu (to load community recipes)
                                    if newId == "__liked__" {
                                        Task { await loadRecipes(keepVisible: true) }
                                    } else {
                                        Task { await reloadSelectedMenuRecipes() }
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
                                if let mid = selectedMenu?.id, mid != "__liked__" {
                                    let groups = groupedByCourse(menuId: mid)
                                    ForEach(groups, id: \.course) { group in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(group.course)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            ForEach(group.recipes) { recipe in
                                                RecipeCard(
                                                    recipe: recipe,
                                                    isPersonal: true,
                                                    onDelete: { toDelete = recipe; showDeleteAlert = true },
                                                    onAssign: { assigningRecipe = recipe }
                                                )
                                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                                .onTapGesture { pushRecipe = recipe }
                                            }
                                        }
                                    }
                                } else {
                                    ForEach(visibleRecipes) { recipe in
                                        RecipeCard(
                                            recipe: recipe,
                                            isPersonal: true,
                                            onDelete: { toDelete = recipe; showDeleteAlert = true },
                                            onAssign: { assigningRecipe = recipe }
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .onTapGesture { pushRecipe = recipe }
                                    }
                                }
                            }
                            .id(app.likedRecipesManager.likedRecipeIds)
                            // Hidden NavigationLink to trigger push
                            if let r = pushRecipe {
                                NavigationLink(destination: RecipeDetailView(recipe: r), isActive: Binding(
                                    get: { pushRecipe != nil },
                                    set: { if !$0 { pushRecipe = nil } }
                                )) {
                                    EmptyView()
                                }
                                .hidden()
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
            .refreshable { await loadRecipes(keepVisible: true) }
            .sheet(isPresented: $showNewMenuSheet) {
            NewMenuSheet(title: $newMenuTitle, onCreate: { t in Task { await createMenu(title: t) } })
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
            await MainActor.run { self.selectedMenuLoaded = false }
            if let ids = try? await app.fetchMenuRecipeIds(menuId: menu.id, accessToken: token) {
                await MainActor.run {
                    self.selectedMenuRecipeIds = Set(ids)
                    self.selectedMenuLoaded = true
                }
            } else {
                // Fehler: behalte vorherige IDs, aber markiere als geladen, damit UI nicht leer bleibt
                await MainActor.run { self.selectedMenuLoaded = true }
            }
        } else {
            await MainActor.run {
                self.selectedMenuRecipeIds = []
                self.selectedMenuLoaded = true
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
    
    func add(recipe: Recipe, to menu: Menu) async {
        guard let token = app.accessToken else { return }
        do {
            try await app.addRecipeToMenu(menuId: menu.id, recipeId: recipe.id, accessToken: token)
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
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = app.accessToken else {
            await MainActor.run { 
                self.error = "Nicht angemeldet"
                self.loading = false
            }
            return
        }
        
        // OPTIMIZATION: Wenn Cache vorhanden ist und nicht zu alt (max 5 Minuten), zeige Cache sofort
        if !keepVisible {
            if !app.cachedRecipes.isEmpty, 
               let timestamp = app.recipesCacheTimestamp,
               Date().timeIntervalSince(timestamp) < 300 { // 5 Minuten
                await MainActor.run {
                    self.recipes = app.cachedRecipes
                    self.menus = app.cachedMenus
                    self.loading = false // Seite sofort anzeigen!
                    Logger.info("[PersonalRecipesView] Using fresh cache (\(app.cachedRecipes.count) recipes)", category: .data)
                }
                // Lade im Hintergrund aktualisiert (nur wenn Cache älter als 1 Minute)
                let cacheAge = Date().timeIntervalSince(timestamp)
                if cacheAge > 60 {
                    Task.detached(priority: .utility) {
                        await self.loadRecipesFromNetwork(userId: userId, token: token, keepVisible: true)
                    }
                }
                return
            }
        }
        
        // Kein Cache oder Cache zu alt: Lade sofort das erste Rezept für instant display
        // loading bleibt true bis erstes Rezept geladen ist
        if !keepVisible { loading = true }
        
        await loadRecipesFromNetwork(userId: userId, token: token, keepVisible: keepVisible)
    }
    
    private func loadRecipesFromNetwork(userId: String, token: String, keepVisible: Bool) async {
        do {
            // Wenn ein Menü aktiv ist, markiere als nicht geladen bis IDs neu geladen wurden
            if selectedMenu != nil { await MainActor.run { self.selectedMenuLoaded = false } }
            
            // OPTIMIZATION: Lade zuerst das erste Rezept sofort für instant display
            // Dann lade den Rest im Hintergrund
            async let firstRecipeTask = loadFirstRecipeFromSupabase(userId: userId, token: token)
            async let menusTask = app.fetchMenus(accessToken: token, userId: userId)
            
            // Warte auf erstes Rezept und Menüs
            let (firstRecipe, menusResult) = try await (firstRecipeTask, menusTask)
            
            // Zeige sofort an, wenn wir mindestens 1 Rezept haben
            if let first = firstRecipe {
                await MainActor.run {
                    // Ersetze die Liste mit dem ersten Rezept, wenn noch keine Rezepte vorhanden sind
                    // Oder füge es hinzu, wenn es noch nicht vorhanden ist
                    if self.recipes.isEmpty {
                        self.recipes = [first]
                    } else if !self.recipes.contains(where: { $0.id == first.id }) {
                        self.recipes.insert(first, at: 0)
                    }
                    self.menus = menusResult
                    self.loading = false // Seite sofort anzeigen!
                    Logger.info("[PersonalRecipesView] Displaying first recipe immediately", category: .data)
                }
            } else {
                // Kein erstes Rezept gefunden, lade Menüs trotzdem
                await MainActor.run {
                    self.menus = menusResult
                    self.loading = false // Zeige Seite auch wenn keine Rezepte
                    Logger.info("[PersonalRecipesView] No recipes found, displaying empty state", category: .data)
            }
            }
            
            // Lade jetzt alle Rezepte im Hintergrund und ersetze die Liste
            let allRecipes = try await loadRecipesFromSupabase(userId: userId, token: token)
            
            var list = allRecipes
            
            // If liked menu is selected, also load liked community recipes
            if selectedMenu?.id == "__liked__" {
                let likedIds = app.likedRecipesManager.likedRecipeIds
                // Filter out own recipes from liked IDs to get community recipe IDs
                let ownRecipeIds = Set(list.map { $0.id })
                let communityLikedIds = likedIds.subtracting(ownRecipeIds)
                
                // Load community recipes that are liked (parallel zu anderen Tasks)
                if !communityLikedIds.isEmpty {
                    if let communityRecipes = try? await loadLikedCommunityRecipes(ids: Array(communityLikedIds), token: token) {
                        list.append(contentsOf: communityRecipes)
                    }
                }
            }
            
            await MainActor.run { 
                self.recipes = list
                self.error = nil
                self.menus = menusResult
                // Entferne gelöschte Rezepte aus deletedRecipeIds, die nicht mehr in der Liste sind
                // (d.h. die erfolgreich vom Server gelöscht wurden)
                self.deletedRecipeIds = self.deletedRecipeIds.filter { recipeId in
                    list.contains(where: { $0.id == recipeId })
                }
                if let cur = self.selectedMenu, let updated = menusResult.first(where: { $0.id == cur.id }) {
                        self.selectedMenu = updated
                    }
                }
            
            // OPTIMIZATION: Update cache with fresh data for next time
            await MainActor.run {
                app.cachedRecipes = list
                app.cachedMenus = menusResult
                app.recipesCacheTimestamp = Date()
            }
            
            // Speichere auch auf Disk für Persistenz
            app.saveCachedRecipesToDisk(recipes: list, menus: menusResult)
            
            // Lade Menü-Rezept-IDs parallel (nicht sequenziell)
            if selectedMenu != nil {
                    await reloadSelectedMenuRecipes()
            }
        } catch {
            Logger.error("Failed to load personal recipes", error: error, category: .data)
            await MainActor.run {
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.error = "Keine Internetverbindung"
                    case .timedOut:
                        self.error = "Zeitüberschreitung"
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
    private func loadFirstRecipeFromSupabase(userId: String, token: String) async throws -> Recipe? {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "1")
        ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let recipes = try JSONDecoder().decode([Recipe].self, from: data)
        return recipes.first
    }
    
    // Helper function to load all recipes from Supabase
    private func loadRecipesFromSupabase(userId: String, token: String) async throws -> [Recipe] {
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
        
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Recipe].self, from: data)
    }
    
    // Helper function to load liked community recipes
    private func loadLikedCommunityRecipes(ids: [String], token: String) async throws -> [Recipe] {
        var communityUrl = Config.supabaseURL
        communityUrl.append(path: "/rest/v1/recipes")
        let idList = "(" + ids.map { "\"\($0)\"" }.joined(separator: ",") + ")"
        communityUrl.append(queryItems: [
            URLQueryItem(name: "id", value: "in.\(idList)"),
            URLQueryItem(name: "is_public", value: "eq.true"),
            URLQueryItem(name: "select", value: "*")
        ])
        
        var communityRequest = URLRequest(url: communityUrl)
        communityRequest.httpMethod = "GET"
        communityRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        communityRequest.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        communityRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (communityData, communityResponse) = try await SecureURLSession.shared.data(for: communityRequest)
        
        guard let httpResponse = communityResponse as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Recipe].self, from: communityData)
    }
}

// MARK: - My Contributions View (User's public recipes)
struct MyContributionsView: View {
    @EnvironmentObject var app: AppState
    @State private var recipes: [Recipe] = []
    @State private var loading = true
    @State private var error: String?
    @State private var toDelete: Recipe? = nil
    @State private var showDeleteAlert = false
    @State private var deleting = false
    @State private var showShareSheet = false
    @State private var privateRecipes: [Recipe] = []
    
    var body: some View {
        Group {
            if loading {
                ProgressView()
                    .tint(Color(red: 0.85, green: 0.4, blue: 0.2))
            }
            else if let error {
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
            else if recipes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.4))
                    Text(L.recipe_keine_communitybeiträge.localized)
                        .font(.title3.bold())
                        .foregroundColor(.black.opacity(0.7))
                    Text(L.recipe_teile_deine_rezepte_mit.localized)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.5))
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        Task { await loadPrivateRecipes() }
                        showShareSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text(L.button_shareRecipe.localized)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .leading, endPoint: .trailing
                            ), in: Capsule()
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Share button always visible
                        HStack {
                            Spacer()
                            Button(action: {
                                Task { await loadPrivateRecipes() }
                                showShareSheet = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(L.button_share.localized)
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
                            .buttonStyle(.plain)
                        }
                        
                        LazyVStack(spacing: 12) {
                            ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                                RecipeCard(
                                    recipe: recipe,
                                    isPersonal: false,
                                    onDelete: { toDelete = recipe; showDeleteAlert = true }
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .onTapGesture {
                                    // Navigate to detail
                                }
                                .onAppear {
                                    // Preload images for next 5 recipes when this one appears
                                    let nextRecipes = recipes.suffix(from: min(index + 1, recipes.count)).prefix(5)
                                    let nextImageUrls = nextRecipes.compactMap { r -> URL? in
                                        guard let imageUrl = r.image_url else { return nil }
                                        return URL(string: imageUrl)
                                    }
                                    if !nextImageUrls.isEmpty {
                                        ImageCache.shared.preload(urls: Array(nextImageUrls))
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(L.nav_myContributions.localized)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadMyContributions() }
        .refreshable { await loadMyContributions() }
        .alert(L.alert_removeContribution.localized, isPresented: $showDeleteAlert) {
            Button(L.button_remove.localized, role: .destructive) {
                let r = toDelete
                Task { await confirmRemove(recipe: r) }
            }
            Button(L.button_cancel.localized, role: .cancel) { toDelete = nil }
        } message: {
            Text(L.recipe_dieses_rezept_wird_aus.localized)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareRecipeSheet(privateRecipes: privateRecipes, onSelect: { recipe in
                showShareSheet = false
                app.selectedRecipeForUpload = recipe
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $app.selectedRecipeForUpload) { recipe in
            CommunityUploadSheet(recipe: recipe)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    func loadPrivateRecipes() async {
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = app.accessToken else { return }
        
        do {
            // Load user's private recipes (not public - either NULL or false)
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/recipes")
            url.append(queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "or", value: "(is_public.is.null,is_public.eq.false)"),
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ])
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await SecureURLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return
            }
            
            let list = try JSONDecoder().decode([Recipe].self, from: data)
            
            await MainActor.run {
                self.privateRecipes = list
            }
        } catch {
            Logger.error("Failed to load private recipes", error: error, category: .data)
        }
    }
    
    func shareRecipe(_ recipe: Recipe) async {
        guard let token = app.accessToken else { return }
        
        do {
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/recipes")
            url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(recipe.id)")])
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body = ["is_public": true]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await SecureURLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Reload contributions to show the newly shared recipe
            await loadMyContributions()
        } catch {
            Logger.error("Failed to share recipe", error: error, category: .network)
        }
    }
    
    func confirmRemove(recipe: Recipe?) async {
        guard let recipe = recipe else { return }
        guard let token = app.accessToken else { return }
        deleting = true
        defer { deleting = false }
        
        // Optimistisches Entfernen aus der UI
        await MainActor.run {
            recipes.removeAll { $0.id == recipe.id }
            toDelete = nil
            showDeleteAlert = false
        }
        
        // Set is_public to false via PATCH
        do {
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/recipes")
            url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(recipe.id)")])
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body = ["is_public": false]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await SecureURLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
        } catch {
            Logger.error("Failed to remove recipe from community", error: error, category: .network)
            // Re-load in case of error
            await loadMyContributions()
        }
    }
    
    func loadMyContributions() async {
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = app.accessToken else {
            await MainActor.run {
                self.error = "Nicht angemeldet"
                self.loading = false
            }
            return
        }
        
        loading = true
        defer { loading = false }
        
        do {
            // Load user's public recipes
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/recipes")
            url.append(queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "is_public", value: "eq.true"),
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ])
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await SecureURLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            let list = try JSONDecoder().decode([Recipe].self, from: data)
            
            await MainActor.run {
                self.recipes = list
                self.error = nil
            }
        } catch {
            Logger.error("Failed to load my contributions", error: error, category: .data)
            await MainActor.run {
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.error = "Keine Internetverbindung"
                    case .timedOut:
                        self.error = "Zeitüberschreitung"
                    default:
                        self.recipes = []
                        self.error = nil
                    }
                } else {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Community Tab View (simplified, no sub-tabs)
struct CommunityTabView: View {
    var body: some View {
        CommunityRecipesView()
    }
}

// MARK: - Community Recipes View
struct CommunityRecipesView: View {
    @EnvironmentObject var app: AppState
    @State private var recipes: [Recipe] = []
    @State private var loading = true
    @State private var error: String?
    @State private var query: String = ""
    @State private var selectedFilters: Set<String> = []
    @State private var selectedLanguages: Set<String> = []  // Separate language selection
    @State private var showLanguageDropdown = false  // Language dropdown state
    @State private var showMyContributions = false
    @State private var filterByDietaryPreferences = false  // Toggle für Filter nach Ernährungspräferenzen
    
    // Pagination state
    @State private var currentPage = 0
    @State private var hasMore = true
    @State private var loadingMore = false
    private let pageSize = 50 // Anzahl Rezepte pro Seite (erhöht für schnellere Ladezeiten)
    
    // Filtered recipes (memoized with debouncing for performance)
    @State private var filteredRecipes: [Recipe] = []
    @State private var filterTask: Task<Void, Never>?
    
    // Navigation state for smooth scrolling
    @State private var selectedRecipe: Recipe?
    
    // Throttling for onAppear events
    @State private var lastLoadMoreTime: Date = Date()
    @State private var lastPreloadTime: Date = Date()
    
    // Prevent multiple simultaneous load requests
    @State private var loadTask: Task<Void, Never>?
    
    private var availableLanguages: [(code: String, name: String)] {
        [
            ("de", L.tag_german.localized),
            ("en", L.tag_english.localized),
            ("es", L.tag_spanish.localized),
            ("fr", L.tag_french.localized),
            ("it", L.tag_italian.localized)
        ]
    }
    
    private var availableFilters: [String] {
        [
            L.tag_vegan.localized,
            L.tag_vegetarian.localized,
            L.tag_pescetarian.localized,
            L.tag_glutenFree.localized,
            L.tag_lactoseFree.localized,
            L.tag_lowCarb.localized,
            L.tag_highProtein.localized,
            L.tag_halal.localized,
            L.tag_kosher.localized,
            L.tag_budget.localized,
            L.tag_spicy.localized,
            L.tag_quick.localized
        ]
    }
    private let lowCarbThreshold: Double = 25 // g Kohlenhydrate pro Portion
    private let quickThresholdMinutes: Int = 20 // Minuten für "Schnell" (<= 20 Minuten)
    
    // Apply filters to recipes (extracted for reuse)
    private func applyFilters(to recipes: [Recipe]) -> [Recipe] {
        func norm(_ s: String) -> String {
            s.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
        }
        func parseMinutes(_ s: String?) -> Int? {
            guard let s = s, let range = s.range(of: "\\d+", options: .regularExpression) else { return nil }
            return Int(s[range])
        }
        // Helper to check if recipe matches a language filter
        func matchesLanguage(_ recipe: Recipe, _ languageFilter: String) -> Bool {
            let filterNorm = norm(languageFilter)
            // Check language field
            if let lang = recipe.language {
                let langNorm = norm(lang)
                // Match language codes (de, en, es, fr, it) or full names
                if langNorm == filterNorm || 
                   (filterNorm == "deutsch" && (langNorm == "de" || langNorm == "german" || langNorm == "deutsch")) ||
                   (filterNorm == "englisch" && (langNorm == "en" || langNorm == "english" || langNorm == "englisch")) ||
                   (filterNorm == "spanisch" && (langNorm == "es" || langNorm == "spanish" || langNorm == "spanisch" || langNorm == "espanol")) ||
                   (filterNorm == "franzosisch" && (langNorm == "fr" || langNorm == "french" || langNorm == "franzosisch" || langNorm == "francais")) ||
                   (filterNorm == "italienisch" && (langNorm == "it" || langNorm == "italian" || langNorm == "italienisch" || langNorm == "italiano")) {
                    return true
                }
            }
            // Also check tags for language tags
            if let tags = recipe.tags {
                for tag in tags {
                    let tagNorm = norm(tag)
                    if tagNorm == filterNorm ||
                       (filterNorm == "deutsch" && (tagNorm == "de" || tagNorm == "german" || tagNorm == "deutsch")) ||
                       (filterNorm == "englisch" && (tagNorm == "en" || tagNorm == "english" || tagNorm == "englisch")) ||
                       (filterNorm == "spanisch" && (tagNorm == "es" || tagNorm == "spanish" || tagNorm == "spanisch" || tagNorm == "espanol")) ||
                       (filterNorm == "franzosisch" && (tagNorm == "fr" || tagNorm == "french" || tagNorm == "franzosisch" || tagNorm == "francais")) ||
                       (filterNorm == "italienisch" && (tagNorm == "it" || tagNorm == "italian" || tagNorm == "italienisch" || tagNorm == "italiano")) {
                        return true
                    }
                }
            }
            return false
        }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = recipes.filter { r in
            if q.isEmpty { return true }
            if r.title.localizedCaseInsensitiveContains(q) { return true }
            if let tags = r.tags, tags.contains(where: { $0.localizedCaseInsensitiveContains(q) }) { return true }
            if let diff = r.difficulty, diff.localizedCaseInsensitiveContains(q) { return true }
            // Special cases: text queries
            switch norm(q) {
            case "highprotein":
                if let nutrition = r.nutrition, (nutrition.protein_g ?? 0) >= 30 { return true }
            case "lowcarb":
                if let nutrition = r.nutrition, let c = nutrition.carbs_g, c < lowCarbThreshold { return true }
            case "schnell":
                if let mins = parseMinutes(r.cooking_time), mins < quickThresholdMinutes { return true }
            default:
                break
            }
            return false
        }
        // First apply language filter
        var languageFiltered = base
        if !selectedLanguages.isEmpty {
            Logger.debug("Applying language filter: \(selectedLanguages.count) selected", category: .ui)
            languageFiltered = base.filter { recipe in
                // Check if recipe matches any selected language
                for langName in selectedLanguages {
                    if matchesLanguage(recipe, langName) {
                        return true
                    }
                }
                return false
            }
            Logger.debug("Language filter resulted in \(languageFiltered.count) recipes", category: .ui)
        }
        
        // Apply dietary preferences filter (allergies and diets check) if enabled
        var dietaryFiltered = languageFiltered
        if filterByDietaryPreferences {
            let allergies = app.dietary.allergies.map { norm($0) }
            let diets = app.dietary.diets.map { norm($0) }
            
            // Helper function to check if recipe matches dietary restrictions
            func recipeMatchesDietaryPreferences(_ r: Recipe) -> Bool {
                // Normalize recipe tags for comparison
                // Include both tags and filter_tags (filter_tags are the hidden tags from AI)
                let allTags = (r.tags ?? []) + (r.filter_tags ?? [])
                let tagsNorm = Set(allTags.map { (tag: String) -> String in
                    let cleaned = tag.hasPrefix("_filter:") ? String(tag.dropFirst(8)) : tag
                    return norm(cleaned)
                })
                
                // Check allergies first (strict exclusion)
                if !allergies.isEmpty {
                    guard let ingredients = r.ingredients, !ingredients.isEmpty else {
                        // If no ingredients, we can't check - but if recipe has tags indicating it's safe, allow it
                        // Otherwise, be conservative and exclude if we have allergies set
                        return false  // Exclude recipes without ingredients if allergies are set
                    }
                    
                    let normalizedIngredients = ingredients.map { norm($0) }
                    for allergy in allergies {
                        if normalizedIngredients.contains(where: { ingredient in
                            ingredient.contains(allergy) || allergy.contains(ingredient)
                        }) {
                            Logger.debug("Recipe '\(r.title)' excluded due to allergy: \(allergy)", category: .ui)
                            return false
                        }
                    }
                }
                
                // Check dietary restrictions (diets)
                if !diets.isEmpty {
                    // Map localized diet names to tag names
                    let dietToTagMap: [String: String] = [
                        "vegan": "vegan",
                        "vegetarisch": "vegetarian",
                        "vegetarian": "vegetarian",
                        "pescetarisch": "pescetarian",
                        "pescetarian": "pescetarian",
                        "pescatarian": "pescetarian"
                    ]
                    
                    // Check if recipe matches any of the selected diets
                    var matchesAnyDiet = false
                    for diet in diets {
                        let dietTag = dietToTagMap[diet] ?? diet
                        
                        // Check if recipe has the matching tag
                        if tagsNorm.contains(dietTag) {
                            matchesAnyDiet = true
                            break
                        }
                    }
                    
                    // If user has selected diets, recipe MUST match at least one diet tag
                    // KI should add appropriate tags to all recipes, so we only check tags
                    if !matchesAnyDiet {
                        Logger.debug("Recipe '\(r.title)' excluded - does not match any selected diet tags", category: .ui)
                        return false
                    }
                }
                
                return true  // Recipe matches dietary preferences
            }
            
            dietaryFiltered = languageFiltered.filter { recipeMatchesDietaryPreferences($0) }
            Logger.debug("Dietary filter applied: \(dietaryFiltered.count) recipes remaining (from \(languageFiltered.count))", category: .ui)
        }
        
        // Then apply other filters
        if selectedFilters.isEmpty { return dietaryFiltered }
        let wanted = selectedFilters.map { norm($0) }
        return dietaryFiltered.filter { r in
            // Normalize tags, removing _filter: prefix for comparison but keeping original for display
            // Include both tags and filter_tags (filter_tags are the hidden tags from AI)
            let allTags = (r.tags ?? []) + (r.filter_tags ?? [])
            let tagsNorm = Set(allTags.map { (tag: String) -> String in
                // Remove _filter: prefix if present for filtering comparison
                let cleaned = tag.hasPrefix("_filter:") ? String(tag.dropFirst(8)) : tag
                return norm(cleaned)
            })
            var matched = false
            for f in wanted {
                // Normalize filter name to match tag format
                let filterNorm = norm(f)
                
                // Map localized filter names to tag names
                let filterToTagMap: [String: String] = [
                    "vegan": "vegan",
                    "vegetarian": "vegetarian",
                    "pescetarian": "pescetarian",
                    "pescatarian": "pescetarian",
                    "pescetarisch": "pescetarian",
                    "glutenfrei": "gluten-free",
                    "glutenfree": "gluten-free",
                    "laktosefrei": "lactose-free",
                    "lactosefree": "lactose-free",
                    "kohlenhydratarm": "low-carb",
                    "lowcarb": "low-carb",
                    "proteinreich": "high-protein",
                    "highprotein": "high-protein",
                    "halal": "halal",
                    "kosher": "kosher",
                    "koscher": "kosher",
                    "günstig": "budget",
                    "budget": "budget",
                    "scharf": "spicy",
                    "spicy": "spicy",
                    "schnell": "quick",
                    "quick": "quick"
                ]
                
                let tagName = filterToTagMap[filterNorm] ?? filterNorm
                
                // Check nutrition-based filters
                if tagName == "high-protein" {
                    if let nutrition = r.nutrition, (nutrition.protein_g ?? 0) >= 30 { matched = true; break }
                    if tagsNorm.contains("high-protein") || tagsNorm.contains("highprotein") { matched = true; break }
                } else if tagName == "low-carb" {
                    if let nutrition = r.nutrition, let c = nutrition.carbs_g, c < lowCarbThreshold { matched = true; break }
                    if tagsNorm.contains("low-carb") || tagsNorm.contains("lowcarb") { matched = true; break }
                } else if tagName == "quick" {
                    if let mins = parseMinutes(r.cooking_time), mins < quickThresholdMinutes { matched = true; break }
                    if tagsNorm.contains("quick") || tagsNorm.contains("schnell") { matched = true; break }
                } else if tagName == "vegetarian" {
                    // Only show recipes with vegetarian tag (KI should add this tag to all vegetarian recipes)
                    if tagsNorm.contains("vegetarian") || tagsNorm.contains("vegetarisch") {
                        matched = true
                        break
                    }
                } else if tagName == "vegan" {
                    // Only show recipes with vegan tag (KI should add this tag to all vegan recipes)
                    // Check both normalized tag name and filter name to handle variations
                    // The norm() function already normalizes tags (removes _filter: prefix and normalizes), so we check both
                    let hasVeganTag = tagsNorm.contains("vegan") || tagsNorm.contains(filterNorm)
                    if hasVeganTag {
                        matched = true
                        break
                } else {
                        // Debug: Log if recipe has tags but not vegan tag
                        if let tags = r.tags, !tags.isEmpty {
                            Logger.debug("Recipe '\(r.title)' has tags: \(tags.joined(separator: ", ")), normalized: \(tagsNorm), but no vegan tag", category: .ui)
                        }
                    }
                } else {
                    // Check if tag matches (with variations)
                    if tagsNorm.contains(tagName) || 
                       tagsNorm.contains(filterNorm) ||
                       (tagName == "gluten-free" && tagsNorm.contains("glutenfree")) ||
                       (tagName == "lactose-free" && tagsNorm.contains("lactosefree")) ||
                       (tagName == "low-carb" && tagsNorm.contains("lowcarb")) ||
                       (tagName == "high-protein" && tagsNorm.contains("highprotein")) ||
                       (tagName == "pescetarian" && (tagsNorm.contains("pescetarian") || tagsNorm.contains("pescatarian"))) {
                        matched = true
                        break
                    }
                }
            }
            return matched
        }
    }
    
    // Update filtered recipes with debouncing (150ms delay)
    private func updateFilteredRecipes() {
        filterTask?.cancel()
        filterTask = Task { @MainActor in
            // Debounce: Wait 150ms before applying filters
            try? await Task.sleep(nanoseconds: 150_000_000)
            
            guard !Task.isCancelled else { return }
            
            let filtered = applyFilters(to: recipes)
            self.filteredRecipes = filtered
        }
    }
    
    var body: some View {
        Group {
            if loading && recipes.isEmpty { 
                ProgressView()
                    .tint(Color(red: 0.85, green: 0.4, blue: 0.2))
            }
            else if let error { 
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
            else if recipes.isEmpty && !loading { 
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.4))
                    Text(L.recipe_noch_keine_communityrezepte.localized)
                        .font(.title3.bold())
                        .foregroundColor(.black.opacity(0.7))
                    Text(L.recipe_sei_der_erste_und.localized)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding()
            }
            else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Header mit Suchbar, Ernährungspräferenzen-Toggle und Meine Beiträge Button
                        HStack(spacing: 8) {
                            SearchBar(query: $query, placeholder: L.placeholder_searchCommunityLong.localized)
                            
                            // Toggle für Filter nach Ernährungspräferenzen
                            Button(action: {
                                withAnimation {
                                    filterByDietaryPreferences.toggle()
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Image(systemName: filterByDietaryPreferences ? "checkmark.shield.fill" : "shield")
                                        .font(.system(size: 16))
                                    Text(L.recipe_filterByDietaryPreferences.localized)
                                        .font(.caption2)
                                }
                                .foregroundColor(filterByDietaryPreferences ? .white : Color(red: 0.85, green: 0.4, blue: 0.2))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(filterByDietaryPreferences ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: MyContributionsView()) {
                                VStack(spacing: 2) {
                                    Image(systemName: "person.crop.square")
                                        .font(.system(size: 18))
                                    Text(L.recipe_meine.localized)
                                        .font(.caption2)
                                }
                                .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Filter Chips with Language Dropdown
                        FilterChipsBarWithLanguage(
                            availableLanguages: availableLanguages,
                            selectedLanguages: $selectedLanguages,
                            filterOptions: availableFilters,
                            selectedFilters: $selectedFilters,
                            showLanguageDropdown: $showLanguageDropdown
                        )
                        
                        // OPTIMIZATION: Use List instead of ScrollView+LazyVStack for better view recycling
                        // List has native view recycling and better scroll performance
                        List {
                            ForEach(Array(filteredRecipes.enumerated()), id: \.element.id) { index, recipe in
                                RecipeCard(recipe: recipe, isPersonal: false)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                    }
                                    .onAppear {
                                        // Throttle preloading: Only preload every 200ms to avoid lag
                                        let now = Date()
                                        if now.timeIntervalSince(lastPreloadTime) > 0.2 {
                                            lastPreloadTime = now
                                            
                                            // Preload images for next 3 recipes (reduced from 5)
                                            let nextRecipes = filteredRecipes.suffix(from: min(index + 1, filteredRecipes.count)).prefix(3)
                                            let nextImageUrls = nextRecipes.compactMap { r -> URL? in
                                                guard let imageUrl = r.image_url else { return nil }
                                                return URL(string: imageUrl)
                                            }
                                            if !nextImageUrls.isEmpty {
                                                Task.detached(priority: .utility) {
                                                    await ImageCache.shared.preload(urls: Array(nextImageUrls))
                                                }
                                            }
                                        }
                                        
                                        // Throttle load more: Only check every 500ms to avoid multiple simultaneous loads
                                        let timeSinceLastLoad = now.timeIntervalSince(lastLoadMoreTime)
                                        if timeSinceLastLoad > 0.5 && index >= filteredRecipes.count - 10 && hasMore && !loadingMore && query.isEmpty && selectedFilters.isEmpty && selectedLanguages.isEmpty {
                                            lastLoadMoreTime = now
                                            Task {
                                                await loadMoreCommunityRecipes()
                                            }
                                        }
                                    }
                            }
                            
                            // Loading indicator am Ende, wenn weitere Rezepte geladen werden
                            if loadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Color(red: 0.85, green: 0.4, blue: 0.2))
                                    Spacer()
                                }
                                .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        
                        if filteredRecipes.isEmpty && !loading {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text(query.isEmpty ? "Keine Rezepte gefunden" : "Keine Treffer für \"\(query)\"")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            // Language Dropdown Overlay (at top level)
            if showLanguageDropdown {
                VStack(spacing: 6) {
                    ForEach(availableLanguages, id: \.code) { language in
                        let isSelected = selectedLanguages.contains(language.name)
                        Button(action: {
                            Logger.debug("Language selection toggled: \(language.name)", category: .ui)
                            withAnimation {
                                if isSelected {
                                    selectedLanguages.remove(language.name)
                                } else {
                                    selectedLanguages.insert(language.name)
                                }
                            }
                        }) {
                            Text(language.name)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                                .foregroundColor(isSelected ? .white : .black.opacity(0.7))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
                .offset(x: 16, y: 110)  // Position below filter bar
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
                .zIndex(999)
            }
        }
        .navigationBarHidden(true)
        .task { await loadCommunityRecipes() }
        .background(
            // Hidden NavigationLink for smooth navigation (outside list for better performance)
            Group {
                if let recipe = selectedRecipe {
                    NavigationLink(
                        destination: RecipeDetailView(recipe: recipe),
                        isActive: Binding(
                            get: { selectedRecipe != nil },
                            set: { if !$0 { selectedRecipe = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
        )
        .refreshable { 
            // Reset und neu laden beim Pull-to-Refresh
            await MainActor.run {
                currentPage = 0
                hasMore = true
            }
            await loadCommunityRecipes() 
        }
        .onChange(of: query) { _ in updateFilteredRecipes() }
        .onChange(of: selectedFilters) { _ in updateFilteredRecipes() }
        .onChange(of: selectedLanguages) { _ in updateFilteredRecipes() }
        .onChange(of: filterByDietaryPreferences) { _ in updateFilteredRecipes() }
        .onChange(of: recipes) { _ in updateFilteredRecipes() }
    }
    
    func loadCommunityRecipes() async {
        // Cancel any existing load task
        loadTask?.cancel()
        
        guard let token = app.accessToken else {
            await MainActor.run { 
                self.error = "Nicht angemeldet"
                self.loading = false
            }
            return
        }
        
        // Reset pagination when loading fresh
        await MainActor.run {
            loading = true
            currentPage = 0
            hasMore = true
            recipes = []
        }
        
        // Create new load task
        loadTask = Task {
            await performLoadCommunityRecipes(token: token)
        }
        await loadTask?.value
    }
    
    private func performLoadCommunityRecipes(token: String) async {
        do {
            // Check if task was cancelled
            try Task.checkCancellation()
            
            // OPTIMIZATION: Lade sofort die erste volle Seite (50 Rezepte) für schnelle Anzeige
            let firstPage = try await loadCommunityRecipesPage(page: 0, pageSize: pageSize, token: token)
            
            // Check again after load
            try Task.checkCancellation()
            
            await MainActor.run {
                if !firstPage.isEmpty {
                    self.recipes = firstPage
                    self.loading = false // Seite sofort anzeigen!
                    self.currentPage = 1 // Nächste Seite ist 1
                    self.hasMore = firstPage.count >= pageSize
                    // Initialize filtered recipes immediately (no debounce on initial load)
                    self.filteredRecipes = self.applyFilters(to: firstPage)
                    Logger.info("[CommunityRecipesView] Displaying \(firstPage.count) recipes immediately", category: .data)
                } else {
                    self.loading = false
                    self.filteredRecipes = []
                    Logger.info("[CommunityRecipesView] No recipes found, displaying empty state", category: .data)
                }
            }
            
            // Preload images for first page in background
            let imageUrls = firstPage.compactMap { recipe -> URL? in
                guard let imageUrl = recipe.image_url, !imageUrl.isEmpty else { return nil }
                return URL(string: imageUrl)
            }
            if !imageUrls.isEmpty {
                Task { @MainActor in
                    ImageCache.shared.preload(urls: imageUrls)
                }
            }
            
            // Load batch ratings for first page in background
            let recipeIds = firstPage.map { $0.id }
            if let token = app.accessToken {
                Task {
                    await app.loadBatchRatings(recipeIds: recipeIds, accessToken: token)
                }
            }
        } catch is CancellationError {
            // Task was cancelled - don't show error, just return
            Logger.info("[CommunityRecipesView] Load task cancelled", category: .data)
            return
        } catch {
            Logger.error("Failed to load community recipes", error: error, category: .data)
            Logger.error("Error details: \(error.localizedDescription)", category: .data)
            if let nsError = error as NSError? {
                Logger.error("NSError domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo)", category: .data)
            }
            await MainActor.run {
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.error = "Keine Internetverbindung"
                    case .timedOut:
                        self.error = "Zeitüberschreitung"
                    case .badServerResponse:
                        self.error = "Server-Fehler beim Laden der Rezepte. Bitte versuche es später erneut."
                    default:
                        if self.recipes.isEmpty {
                            self.error = "Rezepte konnten nicht geladen werden: \(urlError.localizedDescription)"
                        }
                    }
                } else if let nsError = error as NSError? {
                    if self.recipes.isEmpty {
                        let errorMsg = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                        self.error = "Fehler: \(errorMsg)"
                    }
                } else {
                    if self.recipes.isEmpty {
                        self.error = error.localizedDescription
                    }
                }
                self.loading = false
            }
        }
    }
    
    // OPTIMIZATION: Lade weitere Rezepte mit Pagination
    func loadMoreCommunityRecipes() async {
        guard let token = app.accessToken,
              hasMore,
              !loadingMore else { return }
        
        await MainActor.run { loadingMore = true }
        
        do {
            // OPTIMIZATION: Lade 2 Seiten parallel für schnellere Ladezeiten (100 Rezepte auf einmal)
            async let page1Task = loadCommunityRecipesPage(page: currentPage, pageSize: pageSize, token: token)
            async let page2Task = loadCommunityRecipesPage(page: currentPage + 1, pageSize: pageSize, token: token)
            
            let (page1Recipes, page2Recipes) = try await (page1Task, page2Task)
            let allNewRecipes = page1Recipes + page2Recipes
            
            await MainActor.run {
                if allNewRecipes.count < pageSize * 2 {
                    hasMore = false // Keine weiteren Rezepte verfügbar
                }
                
                // Füge neue Rezepte hinzu (vermeide Duplikate)
                let existingIds = Set(recipes.map { $0.id })
                let uniqueNewRecipes = allNewRecipes.filter { !existingIds.contains($0.id) }
                recipes.append(contentsOf: uniqueNewRecipes)
                
                currentPage += 2 // 2 Seiten geladen
                loadingMore = false
                
                // Update filtered recipes after adding new ones
                updateFilteredRecipes()
                
                Logger.info("[CommunityRecipesView] Loaded pages \(currentPage - 1)-\(currentPage) with \(allNewRecipes.count) recipes. Total: \(recipes.count)", category: .data)
                
                // Preload images for new recipes in background
                let imageUrls = uniqueNewRecipes.compactMap { recipe -> URL? in
                    guard let imageUrl = recipe.image_url, !imageUrl.isEmpty else { return nil }
                    return URL(string: imageUrl)
                }
                if !imageUrls.isEmpty {
                    Task { @MainActor in
                        ImageCache.shared.preload(urls: imageUrls)
                    }
                }
                
                // Load batch ratings for new recipes in background
                let newRecipeIds = uniqueNewRecipes.map { $0.id }
                Task {
                    await app.loadBatchRatings(recipeIds: newRecipeIds, accessToken: token)
                }
            }
        } catch {
            Logger.error("Failed to load more community recipes", error: error, category: .data)
            await MainActor.run {
                loadingMore = false
                // Bei Fehler: Markiere als keine weiteren Rezepte, um endlose Retries zu vermeiden
                if currentPage == 0 {
                    hasMore = false
                }
            }
        }
    }
    
    // Helper function to load a page of community recipes with pagination
    private func loadCommunityRecipesPage(page: Int, pageSize: Int, token: String) async throws -> [Recipe] {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        
        // Calculate offset for pagination
        let offset = page * pageSize
        
        // OPTIMIZATION: Only load required fields for recipe cards (not full recipe data)
        // This significantly reduces payload size and improves loading speed
        // Note: user_email is not a database column, it's optional and not displayed in cards
        // user_id is required by Recipe model, so it must be included
        // Try with filter_tags first, fallback to without if column doesn't exist
        let selectFieldsWithFilterTags = "id,user_id,title,image_url,cooking_time,difficulty,tags,filter_tags,language,created_at"
        let selectFieldsWithoutFilterTags = "id,user_id,title,image_url,cooking_time,difficulty,tags,language,created_at"
        
        // First try with filter_tags
        var urlWithFilterTags = url
        urlWithFilterTags.append(queryItems: [
            URLQueryItem(name: "is_public", value: "eq.true"),
            URLQueryItem(name: "select", value: selectFieldsWithFilterTags),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(pageSize)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ])
        
        var request = URLRequest(url: urlWithFilterTags)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await SecureURLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.error("[CommunityRecipesView] Invalid response type", category: .network)
                throw URLError(.badServerResponse)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                Logger.error("[CommunityRecipesView] HTTP \(httpResponse.statusCode): \(errorBody)", category: .network)
                
                // If error mentions filter_tags column (400 or 500), try fallback without it
                if (httpResponse.statusCode == 400 || httpResponse.statusCode == 500) && (errorBody.contains("filter_tags") || errorBody.contains("column")) {
                    Logger.warning("[CommunityRecipesView] filter_tags column issue detected (HTTP \(httpResponse.statusCode)), trying fallback without it", category: .network)
                    return try await loadCommunityRecipesPageFallback(page: page, pageSize: pageSize, token: token, selectFields: selectFieldsWithoutFilterTags)
                }
                
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode([Recipe].self, from: data)
        } catch let error as URLError where error.code == .cancelled {
            // Request was cancelled - don't try fallback, just rethrow
            Logger.warning("[CommunityRecipesView] Request cancelled", category: .network)
            throw error
        } catch {
            // If any other error occurs, try fallback without filter_tags
            Logger.warning("[CommunityRecipesView] Error loading with filter_tags, trying fallback: \(error.localizedDescription)", category: .network)
            return try await loadCommunityRecipesPageFallback(page: page, pageSize: pageSize, token: token, selectFields: selectFieldsWithoutFilterTags)
        }
    }
    
    // Fallback function without filter_tags (in case column doesn't exist)
    private func loadCommunityRecipesPageFallback(page: Int, pageSize: Int, token: String, selectFields: String) async throws -> [Recipe] {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        
        let offset = page * pageSize
        
        url.append(queryItems: [
            URLQueryItem(name: "is_public", value: "eq.true"),
            URLQueryItem(name: "select", value: selectFields),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(pageSize)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            Logger.error("[CommunityRecipesView] Fallback also failed: HTTP \(statusCode), \(errorBody)", category: .network)
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Recipe].self, from: data)
    }
}

// MARK: - Filter Chips Bar with Language Dropdown
private struct FilterChipsBarWithLanguage: View {
    let availableLanguages: [(code: String, name: String)]
    @Binding var selectedLanguages: Set<String>
    let filterOptions: [String]
    @Binding var selectedFilters: Set<String>
    @Binding var showLanguageDropdown: Bool
    
    private var languageChipText: String {
        if selectedLanguages.isEmpty {
            return L.recipe_sprache.localized
        } else if selectedLanguages.count == 1 {
            return selectedLanguages.first ?? L.recipe_sprache.localized
        } else {
            return "\(selectedLanguages.count) " + L.recipe_sprachen.localized
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Language Dropdown Chip (always first)
                Button(action: { 
                    Logger.debug("Language dropdown toggled", category: .ui)
                    withAnimation {
                        showLanguageDropdown.toggle() 
                    } 
                }) {
                    HStack(spacing: 4) {
                        Text(languageChipText)
                        Image(systemName: showLanguageDropdown ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(!selectedLanguages.isEmpty ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                    .foregroundColor(!selectedLanguages.isEmpty ? .white : .black.opacity(0.7))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                
                // Regular Filter Chips
                ForEach(filterOptions, id: \.self) { opt in
                    let isOn = selectedFilters.contains(opt)
                    Text(opt)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isOn ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                        .foregroundColor(isOn ? .white : .black.opacity(0.7))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
                        .onTapGesture {
                            if isOn { selectedFilters.remove(opt) } else { selectedFilters.insert(opt) }
                        }
                }
                
                // Clear All Button
                if !selectedFilters.isEmpty || !selectedLanguages.isEmpty {
                    Button(action: {
                        selectedFilters.removeAll()
                        selectedLanguages.removeAll()
                    }) {
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
                                                // Filter out invisible tags (those starting with _filter:)
                                                let visibleTags = tags.filter { !$0.hasPrefix("_filter:") }
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

// MARK: - Like Button Component
private struct LikeButton: View {
    let recipeId: String
    @ObservedObject var likedManager: LikedRecipesManager
    
    private var isLiked: Bool {
        likedManager.isLiked(recipeId: recipeId)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                likedManager.toggleLike(recipeId: recipeId)
            }
        }) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundColor(isLiked ? .pink : .white)
                .padding(12)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4)
                )
                .padding(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recipe Card
struct RecipeCard: View {
    @EnvironmentObject var app: AppState
    let recipe: Recipe
    let isPersonal: Bool
    var onDelete: (() -> Void)? = nil
    var onAssign: (() -> Void)? = nil
    
    @State private var showReportSheet = false
    
    private var isLiked: Bool {
        app.likedRecipesManager.isLiked(recipeId: recipe.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Recipe Image(s) with swipe
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomLeading) {
                    // Image - OPTIMIZATION: Only use TabView if multiple images exist
                    Group {
                        if let imageUrl = recipe.image_url, let first = URL(string: imageUrl) {
                            let urls: [URL] = {
                                if imageUrl.contains("_0.") {
                                    var arr = [first]
                                    if let u1 = URL(string: imageUrl.replacingOccurrences(of: "_0.", with: "_1.")) { arr.append(u1) }
                                    if let u2 = URL(string: imageUrl.replacingOccurrences(of: "_0.", with: "_2.")) { arr.append(u2) }
                                    return arr
                                }
                                return [first]
                            }()
                            
                            // OPTIMIZATION: Single image doesn't need TabView (better performance)
                            if urls.count == 1 {
                                CachedAsyncImage(url: urls[0]) { image in
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
                                    ForEach(urls, id: \.self) { url in
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
                
                // Buttons overlay (top right)
                HStack(spacing: 8) {
                    // Report button (nur für Community-Rezepte)
                    if !isPersonal {
                        Button(action: { showReportSheet = true }) {
                            Image(systemName: "exclamationmark.bubble")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    LikeButton(recipeId: recipe.id, likedManager: app.likedRecipesManager)
                }
                .padding(12)
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
                if let tags = recipe.tags, !tags.isEmpty {
                    // Filter out invisible tags (those starting with _filter:)
                    let visibleTags = tags.filter { !$0.hasPrefix("_filter:") }
                    if !visibleTags.isEmpty {
                        TagChips(tags: Array(visibleTags.prefix(3)))
                    }
                }
                
                HStack(spacing: 12) {
                    if let cookTime = recipe.cooking_time {
                        Label(cookTime, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    if let difficulty = recipe.difficulty {
                        Label(difficulty, systemImage: "chart.bar")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    if !isPersonal && onDelete == nil {
                        AverageRatingView(recipeId: recipe.id)
                    } else {
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
                
                if !isPersonal, let username = recipe.user_email?.components(separatedBy: "@").first {
                    Label(username, systemImage: "person")
                        .font(.caption2)
                        .foregroundColor(.black.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .padding(12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .sheet(isPresented: $showReportSheet) {
            ReportReasonSheet(recipe: recipe, onReported: {})
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
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
