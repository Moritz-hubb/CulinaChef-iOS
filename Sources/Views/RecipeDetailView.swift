import SwiftUI
import AVFoundation
import Combine
import PhotosUI
import UIKit

struct RecipeDetailView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    @State private var error: String?
    @State private var currentPage = 0
    @State private var showCompletion = false
    @State private var showAISheet = false
    @State private var timersExpanded = true
    @StateObject private var timerCenter = TimerCenter()
    @FocusState private var isFocused: Bool
    
    // Photo upload states
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isUploadingPhoto = false
    @State private var uploadError: String?
    @State private var uploadedImageUrl: String? = nil
    @State private var servings: Int = 4
    
    // Shopping list states
    @State private var showServingSelector = false
    @State private var shoppingServings: Int = 4
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    // Paywall state
    @State private var showPaywallSheet = false

    private let gradientColors = [
        Color(red: 0.96, green: 0.78, blue: 0.68),
        Color(red: 0.95, green: 0.74, blue: 0.64),
        Color(red: 0.93, green: 0.66, blue: 0.55)
    ]
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var tabContent: some View {
        TabView(selection: $currentPage) {
            overviewPage.tag(0)
            
            if recipe.instructions.isEmpty {
                emptyInstructionsView
            } else {
                instructionPages
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
    
    @ViewBuilder
    private var emptyInstructionsView: some View {
        VStack(spacing: 12) {
            Text(L.recipe_keine_schritte_gefunden.localized)
                .foregroundStyle(.white)
        }
        .padding(24)
        .tag(1)
        
        if recipe.is_public ?? false {
            ratingPage.tag(2)
        }
    }
    
    @ViewBuilder
    private var instructionPages: some View {
        ForEach(recipe.instructions.indices, id: \.self) { idx in
            stepPage(index: idx + 1, instruction: recipe.instructions[idx])
                .tag(idx + 1)
        }
        if recipe.is_public ?? false {
            ratingPage.tag(recipe.instructions.count + 1)
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            tabContent
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .accessibilityLabel("Schließen")
                .accessibilityHint("Schließt die Rezeptansicht")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 10) {
                    // Like Button
                    LikeButtonToolbarClean(recipeId: recipe.id, likedManager: app.likedRecipesManager)
                    
                    // Share Button
                    Button(action: { shareRecipe() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .accessibilityLabel("Rezept teilen")
                    .accessibilityHint("Teilt das Rezept über das Teilen-Menü")
                    
                    // AI Button
                    Button(action: { showAISheet = true }) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .accessibilityLabel("KI-Assistent")
                    .accessibilityHint("Öffnet den KI-Assistenten für dieses Rezept")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !timerCenter.timers.isEmpty {
                VStack(spacing: 8) {
                    if timersExpanded {
                        ForEach(timerCenter.timers) { timer in
                            FloatingTimerView(center: timerCenter, timer: timer)
                        }
                    }
                    
                    // Collapse/Expand button
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            timersExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: timersExpanded ? "chevron.down" : "chevron.up")
                                .font(.caption.bold())
                            Text(timersExpanded ? L.timerHide.localized : "\(timerCenter.timers.count) \(L.timerActive.localized)")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.3))
                        )
                    }
                    .accessibilityLabel(timersExpanded ? "Timer ausblenden" : "\(timerCenter.timers.count) aktive Timer")
                    .accessibilityHint(timersExpanded ? "Blendet Timer aus" : "Zeigt Timer an")
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
.sheet(isPresented: $showAISheet) {
            RecipeAISheetForSavedRecipe(recipe: recipe, currentStepIndex: max(currentPage - 1, -1))
                .environmentObject(app)
                .presentationDetents([.fraction(0.6), .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear { 
            uploadedImageUrl = recipe.image_url
        }
        .onDisappear {
            // Stop all timers when recipe view is closed
            timerCenter.stopAllTimers()
        }
        .sheet(isPresented: $showServingSelector) {
            ServingSelectorSheet(
                servings: $shoppingServings,
                onConfirm: { addIngredientsToShoppingList(servings: shoppingServings) }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallView()
                .environmentObject(app)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let item = newValue,
                   let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { 
                        self.photoData = data
                        Task { await uploadNewPhoto() }
                    }
                }
            }
        }
        .alert(L.errorUploadFailed.localized, isPresented: Binding(
            get: { uploadError != nil },
            set: { if !$0 { uploadError = nil } }
        )) {
            Button(L.ok.localized) { uploadError = nil }
        } message: {
            Text(uploadError ?? "")
        }
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
    
    private var overviewPage: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Image with Title
                headerImageSection
                
                // Ingredients Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(L.recipe_zutaten.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        // Portionen control
                        HStack(spacing: 8) {
                            Button(action: { if servings > 1 { servings -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                            VStack(spacing: 0) {
                                Text(String(servings))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(L.label_servings.localized)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .frame(minWidth: 70)
                            Button(action: { servings += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                        }
                    }
                    
                    ForEach(recipe.ingredients, id: \.self) { ing in
                        HStack {
                            Text(parseIngredientName(ing))
                                .font(.body)
                                .foregroundStyle(.white)
                            Spacer()
                            if let qty = parseIngredientQuantity(ing) {
                                Text(scaleQuantity(qty, servings: servings))
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(.vertical, 6)
                        .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1), alignment: .bottom)
                    }
                    
                    // Add to Shopping List button
                    Button(action: { showServingSelector = true }) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text(L.recipe_zutaten_zur_einkaufsliste_hinzufüge.localized)
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .padding(.top, 8)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Nutrition Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L.recipe_nährwerte.localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 20) {
                        NutritionItem(label: L.label_calories.localized, value: "\(recipe.nutrition.calories ?? 0)")
                        NutritionItem(label: L.label_protein.localized, value: String(format: "%.1fg", recipe.nutrition.protein_g ?? 0))
                        NutritionItem(label: L.label_carbs.localized, value: String(format: "%.1fg", recipe.nutrition.carbs_g ?? 0))
                        NutritionItem(label: L.label_fat.localized, value: String(format: "%.1fg", recipe.nutrition.fat_g ?? 0))
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Additional Info
                if let cookTime = recipe.cooking_time, let difficulty = recipe.difficulty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L.label_cookingTime.localized)
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text(cookTime)
                                .foregroundStyle(.white)
                        }
                        HStack {
                            Text(L.label_difficulty.localized)
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text(difficulty)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                if let tags = recipe.tags, !tags.isEmpty {
                    // Filter out invisible tags (those starting with _filter:)
                    let visibleTags = tags.filter { !$0.hasPrefix("_filter:") }
                    if !visibleTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L.label_tags.localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                            RecipeDetailFlowLayout(spacing: 8) {
                                ForEach(visibleTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2), in: Capsule())
                                }
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var headerImageSection: some View {
        ZStack(alignment: .bottom) {
            // Background Image or Placeholder
            if let imageUrl = uploadedImageUrl ?? recipe.image_url {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width - 32, height: 250)
                            .clipped()
                    case .failure(_), .empty:
                        placeholderHeaderImageWithButton
                    @unknown default:
                        placeholderHeaderImageWithButton
                    }
                }
                .frame(height: 250)
            } else {
                placeholderHeaderImageWithButton
            }
            
            // Gradient Overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 250)
            .allowsHitTesting(false)
            
            // Recipe Title
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .allowsHitTesting(false)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var placeholderHeaderImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3),
                    Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }
    
    private var placeholderHeaderImageWithButton: some View {
        ZStack(alignment: .topTrailing) {
            placeholderHeaderImage
            
            // Plus button to add photo
            if !isUploadingPhoto && photoData == nil {
                PhotosPicker(selection: Binding(
                    get: { selectedPhoto.map { [$0] } ?? [] },
                    set: { selectedPhoto = $0.first }
                ), maxSelectionCount: 1, matching: .images) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(Color(red: 0.95, green: 0.5, blue: 0.3))
                                .frame(width: 36, height: 36)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(16)
            } else if isUploadingPhoto {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .padding(16)
            }
        }
    }
    
    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L.label_photo.localized)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if !isUploadingPhoto && photoData == nil && uploadedImageUrl == nil {
                    PhotosPicker(selection: Binding(
                        get: { selectedPhoto.map { [$0] } ?? [] },
                        set: { selectedPhoto = $0.first }
                    ), maxSelectionCount: 1, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.caption.bold())
                            Text(L.label_photo.localized)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ), in: Capsule()
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                } else if isUploadingPhoto {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
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
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3)
                    }
                    .padding(10)
                }
            } else if let imageUrl = uploadedImageUrl {
                // Show existing or uploaded recipe photo with delete button
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure(_):
                            emptyPhotoPlaceholder
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        @unknown default:
                            emptyPhotoPlaceholder
                        }
                    }
                    
                    // Delete button for uploaded photo
                    Button {
                        Task { await deleteUploadedPhoto() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3)
                    }
                    .padding(10)
                }
            } else {
                emptyPhotoPlaceholder
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var emptyPhotoPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.5))
            Text(L.recipe_keine_fotos_ce07.localized)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func stepPage(index: Int, instruction: String) -> some View {
        let isLastStep = index == recipe.instructions.count
        return ScrollView {
            let split = splitInstruction(instruction)
            let bodyText = split.body
            let labelText = split.label
            VStack(alignment: .leading, spacing: 16) {
                Text(bodyText)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Timer detection
                if let cookMins = parseCookMinutes(from: bodyText) {
                    let label = labelText ?? timerLabel(for: bodyText, index: index)
                    SharedTimerControl(minutes: cookMins, label: label, center: timerCenter)
                    // Nur Hinweis zeigen, wenn Timer >= 5 Min UND es weitere Schritte gibt
                    if cookMins >= 5 && !isLastStep {
                        Text(L.recipe_in_der_zwischenzeit_führe.localized)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                if isLastStep {
                    if (recipe.is_public ?? false) {
                        Button(action: { 
                            withAnimation(.spring(response: 0.3)) {
                                currentPage = recipe.instructions.count + 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "star.fill")
                                Text(L.button_rateRecipe.localized)
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    } else {
                        Button(action: { 
                            // For saved recipes, just dismiss the view
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(L.button_finishRecipe.localized)
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                } else {
                    // Next button for non-last steps
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            currentPage = index + 1
                        }
                    }) {
                        HStack {
                            Text(L.next.localized)
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(L.label_step.localized) \(index)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }

    private func uploadNewPhoto() async {
        guard let data = photoData,
              let userId = KeychainManager.get(key: "user_id"),
              let token = app.accessToken else { return }
        
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        
        do {
            let uploadedUrl = try await uploadPhoto(data: data, userId: userId, token: token)
            try await updateRecipePhoto(recipeId: recipe.id, imageUrl: uploadedUrl, token: token)
            
            // Update local state to show the uploaded image immediately
            await MainActor.run {
                uploadedImageUrl = uploadedUrl
                photoData = nil
                selectedPhoto = nil
            }
            
        } catch {
            Logger.error("Photo upload failed in recipe detail", error: error, category: .network)
            await MainActor.run {
                uploadError = "\(L.errorUploadFailed.localized) \(L.errorGenericUserFriendly.localized)"
            }
        }
    }
    
    private func uploadPhoto(data: Data, userId: String, token: String) async throws -> String {
        let filename = "\(userId)_\(UUID().uuidString).jpg"
        
        guard let image = UIImage(data: data),
              let compressedData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let uploadUrlString = "\(Config.supabaseURL.absoluteString)/storage/v1/object/recipe-photo/\(filename)"
        guard let uploadUrl = URL(string: uploadUrlString) else {
            throw URLError(.badURL)
        }
        
        var uploadRequest = URLRequest(url: uploadUrl)
        uploadRequest.httpMethod = "POST"
        uploadRequest.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        uploadRequest.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        uploadRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        uploadRequest.httpBody = compressedData
        
        let (_, uploadResponse) = try await SecureURLSession.shared.data(for: uploadRequest)
        
        guard let httpResponse = uploadResponse as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let publicUrl = "\(Config.supabaseURL.absoluteString)/storage/v1/object/public/recipe-photo/\(filename)"
        return publicUrl
    }
    
    private func updateRecipePhoto(recipeId: String, imageUrl: String, token: String) async throws {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(recipeId)")])
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["image_url": imageUrl]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await SecureURLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    private func deleteUploadedPhoto() async {
        guard let imageUrl = uploadedImageUrl,
              let token = app.accessToken else { return }
        
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        
        do {
            // Extract filename from URL
            // URL format: https://.../storage/v1/object/public/recipe-photo/filename.jpg
            let components = imageUrl.split(separator: "/")
            guard let filename = components.last else {
                throw URLError(.badURL)
            }
            
            // Delete from Supabase Storage
            let deleteUrlString = "\(Config.supabaseURL.absoluteString)/storage/v1/object/recipe-photo/\(filename)"
            guard let deleteUrl = URL(string: deleteUrlString) else {
                throw URLError(.badURL)
            }
            
            var deleteRequest = URLRequest(url: deleteUrl)
            deleteRequest.httpMethod = "DELETE"
            deleteRequest.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            deleteRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (_, deleteResponse) = try await SecureURLSession.shared.data(for: deleteRequest)
            
            if let httpResponse = deleteResponse as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                Logger.error("Failed to delete photo from storage (status: \(httpResponse.statusCode))", category: .network)
                // Continue anyway to clear the database reference
            }
            
            // Clear image_url from database
            try await updateRecipePhoto(recipeId: recipe.id, imageUrl: "", token: token)
            
            // Update local state
            await MainActor.run {
                uploadedImageUrl = nil
            }
            
        } catch {
            Logger.error("Photo deletion failed in recipe detail", error: error, category: .network)
            await MainActor.run {
                uploadError = L.error_deletePhotoFailed.localized
            }
        }
    }
    
    // Extract embedded label ⟦label:...⟧ and cleaned body
    private func splitInstruction(_ raw: String) -> (label: String?, body: String) {
        let s = raw
        if let re = try? NSRegularExpression(pattern: #"^\s*⟦label:(.*?)⟧\s*(.*)$"#, options: [.dotMatchesLineSeparators]) {
            let ns = s as NSString
            let range = NSRange(location: 0, length: ns.length)
            if let m = re.firstMatch(in: s, options: [], range: range) {
                let label = (m.range(at: 1).location != NSNotFound) ? ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines) : nil
                let body = (m.range(at: 2).location != NSNotFound) ? ns.substring(with: m.range(at: 2)) : raw
                return (label, body)
            }
        }
        return (nil, raw)
    }

    // Derive a human-friendly timer label from the instruction text
    private func timerLabel(for instruction: String, index: Int) -> String {
        let s = instruction.lowercased()
        func has(_ subs: [String]) -> Bool { subs.contains { s.contains($0) } }
        if has(["ruhen lassen", "ruhen", "ruhephase"]) { return "\(L.timer_rest.localized) – \(L.label_step.localized) \(index)" }
        if has(["gehen lassen"]) || (has(["gehen"]) && has(["teig", "hefe", "hefeteig"])) { return "\(L.timer_proof.localized) – \(L.label_step.localized) \(index)" }
        if has(["marinier"]) { return "\(L.timer_marinate.localized) – \(L.label_step.localized) \(index)" }
        if has(["ofen", "back"]) { return "\(L.timer_bake.localized) – \(L.label_step.localized) \(index)" }
        if has(["köchel", "simmer"]) { return "\(L.timer_simmer.localized) – \(L.label_step.localized) \(index)" }
        if has(["brat", "anbrat"]) { return "\(L.timer_fry.localized) – \(L.label_step.localized) \(index)" }
        if has(["ziehen lassen", "ziehen"]) { return "\(L.timer_steep.localized) – \(L.label_step.localized) \(index)" }
        if has(["kühl", "kühlschrank", "abkühlen"]) { return "\(L.timer_cool.localized) – \(L.label_step.localized) \(index)" }
        // Fallback: take first 3-4 words from instruction
        let words = instruction
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: " ")
            .prefix(4)
        if words.isEmpty { return "\(L.label_step.localized) \(index)" }
        let phrase = words.joined(separator: " ")
        // Capitalize first letter
        let base = phrase.prefix(1).uppercased() + phrase.dropFirst()
        return base + " – \(L.label_step.localized) \(index)"
    }

    // Parse lower-bound minutes from instruction text; support minutes and hours (e.g., "30 Minuten", "1 Stunde 20 Minuten", "4 Stunden").
    private func parseCookMinutes(from text: String) -> Int? {
        let s = text.lowercased()
        let full = NSRange(location: 0, length: s.utf16.count)
        
        // Hours + optional minutes
        if let re = try? NSRegularExpression(pattern: #"(\d+(?:[\.,]\d+)?)\s*(?:h|std\.?|stunde|stunden)(?:\s+(\d+)\s*(?:min|minute|minuten))?"#, options: []) {
            if let m = re.firstMatch(in: s, options: [], range: full) {
                if let r1 = Range(m.range(at: 1), in: s) {
                    let hoursStr = String(s[r1]).replacingOccurrences(of: ",", with: ".")
                    let hours = Double(hoursStr) ?? 0
                    var minutes = Int(hours * 60)
                    if m.numberOfRanges >= 3, m.range(at: 2).location != NSNotFound, let r2 = Range(m.range(at: 2), in: s) {
                        minutes += Int(s[r2]) ?? 0
                    }
                    if minutes > 0 { return minutes }
                }
            }
        }
        
        // Hour ranges (use lower bound)
        let hrPatterns = [
            #"(\d+(?:[\.,]\d+)?)\s*[–-]\s*(\d+(?:[\.,]\d+)?)\s*(?:h|std\.?|stunde|stunden)"#,
            #"(\d+(?:[\.,]\d+)?)\s*(?:bis)\s*(\d+(?:[\.,]\d+)?)\s*(?:h|std\.?|stunde|stunden)"#
        ]
        for p in hrPatterns {
            if let re = try? NSRegularExpression(pattern: p, options: []) {
                if let m = re.firstMatch(in: s, options: [], range: full), let r1 = Range(m.range(at: 1), in: s) {
                    let hoursStr = String(s[r1]).replacingOccurrences(of: ",", with: ".")
                    let hours = Double(hoursStr) ?? 0
                    let minutes = Int(hours * 60)
                    if minutes > 0 { return minutes }
                }
            }
        }
        
        // Single hours
        if let re = try? NSRegularExpression(pattern: #"(\d+(?:[\.,]\d+)?)\s*(?:h|std\.?|stunde|stunden)"#, options: []) {
            if let m = re.firstMatch(in: s, options: [], range: full), let r1 = Range(m.range(at: 1), in: s) {
                let hoursStr = String(s[r1]).replacingOccurrences(of: ",", with: ".")
                let hours = Double(hoursStr) ?? 0
                let minutes = Int(hours * 60)
                if minutes > 0 { return minutes }
            }
        }
        
        // Minute ranges
        let minPatterns = [
            #"(\d+)\s*[–-]\s*(\d+)\s*(?:min|minute|minuten)"#,
            #"(\d+)\s*(?:bis)\s*(\d+)\s*(?:min|minute|minuten)"#
        ]
        for p in minPatterns {
            if let re = try? NSRegularExpression(pattern: p, options: []) {
                if let m = re.firstMatch(in: s, options: [], range: full), let r1 = Range(m.range(at: 1), in: s) {
                    return Int(s[r1])
                }
            }
        }
        
        // Single minutes
        if let re = try? NSRegularExpression(pattern: #"(\d+)\s*(?:min|minute|minuten)"#, options: []) {
            if let m = re.firstMatch(in: s, options: [], range: full), let r1 = Range(m.range(at: 1), in: s) {
                return Int(s[r1])
            }
        }
        
        return nil
    }
    
    // Parse ingredient name (remove quantity from string)
    private func parseIngredientName(_ ingredient: String) -> String {
        // Pattern: "amount unit name" or "amount name"
        // Examples: "200g Mehl", "2 Eier", "1 TL Salz"
        let pattern = #"^[\d\/.,\s-]+(?:g|kg|ml|l|tl|el|teel\u00f6ffel|essl\u00f6ffel|tasse|tassen|st\u00fcck|prise|prisen)?\s*"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: ingredient.utf16.count)
            let cleaned = regex.stringByReplacingMatches(in: ingredient, options: [], range: range, withTemplate: "")
            return cleaned.trimmingCharacters(in: .whitespaces)
        }
        return ingredient
    }
    
    // Parse ingredient quantity
    private func parseIngredientQuantity(_ ingredient: String) -> String? {
        let trimmed = ingredient.trimmingCharacters(in: .whitespaces)
        
        // Extended pattern with more units and variations
        let patterns = [
            // With units: "200g", "1 kg", "500 ml", etc.
            #"^([\d\/.,\s-]+\s*(?:g|kg|mg|ml|l|dl|cl|tl|el|esslöffel|teelöffel|essloeffel|teeloeffel|tasse|tassen|becher|stück|stueck|st\.|prise|prisen|bund|dose|dosen|paket|packung|glas|gläser))"#,
            // With English units
            #"^([\d\/.,\s-]+\s*(?:cup|cups|tbsp|tsp|oz|lb|pound|pounds|ounce|ounces|piece|pieces|pinch|bunch|can|cans|package))"#,
            // Just numbers at start: "2 ", "1/2 ", "1.5 "
            #"^([\d\/.,]+)\s+"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
               let range = Range(match.range(at: 1), in: trimmed) {
                let qty = String(trimmed[range]).trimmingCharacters(in: .whitespaces)
                if !qty.isEmpty {
                    Logger.debug("Parsed ingredient quantity: \(qty)", category: .data)
                    return qty
                }
            }
        }
        
        Logger.debug("No quantity match for ingredient: \(ingredient)", category: .data)
        return nil
    }
    
    // Scale quantity based on servings (default base is 4)
    private func scaleQuantity(_ quantity: String, servings: Int) -> String {
        let baseServings = 4
        let scale = Double(servings) / Double(baseServings)
        
        // Try to extract number and unit
        let pattern = #"([\d\/.,]+)\s*(.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: quantity, options: [], range: NSRange(location: 0, length: quantity.utf16.count)),
              let numberRange = Range(match.range(at: 1), in: quantity) else {
            return quantity
        }
        
        let numberStr = String(quantity[numberRange]).replacingOccurrences(of: ",", with: ".")
        let unit = match.range(at: 2).location != NSNotFound ? String(quantity[Range(match.range(at: 2), in: quantity)!]) : ""
        
        // Handle fractions
        if numberStr.contains("/") {
            let parts = numberStr.split(separator: "/")
            if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den != 0 {
                let value = num / den
                let scaled = value * scale
                return formatNumber(scaled) + unit
            }
        }
        
        // Handle regular numbers
        if let number = Double(numberStr) {
            let scaled = number * scale
            return formatNumber(scaled) + unit
        }
        
        return quantity
    }
    
    // Format number nicely (remove unnecessary decimals)
    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else if value < 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    // MARK: - Share Functions
    private func shareRecipe() {
        var items: [Any] = []
        
        // Generate Markdown
        let markdown = generateMarkdownExport()
        items.append(markdown)
        
        // Add Deep Link for public recipes
        if recipe.is_public == true {
            let deepLink = "https://culinachef.app/recipe/\(recipe.id)"
            if let url = URL(string: deepLink) {
                items.append(url)
            }
        }
        
        shareItems = items
        showShareSheet = true
    }
    
    private func generateMarkdownExport() -> String {
        var md = ""
        
        // Title
        md += "# \(recipe.title)\n\n"
        
        // Metadata
        if let cookTime = recipe.cooking_time {
            md += "**Kochzeit:** \(cookTime)\n\n"
        }
        if let difficulty = recipe.difficulty {
            md += "**Schwierigkeit:** \(difficulty)\n\n"
        }
        if let tags = recipe.tags, !tags.isEmpty {
            md += "**Tags:** \(tags.joined(separator: ", "))\n\n"
        }
        
        // Ingredients
        md += "## Zutaten\n\n"
        for ingredient in recipe.ingredients {
            md += "- \(ingredient)\n"
        }
        md += "\n"
        
        // Instructions
        md += "## Zubereitung\n\n"
        for (index, instruction) in recipe.instructions.enumerated() {
            let split = splitInstruction(instruction)
            let cleanText = split.body
            md += "**Schritt \(index + 1)**\n\n"
            md += "\(cleanText)\n\n"
        }
        
        // Nutrition
        md += "## Nährwerte (pro Portion)\n\n"
        if let calories = recipe.nutrition.calories {
            md += "- **Kalorien:** \(calories) kcal\n"
        }
        if let protein = recipe.nutrition.protein_g {
            md += "- **Protein:** \(String(format: "%.1f", protein))g\n"
        }
        if let carbs = recipe.nutrition.carbs_g {
            md += "- **Kohlenhydrate:** \(String(format: "%.1f", carbs))g\n"
        }
        if let fat = recipe.nutrition.fat_g {
            md += "- **Fett:** \(String(format: "%.1f", fat))g\n"
        }
        
        md += "\n---\n"
        md += "*Erstellt mit CulinaAI*\n"
        
        return md
    }
    
    // Add ingredients to shopping list
    private func addIngredientsToShoppingList(servings: Int) {
        let items = recipe.ingredients.map { ingredient -> ShoppingListItem in
            let name = parseIngredientName(ingredient)
            let quantity: String?
            
            if let qty = parseIngredientQuantity(ingredient) {
                let scaled = scaleQuantity(qty, servings: servings)
                quantity = scaled
            } else {
                quantity = nil
            }
            
            let category = ItemCategory.categorize(ingredient: ingredient)
            return ShoppingListItem(name: name, quantity: quantity, category: category)
        }
        
        Logger.info("Adding \(items.count) items to shopping list", category: .data)
        app.shoppingListManager.addItems(items)
        
        // Navigate to shopping list tab (only for saved recipes, not new ones)
        if recipe.created_at != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                app.selectedTab = 3 // Shopping list tab
            }
        }
    }
    
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        // Network errors
        if errorDescription.contains("cannotfindhost") || 
           errorDescription.contains("cannotconnecttohost") ||
           errorDescription.contains("network") ||
           errorDescription.contains("internet") {
            return L.errorNetworkConnection.localized
        }
        
        // Rate limit errors
        if errorDescription.contains("rate limit") || 
           errorDescription.contains("limit exceeded") {
            return L.errorRateLimitExceeded.localized
        }
        
        // Generic fallback
        return L.errorGenericUserFriendly.localized
    }
}

// MARK: - AI Chat Sheet for Saved Recipes
private struct RecipeAISheetForSavedRecipe: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    let currentStepIndex: Int

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var sending = false
    @State private var error: String?
    @State private var showConsentDialog = false
    @State private var showPaywallSheet = false

    var body: some View {
        Group {
            if app.hasAccess(to: .aiRecipeAnalysis) {
                chatContent
            } else {
                paywallContent
            }
        }
        .sheet(isPresented: $showConsentDialog) {
            OpenAIConsentDialog(
                onAccept: {
                    OpenAIConsentManager.hasConsent = true
                },
                onDecline: {}
            )
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallView()
                .environmentObject(app)
        }
    }
    
    private var chatContent: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.68), Color(red: 0.95, green: 0.74, blue: 0.64), Color(red: 0.93, green: 0.66, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(L.culinaName.localized)
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
.padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 10)

                // Chat list
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            if messages.isEmpty {
                                VStack(spacing: 10) {
                                    Text(L.recipe_stell_mir_fragen_zu.localized)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Text(L.recipe_zb_garzeiten_anpassen_ersatzzutaten.localized)
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(messages) { msg in
                                    SavedRecipeChatBubble(message: msg)
                                }
                                if sending {
                                    CulinaThinkingPenguinView()
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation(.easeOut) { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(L.messagePlaceholder.localized).foregroundStyle(.white.opacity(0.5))
                    }
                    TextField("", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .onChange(of: inputText) { _, newValue in
                            if newValue.count > 5000 {
                                inputText = String(newValue.prefix(5000))
                            }
                        }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(.clear)
                .frame(minHeight: 42)

                Button(action: { Task { await sendText() } }) {
                    Group { if sending { ProgressView().tint(.white) } else { Image(systemName: "paperplane.fill").foregroundStyle(.white) } }
                        .frame(width: 42, height: 42)
                        .background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        .shadow(color: Color.orange.opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .disabled(sending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            .opacity(0.6)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
                    .shadow(color: .purple.opacity(0.25), radius: 30, x: 0, y: 12)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .onAppear {
            if messages.isEmpty {
                messages.append(.init(role: .assistant, text: L.chatWelcomeMessage.localized))
            }
        }
    }

    private func sendText() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            messages.append(.init(role: .assistant, text: "KI-Funktionen sind auf modifizierten Geräten nicht verfügbar"))
            return
        }
        
        // Check DSGVO consent before using OpenAI
        guard OpenAIConsentManager.hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
        
        inputText = ""
        let userMsg = ChatMessage(role: .user, text: text)
        messages.append(userMsg)
        sending = true
        defer { sending = false }
        do {
            guard let token = app.accessToken else {
                throw NSError(domain: "rate_limit", code: -1, userInfo: [NSLocalizedDescriptionKey: L.errorNotLoggedIn.localized])
            }
            // Try to increment AI usage, but don't fail if backend is unreachable
            do {
                let txnID = await app.getOriginalTransactionId()
                _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: txnID)
            } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
                Logger.info("Backend unreachable for recipe AI, continuing without usage tracking", category: .network)
            } catch {
                await MainActor.run { 
                    self.error = userFriendlyErrorMessage(from: error)
                }
                return
            }
            guard let openai = (app.recipeAI ?? app.openAI) else { throw NSError(domain: "no_api", code: 0) }

            let sysGeneral = app.systemContext()
            let recipeJSON = try encodeRecipe(recipe)
            var sysRecipe = "Du bist ein Kochassistent. Verwende ausschließlich die bereitgestellten Rezeptdaten.\n\nWICHTIG: Halte deine Antworten SEHR KURZ. Maximal 2 Sätze. Keine ausführlichen Erklärungen. Nur die direkte Antwort auf die Frage.\n\nRezeptdaten (JSON):\n\(recipeJSON)\n"
            if currentStepIndex >= 0 {
                sysRecipe += "Aktueller Schritt Index (1-basiert): \(currentStepIndex + 1). Beziehe dich darauf in deiner Antwort.\n"
            } else {
                sysRecipe += "Der Nutzer ist auf der Übersicht.\n"
            }

            var prefixed: [ChatMessage] = []
            if !sysGeneral.isEmpty { prefixed.append(.init(role: .system, text: sysGeneral)) }
            prefixed.append(.init(role: .system, text: sysRecipe))
            prefixed.append(contentsOf: messages)

            let reply = try await openai.chatReply(messages: prefixed, maxHistory: prefixed.count)
            await MainActor.run { messages.append(.init(role: .assistant, text: reply)) }
        } catch {
            await MainActor.run { 
                let errorMsg = userFriendlyErrorMessage(from: error)
                messages.append(.init(role: .assistant, text: errorMsg))
            }
        }
    }

    private func encodeRecipe(_ recipe: Recipe) throws -> String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.withoutEscapingSlashes]
        let data = try enc.encode(recipe)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    private var paywallContent: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.68), Color(red: 0.95, green: 0.74, blue: 0.64), Color(red: 0.93, green: 0.66, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
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
                .padding(.horizontal, 16)
                .padding(.top, 18)
                
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .white.opacity(0.3), radius: 20)
                    
                    VStack(spacing: 12) {
                        Text(L.inRecipeAI.localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("Diese Funktion ist nur für Unlimited-Mitglieder verfügbar")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: { showPaywallSheet = true }) {
                        Text("Unlimited freischalten")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 280)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                    .accessibilityLabel("Unlimited freischalten")
                    .accessibilityHint("Öffnet die Abo-Auswahl")
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallView()
                .environmentObject(app)
        }
    }
    
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        // Network errors
        if errorDescription.contains("cannotfindhost") || 
           errorDescription.contains("cannotconnecttohost") ||
           errorDescription.contains("network") ||
           errorDescription.contains("internet") {
            return L.errorNetworkConnection.localized
        }
        
        // Rate limit errors
        if errorDescription.contains("rate limit") || 
           errorDescription.contains("limit exceeded") {
            return L.errorRateLimitExceeded.localized
        }
        
        // Generic fallback
        return L.errorGenericUserFriendly.localized
    }
}

// MARK: - Chat UI elements for saved recipes
private struct SavedRecipeChatBubble: View {
    let message: ChatMessage
    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 24) }
            Text(message.text)
                .foregroundStyle(.white)
                .padding(12)
                .background {
                    if isUser {
                        LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Rectangle().fill(.ultraThinMaterial)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(isUser ? 0.15 : 0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 6)
                .id(message.id)
            if !isUser { Spacer(minLength: 24) }
        }
        .padding(.horizontal, 4)
    }
}


// MARK: - Flow Layout (private to avoid conflicts)
private struct RecipeDetailFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Nutrition Item
struct NutritionItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Timer Components (private to RecipeDetailView)
private struct SharedTimerControl: View {
    let minutes: Int
    let label: String
    @ObservedObject var center: TimerCenter
    
    private var myTimer: RunningTimer? {
        center.timers.first { $0.label == label }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let has = myTimer != nil
            HStack(spacing: 8) {
                Image(systemName: "timer")
                Text(has ? "Timer läuft" : "Timer")
                Spacer()
                Text(formatted(myTimer?.remaining ?? minutes * 60))
                    .monospacedDigit()
                    .font(.headline)
            }
            .foregroundStyle(.white)
            HStack {
                Button(action: {
                    if let cur = myTimer { cur.running.toggle() }
                    else { center.start(minutes: minutes, label: label) }
                }) {
                    Label(myTimer == nil ? "Start" : ((myTimer?.running ?? false) ? "Pause" : "Start"), systemImage: (myTimer == nil) ? "play.fill" : ((myTimer?.running ?? false) ? "pause.fill" : "play.fill"))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                .foregroundStyle(.white)
                
                Button(action: { myTimer?.reset() }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .foregroundStyle(.white)
                
                Spacer()
                
                Stepper("", value: Binding(get: { myTimer?.baseMinutes ?? minutes }, set: { newVal in
                    let v = max(1, newVal)
                    if let cur = myTimer { cur.baseMinutes = v; cur.remaining = v * 60 }
                }), in: 1...720)
                .labelsHidden()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct FloatingTimerView: View {
    @ObservedObject var center: TimerCenter
    @ObservedObject var timer: RunningTimer
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Text(formatted(timer.remaining))
                    .monospacedDigit()
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Spacer()
            if timer.remaining == 0 {
                Button(action: {
                    timer.stopSound()
                    center.remove(timer: timer)
                }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                }
                Button(action: { timer.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.white)
                }
            } else {
                Button(action: { timer.running.toggle() }) {
                    Image(systemName: timer.running ? "pause.fill" : "play.fill")
                        .foregroundStyle(.white)
                }
                Button(action: { timer.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Rating Page
private extension RecipeDetailView {
    var ratingPage: some View {
        RatingSubmissionView(recipeId: recipe.id)
            .environmentObject(app)
    }
}

// MARK: - Serving Selector Sheet
private struct ServingSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var servings: Int
    let onConfirm: () -> Void
    
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
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text(L.recipe_für_wie_viele_personen.localized)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Text(L.recipe_die_mengen_werden_automatisch.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    // Serving stepper
                    HStack(spacing: 20) {
                        Button(action: { if servings > 1 { servings -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.white)
                        }
                        .disabled(servings <= 1)
                        .opacity(servings <= 1 ? 0.4 : 1.0)
                        
                        VStack(spacing: 4) {
                            Text("\(servings)")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundStyle(.white)
                            Text(servings == 1 ? "Person" : "Personen")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(minWidth: 140)
                        
                        Button(action: { servings += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    Button(action: {
                        onConfirm()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text(L.recipe_zur_einkaufsliste_hinzufügen.localized)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(20)
            }
            .navigationTitle(L.common_selectServings.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.cancel.localized) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct RatingSubmissionView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let recipeId: String
    @State private var selected: Int = 0
    @State private var submitting = false
    @State private var submitted = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(L.recipe_bewerte_dieses_rezept.localized)
                .font(.title3.bold())
                .foregroundStyle(.white)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= selected ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundStyle(.yellow)
                        .onTapGesture { selected = i }
                }
            }
            .padding(.vertical, 8)

            if submitted {
                Text(L.recipe_danke_für_deine_bewertung.localized)
                    .foregroundStyle(.white)
                Button(L.close.localized) { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
            } else {
                Button(action: { Task { await submit() } }) {
                    HStack {
                        if submitting { ProgressView().tint(.white) }
                        Text(L.recipe_submit.localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill((selected > 0) ? Color(red: 0.95, green: 0.5, blue: 0.3) : .gray)
                    )
                }
                .disabled(selected == 0 || submitting)
            }

            if let error { Text(error).foregroundStyle(.red) }
            Spacer()
        }
        .padding(16)
    }

    private func submit() async {
        guard let token = app.accessToken, let userId = KeychainManager.get(key: "user_id") else {
            await MainActor.run { self.error = L.errorNotLoggedIn.localized }
            return
        }
        submitting = true
        defer { submitting = false }
        do {
            try await app.upsertRating(recipeId: recipeId, rating: selected, accessToken: token, userId: userId)
            await MainActor.run { self.submitted = true }
        } catch {
            await MainActor.run { self.error = userFriendlyErrorMessage(from: error) }
        }
    }
    
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        // Network errors
        if errorDescription.contains("cannotfindhost") || 
           errorDescription.contains("cannotconnecttohost") ||
           errorDescription.contains("network") ||
           errorDescription.contains("internet") {
            return L.errorNetworkConnection.localized
        }
        
        // Rate limit errors
        if errorDescription.contains("rate limit") || 
           errorDescription.contains("limit exceeded") {
            return L.errorRateLimitExceeded.localized
        }
        
        // Generic fallback
        return L.errorGenericUserFriendly.localized
    }
}

// MARK: - Like Button for Toolbar
private struct LikeButtonToolbar: View {
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
                .foregroundColor(.pink)
                .font(.title3)
        }
    }
}

// MARK: - Clean Like Button for RecipeDetail Header
private struct LikeButtonToolbarClean: View {
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
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isLiked ? .pink : .white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
    }
}
