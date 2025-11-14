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
                    TabButton(title: L.community.localized, isSelected: selectedTab == 1) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = 1
                        }
                    }
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
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
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
            ForEach(tags, id: \.self) { tag in
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
    @State private var average: Double? = nil
    @State private var count: Int? = nil

    var body: some View {
        HStack(spacing: 6) {
            let avg = average
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
        .task(id: recipeId) {
            guard let token = app.accessToken else { return }
            if let stats = try? await app.fetchRatingStats(recipeId: recipeId, accessToken: token) {
                await MainActor.run {
                    self.average = stats.average
                    self.count = stats.count
                }
            } else {
                await MainActor.run {
                    self.average = nil
                    self.count = nil
                }
            }
        }
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
    
    private var visibleRecipes: [Recipe] {
        // Special case: Liked recipes menu
        if selectedMenu?.id == "__liked__" {
            let likedIds = app.likedRecipesManager.likedRecipeIds
            return recipes.filter { likedIds.contains($0.id) }
        }
        
        if let _ = selectedMenu {
            // Until IDs sind geladen, zeige alle Rezepte statt leer
            if selectedMenuLoaded {
                return recipes.filter { selectedMenuRecipeIds.contains($0.id) }
            } else {
                return recipes
            }
        }
        return recipes
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
            .task { await loadRecipes() }
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
        // Optimistisches Entfernen aus der UI
        await MainActor.run {
            recipes.removeAll { $0.id == recipe.id }
            selectedMenuRecipeIds.remove(recipe.id)
            toDelete = nil
            showDeleteAlert = false
        }
        await app.deleteRecipeOrQueue(recipeId: recipe.id)
        // Versuche, die Liste im Hintergrund zu aktualisieren (falls online)
        await loadRecipes(keepVisible: true)
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
        if !keepVisible { loading = true }
        defer { if !keepVisible { loading = false } }
        do {
            // Load directly from Supabase
            // Wenn ein Menü aktiv ist, markiere als nicht geladen bis IDs neu geladen wurden
            if selectedMenu != nil { await MainActor.run { self.selectedMenuLoaded = false } }
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
            
            var list = try JSONDecoder().decode([Recipe].self, from: data)
            
            // If liked menu is selected, also load liked community recipes
            if selectedMenu?.id == "__liked__" {
                let likedIds = app.likedRecipesManager.likedRecipeIds
                // Filter out own recipes from liked IDs to get community recipe IDs
                let ownRecipeIds = Set(list.map { $0.id })
                let communityLikedIds = likedIds.subtracting(ownRecipeIds)
                
                // Load community recipes that are liked
                if !communityLikedIds.isEmpty {
                    var communityUrl = Config.supabaseURL
                    communityUrl.append(path: "/rest/v1/recipes")
                    let idList = "(" + communityLikedIds.map { "\"\($0)\"" }.joined(separator: ",") + ")"
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
                    
                    if let (communityData, _) = try? await SecureURLSession.shared.data(for: communityRequest),
                       let communityRecipes = try? JSONDecoder().decode([Recipe].self, from: communityData) {
                        list.append(contentsOf: communityRecipes)
                    }
                }
            }
            
            await MainActor.run { 
                self.recipes = list
                self.error = nil
            }
            // Load menus as well
            if let ms = try? await app.fetchMenus(accessToken: token, userId: userId) {
                await MainActor.run {
                    self.menus = ms
                    if let cur = self.selectedMenu, let updated = ms.first(where: { $0.id == cur.id }) {
                        self.selectedMenu = updated
                    }
                }
                if self.selectedMenu != nil {
                    await reloadSelectedMenuRecipes()
                }
            }
        } catch {
            print("[PersonalRecipes] Error: \(error)")
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
                            ForEach(recipes) { recipe in
                                RecipeCard(
                                    recipe: recipe,
                                    isPersonal: false,
                                    onDelete: { toDelete = recipe; showDeleteAlert = true }
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .onTapGesture {
                                    // Navigate to detail
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
            print("[MyContributions] Load private recipes error: \(error)")
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
            print("[MyContributions] Share error: \(error)")
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
            print("[MyContributions] Remove error: \(error)")
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
            print("[MyContributions] Error: \(error)")
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
            L.tag_glutenFree.localized,
            L.tag_lactoseFree.localized,
            L.tag_lowCarb.localized,
            L.tag_highProtein.localized,
            L.tag_budget.localized,
            L.tag_spicy.localized,
            L.tag_quick.localized
        ]
    }
    private let lowCarbThreshold: Double = 25 // g Kohlenhydrate pro Portion
    private let quickThresholdMinutes: Int = 30 // Minuten für "Schnell"
    
    private var filteredRecipes: [Recipe] {
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
                if (r.nutrition.protein_g ?? 0) >= 30 { return true }
            case "lowcarb":
                if let c = r.nutrition.carbs_g, c < lowCarbThreshold { return true }
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
            print("[Language Filter] Selected languages: \(selectedLanguages)")
            print("[Language Filter] Total recipes before filter: \(base.count)")
            languageFiltered = base.filter { recipe in
                // Check if recipe matches any selected language
                for langName in selectedLanguages {
                    let matches = matchesLanguage(recipe, langName)
                    if matches {
                        print("[Language Filter] Recipe '\(recipe.title)' matches '\(langName)' - language field: \(recipe.language ?? "nil"), tags: \(recipe.tags ?? [])")
                        return true
                    }
                }
                print("[Language Filter] Recipe '\(recipe.title)' does NOT match - language field: \(recipe.language ?? "nil"), tags: \(recipe.tags ?? [])")
                return false
            }
            print("[Language Filter] Filtered recipes count: \(languageFiltered.count)")
        }
        
        // Then apply other filters
        if selectedFilters.isEmpty { return languageFiltered }
        let wanted = selectedFilters.map { norm($0) }
        return languageFiltered.filter { r in
            let tagsNorm = Set((r.tags ?? []).map { norm($0) })
            var matched = false
            for f in wanted {
                if f == "highprotein" {
                    if (r.nutrition.protein_g ?? 0) >= 30 { matched = true; break }
                    if tagsNorm.contains("highprotein") { matched = true; break }
                } else if f == "lowcarb" {
                    if let c = r.nutrition.carbs_g, c < lowCarbThreshold { matched = true; break }
                    if tagsNorm.contains("lowcarb") { matched = true; break }
                } else if f == "schnell" {
                    if let mins = parseMinutes(r.cooking_time), mins < quickThresholdMinutes { matched = true; break }
                    if tagsNorm.contains("schnell") { matched = true; break }
                } else {
                    if tagsNorm.contains(f) { matched = true; break }
                }
            }
            return matched
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
                        // Header mit Suchbar und Meine Beiträge Button
                        HStack(spacing: 8) {
                            SearchBar(query: $query, placeholder: L.placeholder_searchCommunityLong.localized)
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
                        
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeCard(recipe: recipe, isPersonal: false)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
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
                            print("[Language Selection] Tapped: \(language.name), currently selected: \(isSelected)")
                            withAnimation {
                                if isSelected {
                                    selectedLanguages.remove(language.name)
                                } else {
                                    selectedLanguages.insert(language.name)
                                }
                            }
                            print("[Language Selection] Updated selectedLanguages: \(selectedLanguages)")
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
        .refreshable { await loadCommunityRecipes() }
    }
    
    func loadCommunityRecipes() async {
        guard let token = app.accessToken else {
            await MainActor.run { 
                self.error = "Nicht angemeldet"
                self.loading = false
            }
            return
        }
        
        await MainActor.run { loading = true }
        
        do {
            // Load public recipes from Supabase
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/recipes")
            url.append(queryItems: [
                URLQueryItem(name: "is_public", value: "eq.true"),
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ])
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            let list = try JSONDecoder().decode([Recipe].self, from: data)
            
            await MainActor.run { 
                self.recipes = list
                self.error = nil
                self.loading = false
            }
        } catch {
            print("[CommunityRecipes] Error: \(error)")
            await MainActor.run { 
                // Don't clear existing recipes on error - keep showing what we have
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.error = "Keine Internetverbindung"
                    case .timedOut:
                        self.error = "Zeitüberschreitung"
                    default:
                        // Keep existing recipes, just don't show error
                        if self.recipes.isEmpty {
                            self.error = "Rezepte konnten nicht geladen werden"
                        }
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
                    print("[Language Dropdown] Toggling: \(showLanguageDropdown) -> \(!showLanguageDropdown)")
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
                                                Text(tags.prefix(2).joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundStyle(.white.opacity(0.7))
                                                    .lineLimit(1)
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
                    // Image
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
                    TabView {
                        ForEach(urls, id: \.self) { url in
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    placeholderImage
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 180)
                                        .clipped()
                                case .failure(_):
                                    placeholderImage
                                @unknown default:
                                    placeholderImage
                                }
                            }
                        }
                    }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: urls.count > 1 ? .automatic : .never))
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
                    TagChips(tags: Array(tags.prefix(3)))
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
