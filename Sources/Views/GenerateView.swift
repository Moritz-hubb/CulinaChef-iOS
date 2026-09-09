import SwiftUI

struct GenerateView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @State private var ingredients: [String] = []
    @State private var newIngredientText: String = ""
    @State private var generating = false
    @State private var generated: Recipe?
    @State private var error: String?
    @State private var showConsentDialog = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L.ui_zutaten.localized)) {
                    HStack(spacing: 8) {
TextField("z.B. Tomaten", text: $newIngredientText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .foregroundStyle(.white)
                            .accessibilityLabel(L.a11y_enterIngredient.localized)
                            .accessibilityHint(L.a11y_enterIngredientHint.localized)
                        Button(L.common_add.localized) {
                            let trimmed = newIngredientText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                ingredients.append(trimmed)
                                newIngredientText = ""
                            }
                        }
                        .accessibilityLabel(L.a11y_addIngredient.localized)
                        .accessibilityHint(L.a11y_addIngredientHint.localized)
                    }
                    if !ingredients.isEmpty {
                        ForEach(ingredients.indices, id: \.self) { index in
                            HStack {
                                Text(ingredients[index])
                                Spacer()
                                Button(action: { ingredients.remove(at: index) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .accessibilityLabel(L.a11y_removeIngredient.localized)
                                .accessibilityHint(L.a11y_removeNamedFromList.localized(replacing: ["item": ingredients[index]]))
                            }
                        }
                    }
                }
                Button(action: { Task { await generate() } }) {
                    if generating { ProgressView() } else { Text(L.generate_cookFromThis.localized) }
                }
                .accessibilityLabel(generating ? L.loading.localized : L.generate_cookFromThis.localized)
                .accessibilityHint(L.a11y_generateRecipeFromIngredients.localized)
                .disabled(generating || ingredients.isEmpty)

                if let r = generated {
                    Section(header: Text(L.generate_suggestion.localized)) {
                        NavigationLink(destination: RecipeDetailView(recipe: r)) {
                            VStack(alignment: .leading) {
                                Text(r.title).font(.headline)
                                Text("\((r.ingredients?.count ?? 0)) \(L.generate_ingredientsCount.localized)").font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                if let error { Text(error).foregroundColor(.red) }
            }
            .navigationTitle(L.nav_aiCooking.localized)
            .sheet(isPresented: $showConsentDialog) {
                OpenAIConsentDialog(
                    onAccept: {
                        OpenAIConsentManager.hasConsent = true
                        Task { await generate() }
                    },
                    onDecline: {
                        error = L.consent_required.localized
                    }
                )
            }
        }
    }

    func generate() async {
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            await MainActor.run {
                error = L.errorJailbreakDetected.localized
            }
            return
        }
        
        // Check DSGVO consent before using OpenAI
        guard OpenAIConsentManager.hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
        
        guard let token = app.accessToken else { return }
        error = nil
        generating = true
        defer { generating = false }
        guard !ingredients.isEmpty else { return }
        do {
            let recipe = try await app.backend.generateRecipe(ingredients: ingredients, accessToken: token)
            await MainActor.run { self.generated = recipe }
        } catch {
            await MainActor.run { 
                self.error = ErrorMessageHelper.userFriendlyMessage(from: error)
            }
        }
    }
}
