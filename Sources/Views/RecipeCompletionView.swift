import SwiftUI
import PhotosUI

struct RecipeCompletionView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    
    let recipe: Recipe
    let onCloseRecipe: (() -> Void)?
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var notes: String = ""
    @State private var cookingTime: String = ""
    @State private var difficulty: String = "Mittel"
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var saveType: SaveType = .none
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var successMessage: String = ""
    @State private var errorMessage: String?

    // Menus selection for private save
    @State private var menus: [Menu] = []
    @State private var selectedMenuIds: Set<String> = []
    @State private var addingMenu: Bool = false
    @State private var newMenuTitleInline: String = ""
    @State private var showMenuPicker: Bool = false
    @State private var tempSelectedMenuIds: Set<String> = []
    @State private var showMenuDialog: Bool = false
    // Auto-save when coming from a menu suggestion
    @State private var autoSaveTriggered: Bool = false
    
    enum SaveType {
        case none
        case personal
        case community
    }
    
    private var difficultyOptions: [String] {
        [L.difficulty_easy.localized, L.difficulty_medium.localized, L.difficulty_hard.localized]
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.85, blue: 0.75),
                    Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        if let uiImage = UIImage(named: "penguin-chef") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                        
                        Text(L.completion_enjoyYourMeal.localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text(recipe.title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Photo Upload Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(L.completion_photo.localized)
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                            if photoData == nil {
                                PhotosPicker(selection: Binding(
                                    get: { selectedPhoto.map { [$0] } ?? [] },
                                    set: { selectedPhoto = $0.first }
                                ), maxSelectionCount: 1, matching: .images) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(L.completion_photo.localized)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: Capsule()
                                    )
                                }
                            }
                        }
                        
                        if let data = photoData, let uiImage = UIImage(data: data) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Button {
                                    withAnimation {
                                        photoData = nil
                                        selectedPhoto = nil
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 4)
                                }
                                .padding(12)
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemGray6))
                                    .frame(height: 200)
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text(L.recipe_keine_fotos.localized)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)

/*                    // Menus selection (moved to sheet)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.recipe_in_menüs_speichern.localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(menus) { m in
                                    let isOn = selectedMenuIds.contains(m.id)
                                    Button(action: {
                                        if isOn { selectedMenuIds.remove(m.id) } else { selectedMenuIds.insert(m.id) }
                                    }) {
                                        Text(m.title)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(isOn ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                                            .foregroundColor(isOn ? .white : .black.opacity(0.7))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                                Button(action: { addingMenu.toggle() }) {
                                    HStack(spacing: 6) { Image(systemName: "plus"); Text(L.recipe_menü.localized) }
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(UIColor.systemGray6))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if addingMenu {
                            HStack(spacing: 8) {
                                TextField("Menüname", text: $newMenuTitleInline)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Color(UIColor.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Button("Erstellen") {
                                    Task { await createMenuInline() }
                                }
                                .disabled(newMenuTitleInline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }
                    .padding(20)
                    .background(.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
*/                    
                    // Save Options
                    VStack(spacing: 12) {
                        Text(L.completion_saveRecipe.localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        // Personal Save
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                saveType = .personal
                            }
                            // Open simple menu dialog; fallback to direct save if no menus
                            Task { if menus.isEmpty { await loadMenus() } }
                            showMenuDialog = true
                        } label: {
                            HStack {
                                Image(systemName: saveType == .personal ? "checkmark.circle.fill" : "lock.fill")
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L.completion_savePrivate.localized)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(L.recipe_nur_für_dich_sichtbar.localized)
                                        .font(.system(size: 12))
                                        .opacity(0.7)
                                }
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSaving)
                        
                        // Community Save
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                saveType = .community
                            }
                            Task { await saveRecipe() }
                        } label: {
                            HStack {
                                Image(systemName: saveType == .community ? "checkmark.circle.fill" : "globe")
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L.completion_shareCommunity.localized)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(L.recipe_für_alle_sichtbar.localized)
                                        .font(.system(size: 12))
                                        .opacity(0.7)
                                }
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSaving)
                        
                        // Skip Button
                        Button {
                            dismiss()
                        } label: {
                            Text(L.completion_doNotSave.localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black.opacity(0.5))
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(20)
                    .background(.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            
            // Success Overlay
            if showSuccess {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Success Icon with gradient background
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(L.completion_successfullySaved.localized)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(saveType == .community ? L.completion_sharedInCommunity.localized : L.completion_savedInYourRecipes.localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.75))
                                .multilineTextAlignment(.center)
                            
                            Text("\"\(recipe.title)\"")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                onCloseRecipe?()
                            }
                        }) {
                            Text(L.recipe_rezept_schließen.localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ), in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 22, x: 0, y: 10)
                    .frame(maxWidth: 320)
                }
                .transition(.opacity)
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let item = newValue,
                   let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { self.photoData = data }
                }
            }
        }
        .onAppear {
            if cookingTime.isEmpty, let ct = recipe.cooking_time { cookingTime = ct }
            if tags.isEmpty, let preset = recipe.tags, !preset.isEmpty { tags = preset }
            Task { await loadMenus() }
            // Preselect menu if coming from a suggestion and trigger auto-save
            if let mid = app.pendingTargetMenuId {
                selectedMenuIds.insert(mid)
                if !autoSaveTriggered {
                    autoSaveTriggered = true
                    saveType = .personal
                    Task { await saveRecipe() }
                }
            }
        }
        .alert("Fehler", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showMenuPicker) {
            MenuPickerSheet(
                menus: menus,
                tempSelection: $tempSelectedMenuIds,
                onCreateMenu: { title in Task { await createMenuInlineTitle(title) } },
                onCancel: { showMenuPicker = false },
                onConfirm: {
                    selectedMenuIds = tempSelectedMenuIds
                    showMenuPicker = false
                    Task { await saveRecipe() }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(L.completion_saveInMenu.localized, isPresented: $showMenuDialog, titleVisibility: .visible) {
            Button(L.completion_withoutMenu.localized) {
                selectedMenuIds.removeAll()
                Task { await saveRecipe() }
            }
            ForEach(menus) { m in
                Button(m.title) {
                    selectedMenuIds = [m.id]
                    Task { await saveRecipe() }
                }
            }
            Button(L.cancel.localized, role: .cancel) {}
        }
        .onAppear {
            if cookingTime.isEmpty, let ct = recipe.cooking_time { cookingTime = ct }
            if tags.isEmpty, let preset = recipe.tags, !preset.isEmpty { tags = preset }
            Task { await loadMenus() }
            // Preselect menu if coming from a suggestion
            if let mid = app.pendingTargetMenuId {
                selectedMenuIds.insert(mid)
            }
        }
    }
    
    private func loadMenus() async {
        guard let userId = KeychainManager.get(key: "user_id"), let token = app.accessToken else { return }
        if let ms = try? await app.fetchMenus(accessToken: token, userId: userId) {
            await MainActor.run { self.menus = ms }
        }
    }
    
    private func createMenuInline() async {
        await createMenuInlineTitle(newMenuTitleInline)
    }
    
    private func createMenuInlineTitle(_ title: String) async {
        guard let userId = KeychainManager.get(key: "user_id"), let token = app.accessToken else { return }
        do {
            let m = try await app.createMenu(title: title, accessToken: token, userId: userId)
            await MainActor.run {
                self.menus.insert(m, at: 0)
                self.tempSelectedMenuIds.insert(m.id)
                self.selectedMenuIds.insert(m.id)
                self.newMenuTitleInline = ""
                self.addingMenu = false
            }
        } catch {}
    }
    
    private func saveRecipe() async {
        guard saveType != .none else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        // Get user credentials
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = app.accessToken else {
            Logger.error("Recipe save aborted - no user credentials", category: .data)
            return
        }
        
        do {
            // Prepare recipe data
            let isPublic = saveType == .community
            
            // Upload photo to Supabase storage if available
            var imageUrl: String? = nil
            if let data = photoData {
                imageUrl = try? await uploadPhoto(data: data, userId: userId, token: token)
            }
            
            // Build request body with all fields
            let nutritionDict: [String: Any] = [
                "calories": recipe.nutrition?.calories ?? 0,
                "protein_g": recipe.nutrition?.protein_g ?? 0,
                "carbs_g": recipe.nutrition?.carbs_g ?? 0,
                "fat_g": recipe.nutrition?.fat_g ?? 0
            ]
            
            var body: [String: Any] = [
                "user_id": userId,
                "title": recipe.title,
                "ingredients": recipe.ingredients ?? [],
                "instructions": recipe.instructions ?? [],
                "nutrition": nutritionDict,
                "is_public": false  // ALWAYS private initially
            ]
            
            // Add optional fields
            if let imageUrl = imageUrl {
                body["image_url"] = imageUrl
            }
            if !cookingTime.isEmpty {
                body["cooking_time"] = cookingTime
            } else if let ct = recipe.cooking_time, !ct.isEmpty {
                body["cooking_time"] = ct
            }
            body["difficulty"] = difficulty
            if !tags.isEmpty {
                body["tags"] = tags
            } else if let preset = recipe.tags, !preset.isEmpty {
                body["tags"] = preset
            }
            
            // Save to Supabase
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/recipes")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("return=representation", forHTTPHeaderField: "Prefer")
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (respData, response) = try await SecureURLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.error("Recipe save failed with status \(httpResponse.statusCode)", category: .network)
                if httpResponse.statusCode == 401 {
                    await MainActor.run {
                        self.errorMessage = "Sitzung abgelaufen. Bitte melde dich neu an."
                    }
                }
                throw URLError(.badServerResponse)
            }
            
            // Parse created recipe id
            var createdId: String? = nil
            if let list = try? JSONDecoder().decode([Recipe].self, from: respData), let first = list.first {
                createdId = first.id
            }
            
            // If community upload, publish via backend (moderation + rate limit)
            if isPublic, let recipeId = createdId {
                try await publishToCommunity(recipeId: recipeId, imageUrls: imageUrl.map { [$0] } ?? [], token: token)
            }
            // Determine target menus: selected in UI or fallback to pendingTargetMenuId
            var targetMenuIds = selectedMenuIds
            if targetMenuIds.isEmpty, let fallback = app.pendingTargetMenuId {
                targetMenuIds.insert(fallback)
            }
            var broadcastMenuId: String? = nil
            if !isPublic, let rid = createdId, !targetMenuIds.isEmpty {
                for mid in targetMenuIds {
                    try? await app.addRecipeToMenu(menuId: mid, recipeId: rid, accessToken: token)
                    broadcastMenuId = mid
                }
            }
            // Broadcast newly created recipe for immediate UI update
            if let list = try? JSONDecoder().decode([Recipe].self, from: respData), let first = list.first {
                await MainActor.run {
                    app.lastCreatedRecipe = first
                    app.lastCreatedRecipeMenuId = broadcastMenuId
                }
            }
            // If we came from a menu placeholder suggestion, remove it now
            if let mid = app.pendingTargetMenuId, let name = app.pendingSuggestionNameToRemove {
                app.removeMenuSuggestion(named: name, from: mid)
                await MainActor.run {
                    app.pendingTargetMenuId = nil
                    app.pendingSuggestionNameToRemove = nil
                }
            }
            
            await MainActor.run {
                showSuccess = true
                let n = selectedMenuIds.count
                successMessage = isPublic ? "Rezept veröffentlicht" : (n > 0 ? "In \(n) Menü(s) gespeichert" : "Gespeichert")
                
                // Track positive action for App Store review
                AppStoreReviewManager.recordPositiveAction()
                // Check if we should request a review
                AppStoreReviewManager.requestReviewIfAppropriate()
            }
            
        } catch {
            Logger.error("Error saving recipe", error: error, category: .data)
            await MainActor.run {
                showSuccess = false
                isSaving = false
                self.errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            }
        }
    }
    
    private func publishToCommunity(recipeId: String, imageUrls: [String], token: String) async throws {
        // Call backend /community/publish endpoint (with moderation + rate limit)
        let publishUrl = Config.backendBaseURL.appending(path: "/community/publish")
        
        var request = URLRequest(url: publishUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "recipe_id": recipeId,
            "image_urls": imageUrls
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (respData, response) = try await SecureURLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 429 {
            // Rate limit exceeded
            if let errorDict = try? JSONSerialization.jsonObject(with: respData) as? [String: Any],
               let detail = errorDict["detail"] as? String {
                throw NSError(domain: "rate_limit", code: 429, userInfo: [NSLocalizedDescriptionKey: detail])
            }
            throw NSError(domain: "rate_limit", code: 429, userInfo: [NSLocalizedDescriptionKey: "Upload-Limit erreicht"])
        }
        
        if httpResponse.statusCode == 403 {
            // Moderation failed
            if let errorDict = try? JSONSerialization.jsonObject(with: respData) as? [String: Any],
               let detail = errorDict["detail"] as? String {
                throw NSError(domain: "moderation", code: 403, userInfo: [NSLocalizedDescriptionKey: detail])
            }
            throw NSError(domain: "moderation", code: 403, userInfo: [NSLocalizedDescriptionKey: "Moderation fehlgeschlagen"])
        }
        
        // Extract error message from response if available
        let errorMessage: String? = {
            if let errorDict = try? JSONSerialization.jsonObject(with: respData) as? [String: Any],
               let detail = errorDict["detail"] as? String {
                return detail
            } else if let responseString = String(data: respData, encoding: .utf8), !responseString.isEmpty {
                return responseString
            }
            return nil
        }()
        
        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.error("Community publish failed with status \(httpResponse.statusCode): \(errorMessage ?? "Unknown")", category: .network)
            
            // Provide more specific error messages
            if httpResponse.statusCode >= 500 {
                throw NSError(domain: "server_error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Server-Fehler. Bitte versuche es später erneut."])
            } else {
                throw NSError(domain: "client_error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Upload fehlgeschlagen. Bitte versuche es erneut."])
            }
        }
    }
    
    private func uploadPhoto(data: Data, userId: String, token: String) async throws -> String {
        let filename = "\(userId)_\(UUID().uuidString).jpg"
        
        // Optimize image (resize + compress to max 2MB)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        let optimizedData = try ImageOptimizer.optimizeImage(image)
        
        // Upload to Supabase Storage
        let uploadUrlString = "\(Config.supabaseURL.absoluteString)/storage/v1/object/recipe-photo/\(filename)"
        guard let uploadUrl = URL(string: uploadUrlString) else {
            throw URLError(.badURL)
        }
        
        Logger.debug("Uploading photo to storage", category: .network)
        
        var uploadRequest = URLRequest(url: uploadUrl)
        uploadRequest.httpMethod = "POST"
        uploadRequest.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        uploadRequest.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        uploadRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        uploadRequest.httpBody = optimizedData
        
        let (responseData, uploadResponse) = try await SecureURLSession.shared.data(for: uploadRequest)
        
        guard let httpResponse = uploadResponse as? HTTPURLResponse else {
            Logger.error("Photo upload failed - no HTTP response", category: .network)
            throw URLError(.badServerResponse)
        }
        
        Logger.debug("Photo upload response status: \(httpResponse.statusCode)", category: .network)
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let responseString = String(data: responseData, encoding: .utf8) {
                Logger.error("Photo upload failed with status \(httpResponse.statusCode): \(responseString)", category: .network)
            }
            throw URLError(.badServerResponse)
        }
        
        // Return public URL
        let publicUrl = "\(Config.supabaseURL.absoluteString)/storage/v1/object/public/recipe-photo/\(filename)"
        Logger.info("Photo uploaded successfully", category: .network)
        return publicUrl
    }
}

// MARK: - FlowLayout for Tags
private struct FlowLayout<T: Hashable, V: View>: View {
    let items: [T]
    let content: (T) -> V
    @State private var totalHeight: CGFloat = .zero
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                generateContent(in: geo)
            }
            .frame(height: totalHeight)
        }
    }
    
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if index == items.count - 1 { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == items.count - 1 { height = 0 }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async { binding.wrappedValue = geometry.size.height }
            return .clear
        }
    }
}

// MARK: - Menu Picker Sheet
private struct MenuPickerSheet: View {
    let menus: [Menu]
    @Binding var tempSelection: Set<String>
    var onCreateMenu: (String) -> Void
    var onCancel: () -> Void
    var onConfirm: () -> Void
    @State private var newTitle: String = ""
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.96, green: 0.78, blue: 0.68),
                Color(red: 0.95, green: 0.74, blue: 0.64),
                Color(red: 0.93, green: 0.66, blue: 0.55)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack {
                    Text(L.recipe_menü_auswählen.localized)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                // Chips row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { tempSelection.removeAll() }) {
                            Text(L.recipe_alle_ohne_menü.localized)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(tempSelection.isEmpty ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                                .foregroundColor(tempSelection.isEmpty ? .white : .black.opacity(0.7))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        ForEach(menus) { m in
                            let isOn = tempSelection.contains(m.id)
                            Button(action: { if isOn { tempSelection.remove(m.id) } else { tempSelection.insert(m.id) } }) {
                                Text(m.title)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(isOn ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color(UIColor.systemGray6))
                                    .foregroundColor(isOn ? .white : .black.opacity(0.7))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    TextField(L.recipe_neues_menü.localized, text: $newTitle)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button(L.save.localized) {
                        if !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onCreateMenu(newTitle)
                            newTitle = ""
                        }
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text(L.cancel.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial.opacity(0.25)))
                    }
                    .buttonStyle(.plain)
                    Button(action: onConfirm) {
                        Text(L.save.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    RecipeCompletionView(
        recipe: Recipe(
            id: "1",
            user_id: "1",
            title: "Spaghetti Carbonara",
            ingredients: ["Pasta", "Eier", "Speck"],
            instructions: ["Kochen", "Mischen"],
            nutrition: Nutrition(calories: 500, protein_g: 20, carbs_g: 60, fat_g: 15),
            created_at: nil,
            is_favorite: false
        ),
        onCloseRecipe: {}
    )
    .environmentObject(AppState())
}
