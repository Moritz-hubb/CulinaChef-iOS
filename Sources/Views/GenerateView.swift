import SwiftUI

struct GenerateView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @State private var ingredients: [String] = []
    @State private var newIngredientText: String = ""
    @State private var generating = false
    @State private var generated: Recipe?
    @State private var error: String?
    @State private var showPaywall = false
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
                        Button("Hinzufügen") {
                            let trimmed = newIngredientText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                ingredients.append(trimmed)
                                newIngredientText = ""
                            }
                        }
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
                            }
                        }
                    }
                }
                Button(action: { Task { await generate() } }) {
                    if generating { ProgressView() } else { Text(L.generate_cookFromThis.localized) }
                }
                .disabled(generating || ingredients.isEmpty)

                if let r = generated {
                    Section(header: Text(L.generate_suggestion.localized)) {
                        NavigationLink(destination: RecipeDetailView(recipe: r)) {
                            VStack(alignment: .leading) {
                                Text(r.title).font(.headline)
                                Text("\(r.ingredients.count) \(L.generate_ingredientsCount.localized)").font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                if let error { Text(error).foregroundColor(.red) }
            }
            .navigationTitle("KI Kochen")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(app)
            }
            .sheet(isPresented: $showConsentDialog) {
                VStack(spacing: 16) {
                    Text("KI-Funktionen nutzen")
                        .font(.title2.bold())
                    Text("Einwilligung zur Datenverarbeitung (OpenAI, USA). Ohne Zustimmung können KI-Funktionen nicht genutzt werden.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    HStack {
                        Button(role: .cancel) {
                            showConsentDialog = false
                        } label: { Text("Ablehnen") }
                        Spacer()
                        Button {
                            OpenAIConsentManager.hasConsent = true
                            showConsentDialog = false
                            Task { await generate() }
                        } label: { Text("Zustimmen und fortfahren").bold() }
                    }
                }
                .padding()
            }
        }
    }

    func generate() async {
        // Check feature access first
        guard app.hasAccess(to: .aiRecipeGenerator) else {
            await MainActor.run {
                showPaywall = true
            }
            return
        }
        
        guard let token = app.accessToken else { return }
        guard OpenAIConsentManager.hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
        error = nil
        generating = true
        defer { generating = false }
        guard !ingredients.isEmpty else { return }
        do {
            let recipe = try await app.backend.generateRecipe(ingredients: ingredients, accessToken: token)
            await MainActor.run { self.generated = recipe }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }
}
