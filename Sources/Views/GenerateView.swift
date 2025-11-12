import SwiftUI

fileprivate enum AIConsent {
    private static let key = "openai_consent_granted"
    static var hasConsent: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

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
                ZStack {
                    LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7), Color(red: 0.99, green: 0.7, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                            Text(L.consent_title.localized)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text(L.consent_subtitle.localized)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        
                        HStack(spacing: 12) {
                            Button(role: .cancel) { showConsentDialog = false } label: {
                                Text(L.consent_decline.localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            Spacer()
                            Button {
                                AIConsent.hasConsent = true
                                showConsentDialog = false
                                Task { await generate() }
                            } label: {
                                Text(L.consent_accept.localized)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(
                                        LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule()
                                    )
                                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
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
        guard AIConsent.hasConsent else {
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
