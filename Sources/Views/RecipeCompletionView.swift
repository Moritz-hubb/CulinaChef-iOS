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
    @State private var cookingTime: String = ""
    @State private var tags: [String] = []
    @State private var saveType: SaveType = .none
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var successMessage: String = ""
    @State private var errorMessage: String?

    @State private var menus: [Menu] = []
    @State private var selectedMenuIds: Set<String> = []
    @State private var showMenuPicker: Bool = false
    @State private var tempSelectedMenuIds: Set<String> = []
    @State private var showMenuDialog: Bool = false
    @State private var autoSaveTriggered: Bool = false
    @State private var appeared = false

    enum SaveType {
        case none
        case personal
    }

    private var appGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.78, blue: 0.68),
                Color(red: 0.95, green: 0.74, blue: 0.64),
                Color(red: 0.93, green: 0.66, blue: 0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            appGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    photoSection
                    saveSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }

            if isSaving && !showSuccess {
                savingOverlay
            }

            if showSuccess {
                successOverlay
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
            if let mid = app.pendingTargetMenuId {
                selectedMenuIds.insert(mid)
                if !autoSaveTriggered {
                    autoSaveTriggered = true
                    saveType = .personal
                    Task { await saveRecipe() }
                }
            }
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
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
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.cancel.localized)

                Spacer()
            }

            if let uiImage = UIImage(named: "penguin-chef") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 108, height: 108)
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            } else {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(accentGradient)
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            }

            Text(L.completion_enjoyYourMeal.localized)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(recipe.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.bottom, 4)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.completion_photo.localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(L.community_bild_ist_optional_max.localized)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
            }

            if let data = photoData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 210)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            photoData = nil
                            selectedPhoto = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                }
            } else {
                PhotosPicker(
                    selection: Binding(
                        get: { selectedPhoto.map { [$0] } ?? [] },
                        set: { selectedPhoto = $0.first }
                    ),
                    maxSelectionCount: 1,
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial.opacity(0.45))
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )

                        Text(L.recipe_keine_fotos.localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))

                        Text(L.completion_photo.localized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(accentGradient, in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.28))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [7, 5])
                            )
                            .foregroundStyle(Color.white.opacity(0.28))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(glassCardBackground)
    }

    private var saveSection: some View {
        VStack(spacing: 14) {
            Text(L.completion_saveRecipe.localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation(.spring(response: 0.3)) {
                    saveType = .personal
                }
                Task { if menus.isEmpty { await loadMenus() } }
                showMenuDialog = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.18), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.completion_savePrivate.localized)
                            .font(.system(size: 16, weight: .bold))
                        Text(L.recipe_nur_für_dich_sichtbar.localized)
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.85)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(accentGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.35), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(isSaving)

            Button {
                dismiss()
            } label: {
                Text(L.completion_doNotSave.localized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.28))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .padding(18)
        .background(glassCardBackground)
    }

    private var glassCardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                Text(L.completion_saveRecipe.localized + "…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .transition(.opacity)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(accentGradient)
                        .frame(width: 78, height: 78)
                        .shadow(color: Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.4), radius: 12, y: 6)
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text(L.completion_successfullySaved.localized)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text(L.completion_savedInYourRecipes.localized)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    Text("\"\(recipe.title)\"")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }

                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onCloseRecipe?()
                    }
                } label: {
                    Text(L.recipe_rezept_schließen.localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
            .padding(.horizontal, 28)
            .frame(maxWidth: 360)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    // MARK: - Data

    private func loadMenus() async {
        guard let userId = KeychainManager.get(key: "user_id"), let token = app.accessToken else { return }
        if let ms = try? await app.fetchMenus(accessToken: token, userId: userId) {
            await MainActor.run { self.menus = ms }
        }
    }

    private func createMenuInlineTitle(_ title: String) async {
        guard let userId = KeychainManager.get(key: "user_id"), let token = app.accessToken else { return }
        do {
            let m = try await app.createMenu(title: title, accessToken: token, userId: userId)
            await MainActor.run {
                self.menus.insert(m, at: 0)
                self.tempSelectedMenuIds.insert(m.id)
                self.selectedMenuIds.insert(m.id)
            }
        } catch {}
    }

    private func saveRecipe() async {
        guard saveType != .none else { return }

        isSaving = true
        defer { isSaving = false }

        guard let userId = KeychainManager.get(key: "user_id"),
              let token = app.accessToken else {
            Logger.error("Recipe save aborted - no user credentials", category: .data)
            return
        }

        do {
            var imageUrl: String? = nil
            if let data = photoData {
                imageUrl = try? await uploadPhoto(data: data, userId: userId, token: token)
            }

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
                "is_public": false
            ]

            if let imageUrl = imageUrl {
                body["image_url"] = imageUrl
            }
            if !cookingTime.isEmpty {
                body["cooking_time"] = cookingTime
            } else if let ct = recipe.cooking_time, !ct.isEmpty {
                body["cooking_time"] = ct
            }
            if !tags.isEmpty {
                body["tags"] = tags
            } else if let preset = recipe.tags, !preset.isEmpty {
                body["tags"] = preset
            }

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

            var createdId: String? = nil
            if let list = try? JSONDecoder().decode([Recipe].self, from: respData), let first = list.first {
                createdId = first.id
            }

            var targetMenuIds = selectedMenuIds
            if targetMenuIds.isEmpty, let fallback = app.pendingTargetMenuId {
                targetMenuIds.insert(fallback)
            }
            var broadcastMenuId: String? = nil
            if let rid = createdId, !targetMenuIds.isEmpty {
                for mid in targetMenuIds {
                    try? await app.addRecipeToMenu(menuId: mid, recipeId: rid, accessToken: token)
                    broadcastMenuId = mid
                }
            }
            if let list = try? JSONDecoder().decode([Recipe].self, from: respData), let first = list.first {
                await MainActor.run {
                    app.lastCreatedRecipe = first
                    app.lastCreatedRecipeMenuId = broadcastMenuId
                }
            }
            if let mid = app.pendingTargetMenuId, let name = app.pendingSuggestionNameToRemove {
                app.removeMenuSuggestion(named: name, from: mid)
                await MainActor.run {
                    app.pendingTargetMenuId = nil
                    app.pendingSuggestionNameToRemove = nil
                }
            }

            await MainActor.run {
                withAnimation(.spring(response: 0.35)) {
                    showSuccess = true
                }
                let n = selectedMenuIds.count
                successMessage = n > 0 ? "In \(n) Menü(s) gespeichert" : "Gespeichert"
                AppStoreReviewManager.recordPositiveAction()
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

    private func uploadPhoto(data: Data, userId: String, token: String) async throws -> String {
        let filename = "\(userId)_\(UUID().uuidString).jpg"

        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        let optimizedData = try ImageOptimizer.optimizeImage(image)

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

        let publicUrl = "\(Config.supabaseURL.absoluteString)/storage/v1/object/public/recipe-photo/\(filename)"
        Logger.info("Photo uploaded successfully", category: .network)
        return publicUrl
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

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { tempSelection.removeAll() }) {
                            Text(L.recipe_alle_ohne_menü.localized)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(tempSelection.isEmpty ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.white.opacity(0.22))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        ForEach(menus) { m in
                            let isOn = tempSelection.contains(m.id)
                            Button(action: { if isOn { tempSelection.remove(m.id) } else { tempSelection.insert(m.id) } }) {
                                Text(m.title)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(isOn ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.white.opacity(0.22))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField(L.recipe_neues_menü.localized, text: $newTitle)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button(L.save.localized) {
                        if !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onCreateMenu(newTitle)
                            newTitle = ""
                        }
                    }
                    .foregroundStyle(.white)
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
            created_at: nil
        ),
        onCloseRecipe: {}
    )
    .environmentObject(AppState())
}
