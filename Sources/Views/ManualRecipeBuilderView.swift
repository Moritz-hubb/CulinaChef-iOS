import SwiftUI
import PhotosUI

struct ManualRecipeBuilderView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    // Basic Info
    @State private var recipeName: String = ""
    @State private var servings: String = "4"
    @State private var cookingTime: String = ""
    @State private var difficulty: String = ""
    
    // Images
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: Data?
    @State private var isUploadingPhoto = false
    
    // Ingredients
    @State private var ingredients: [ManualIngredient] = [ManualIngredient()]
    
    // Nutrition (optional)
    @State private var showNutrition: Bool = false
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    
    // Steps
    @State private var steps: [ManualStep] = [ManualStep(number: 1)]
    
    // Tags
    @State private var selectedTags: Set<String> = []
    
    // Saving
    @State private var isSaving: Bool = false
    @State private var saveError: String?
    @State private var showSuccessAlert: Bool = false
    
    // Character limit tracking
    var totalCharacterCount: Int {
        let nameCount = recipeName.count
        let ingredientsCount = ingredients.map { $0.text.count }.reduce(0, +)
        let stepsCount = steps.map { $0.text.count }.reduce(0, +)
        return nameCount + ingredientsCount + stepsCount
    }
    
    private var difficultyOptions: [String] {
        [L.difficulty_easy.localized, L.difficulty_medium.localized, L.difficulty_hard.localized]
    }
    private var availableTags: [String] {
        [
            L.tag_vegan.localized,
            L.tag_vegetarian.localized,
            L.tag_glutenFree.localized,
            L.tag_lactoseFree.localized,
            L.tag_lowCarb.localized,
            L.tag_highProtein.localized,
            L.tag_quick.localized,
            L.tag_budget.localized
        ]
    }
    
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
                
                ScrollView {
                    Color.clear.onAppear {
                        if difficulty.isEmpty {
                            difficulty = L.difficulty_medium.localized
                        }
                    }
                    VStack(spacing: 20) {
                        // MARK: - Basic Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(L.label_basicInfo.localized)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(L.label_recipeName.localized)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Spacer()
                                    Text("\(recipeName.count)/60")
                                        .font(.caption)
                                        .foregroundStyle(recipeName.count > 60 ? .red : .white.opacity(0.6))
                                }
                                TextField(L.placeholder_recipeName.localized, text: $recipeName)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(.white)
                                    .tint(.white)
                                    .accessibilityLabel(L.label_recipeName.localized)
                                    .accessibilityHint(L.placeholder_recipeName.localized)
                                    .padding(12)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .focused($isFocused)
                                    .onChange(of: recipeName) { _, newValue in
                                        if newValue.count > 60 {
                                            recipeName = String(newValue.prefix(60))
                                        }
                                        enforceGlobalLimit()
                                    }
                            }
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L.label_servings.localized + " *")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                    TextField("4", text: $servings)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(.white)
                                        .tint(.white)
                                        .accessibilityLabel(L.label_servings.localized)
                                        .accessibilityHint("Anzahl der Portionen")
                                        .padding(12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .focused($isFocused)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L.label_timeMinutes.localized)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                    TextField("30", text: $cookingTime)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(.white)
                                        .tint(.white)
                                        .accessibilityLabel(L.label_timeMinutes.localized)
                                        .accessibilityHint("Kochzeit in Minuten")
                                        .padding(12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .focused($isFocused)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L.label_difficulty.localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                                Picker(L.label_difficulty.localized, selection: $difficulty) {
                                    ForEach(difficultyOptions, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        
                        // MARK: - Photo Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(L.label_photoOptional.localized)
                            
                            if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        Button(action: { self.photoData = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white)
                                                .background(Circle().fill(.black.opacity(0.5)))
                                        }
                                        .padding(8),
                                        alignment: .topTrailing
                                    )
                            } else {
                                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 1, matching: .images) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                        Text(L.recipe_foto_hinzufügen.localized)
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                        
                        // MARK: - Tags Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(L.label_categories.localized)
                            TagSelectionView(options: availableTags, selection: $selectedTags)
                        }
                        
                        // MARK: - Ingredients Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SectionTitle(L.label_ingredients.localized)
                                Spacer()
                                Button(action: { ingredients.append(ManualIngredient()) }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            ForEach(ingredients.indices, id: \.self) { index in
                                HStack(spacing: 8) {
                                    TextField(L.placeholder_ingredient.localized, text: $ingredients[index].text)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(.white)
                                        .tint(.white)
                                        .padding(12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .focused($isFocused)
                                        .onChange(of: ingredients[index].text) { _, _ in
                                            enforceGlobalLimit()
                                        }
                                    
                                    if ingredients.count > 1 {
                                        Button(action: { ingredients.remove(at: index) }) {
                                            Image(systemName: "trash")
                                                .foregroundStyle(.white.opacity(0.7))
                                                .padding(12)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Nutrition Section
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $showNutrition) {
                                SectionTitle(L.label_nutritionOptional.localized)
                            }
                            .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                            
                            if showNutrition {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        NutritionField(title: L.label_calories.localized, text: $calories, unit: "kcal")
                                        NutritionField(title: L.label_protein.localized, text: $protein, unit: "g")
                                    }
                                    HStack(spacing: 12) {
                                        NutritionField(title: L.label_carbs.localized, text: $carbs, unit: "g")
                                        NutritionField(title: L.label_fat.localized, text: $fat, unit: "g")
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Steps Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SectionTitle(L.label_preparationSteps.localized)
                                Spacer()
                                Button(action: { steps.append(ManualStep(number: steps.count + 1)) }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            ForEach(steps.indices, id: \.self) { index in
                                StepEditorView(
                                    step: $steps[index],
                                    stepNumber: index + 1,
                                    onDelete: steps.count > 1 ? { steps.remove(at: index) } : nil,
                                    isFocused: $isFocused,
                                    onTextChange: { enforceGlobalLimit() }
                                )
                            }
                        }
                        
                        // MARK: - Save Button
                        Button(action: { Task { await saveRecipe() } }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(L.button_save.localized)
                                }
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
                                ),
                                in: Capsule()
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isSaving || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.5)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(L.nav_createRecipe.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L.button_done.localized) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: selectedPhotos) { _, newValue in
            Task {
                if let item = newValue.first {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run { self.photoData = data }
                    }
                }
            }
        }
        .alert(L.alert_error.localized, isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button(L.button_ok.localized) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
        .alert(L.alert_successfullySaved.localized, isPresented: $showSuccessAlert) {
            Button(L.button_ok.localized) {
                dismiss()
            }
        } message: {
            Text(L.recipe_dein_rezept_wurde_erfolgreich.localized)
        }
    }
    
    var isFormValid: Bool {
        !recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !servings.isEmpty &&
        ingredients.contains(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) &&
        steps.contains(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }
    
    func enforceGlobalLimit() {
        let total = totalCharacterCount
        if total > 10000 {
            let excess = total - 10000
            trimExcessCharacters(excess: excess)
        }
    }
    
    func trimExcessCharacters(excess: Int) {
        var remaining = excess
        
        // Trim from steps (last to first)
        for i in (0..<steps.count).reversed() {
            if remaining <= 0 { break }
            let stepLength = steps[i].text.count
            if stepLength > 0 {
                let toRemove = min(remaining, stepLength)
                steps[i].text = String(steps[i].text.prefix(stepLength - toRemove))
                remaining -= toRemove
            }
        }
        
        // Trim from ingredients (last to first)
        for i in (0..<ingredients.count).reversed() {
            if remaining <= 0 { break }
            let ingLength = ingredients[i].text.count
            if ingLength > 0 {
                let toRemove = min(remaining, ingLength)
                ingredients[i].text = String(ingredients[i].text.prefix(ingLength - toRemove))
                remaining -= toRemove
            }
        }
        
        // Trim from recipe name (as last resort)
        if remaining > 0 {
            let nameLength = recipeName.count
            if nameLength > 0 {
                let toRemove = min(remaining, nameLength)
                recipeName = String(recipeName.prefix(nameLength - toRemove))
            }
        }
    }
    
    func saveRecipe() async {
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = app.accessToken else {
            await MainActor.run { saveError = L.errorNotLoggedIn.localized }
            return
        }
        
        await MainActor.run { isSaving = true }
        defer { Task { await MainActor.run { isSaving = false } } }
        
        do {
            // Upload photo if exists
            var imageUrl: String?
            if let photoData = photoData {
                imageUrl = try await uploadPhoto(photoData, userId: userId, token: token)
            }
            
            // Prepare recipe data
            let ingredientsList = ingredients
                .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let instructionsList = steps
                .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let nutrition: [String: Any] = [
                "calories": Int(calories) ?? NSNull(),
                "protein_g": Double(protein) ?? NSNull(),
                "carbs_g": Double(carbs) ?? NSNull(),
                "fat_g": Double(fat) ?? NSNull()
            ]
            
            let cookingTimeStr = cookingTime.isEmpty ? nil : "\(cookingTime) Min"
            
            let recipeData: [String: Any] = [
                "user_id": userId,
                "title": recipeName.trimmingCharacters(in: .whitespacesAndNewlines),
                "ingredients": ingredientsList,
                "instructions": instructionsList,
                "nutrition": nutrition,
                "image_url": imageUrl ?? NSNull(),
                "cooking_time": cookingTimeStr ?? NSNull(),
                "difficulty": difficulty,
                "tags": Array(selectedTags)
            ]
            
            // Save to Supabase
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/recipes")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("return=representation", forHTTPHeaderField: "Prefer")
            
            request.httpBody = try JSONSerialization.data(withJSONObject: recipeData)
            
            let (data, response) = try await SecureURLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            let savedRecipes = try JSONDecoder().decode([Recipe].self, from: data)
            
            await MainActor.run {
                if let savedRecipe = savedRecipes.first {
                    app.lastCreatedRecipe = savedRecipe
                }
                showSuccessAlert = true
                
                // Track positive action for App Store review
                AppStoreReviewManager.recordPositiveAction()
                // Check if we should request a review
                AppStoreReviewManager.requestReviewIfAppropriate()
            }
            
        } catch {
            await MainActor.run {
                saveError = "\(L.errorSaveFailed.localized): \(error.localizedDescription)"
            }
        }
    }
    
    func uploadPhoto(_ data: Data, userId: String, token: String) async throws -> String {
        let fileName = "\(userId)_\(UUID().uuidString).jpg"
        
        // Resize to fit max dimensions (aspect fit) and compress
        guard let image = UIImage(data: data),
              let resizedImage = resizeImageToFit(image, maxWidth: 1200, maxHeight: 800),
              let compressedData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let uploadUrlString = "\(Config.supabaseURL.absoluteString)/storage/v1/object/recipe-photo/\(fileName)"
        guard let uploadUrl = URL(string: uploadUrlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "POST"
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = compressedData
        
        let (responseData, response) = try await SecureURLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            // Log error for debugging
            if let errorString = String(data: responseData, encoding: .utf8) {
                Logger.error("Photo upload failed with status \(httpResponse.statusCode): \(errorString)", category: .network)
            }
            throw URLError(.badServerResponse)
        }
        
        let publicURL = "\(Config.supabaseURL.absoluteString)/storage/v1/object/public/recipe-photo/\(fileName)"
        return publicURL
    }
    
    func resizeImageToFit(_ image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage? {
        let originalSize = image.size
        
        // If image is already smaller than max dimensions, return original
        if originalSize.width <= maxWidth && originalSize.height <= maxHeight {
            return image
        }
        
        // Calculate scale factor to fit within max dimensions (aspect fit)
        let widthRatio = maxWidth / originalSize.width
        let heightRatio = maxHeight / originalSize.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: originalSize.width * scaleFactor,
            height: originalSize.height * scaleFactor
        )
        
        // Render the resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Supporting Types
struct ManualIngredient: Identifiable {
    let id = UUID()
    var text: String = ""
}

struct ManualStep: Identifiable {
    let id = UUID()
    var number: Int
    var text: String = ""
    var timerMinutes: String = ""
}

// MARK: - Supporting Views
private struct SectionTitle: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
    }
}

private struct NutritionField: View {
    let title: String
    @Binding var text: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            HStack {
                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .tint(.white)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct TagSelectionView: View {
    let options: [String]
    @Binding var selection: Set<String>
    
    var body: some View {
        ManualFlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { tag in
                TagChip(text: tag, isSelected: selection.contains(tag)) {
                    if selection.contains(tag) {
                        selection.remove(tag)
                    } else {
                        selection.insert(tag)
                    }
                }
            }
        }
    }
}

private struct TagChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.callout.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                        AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )) :
                        AnyShapeStyle(Color.white.opacity(0.08))
                )
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct ManualFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

private struct StepEditorView: View {
    @Binding var step: ManualStep
    let stepNumber: Int
    let onDelete: (() -> Void)?
    @FocusState.Binding var isFocused: Bool
    let onTextChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(L.label_step.localized) \(stepNumber)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            
            TextField(L.placeholder_stepDescription.localized, text: $step.text, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .tint(.white)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .focused($isFocused)
                .lineLimit(3...10)
                .onChange(of: step.text) { _, _ in
                    onTextChange()
                }
            
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .foregroundStyle(.white.opacity(0.7))
                Text(L.label_timer.localized)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                TextField(L.placeholder_minutes.localized, text: $step.timerMinutes)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .padding(8)
                    .frame(width: 60)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .focused($isFocused)
                Text(L.label_minutes.localized)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
