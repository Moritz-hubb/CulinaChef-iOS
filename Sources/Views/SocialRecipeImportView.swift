import SwiftUI

/// Importiert ein Rezept aus einem Social-Media-Link über das Backend (Metadaten + KI).
struct SocialRecipeImportView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    var onFinished: (Recipe) -> Void

    @State private var urlText: String = ""
    @State private var extraText: String = ""
    @State private var loading = false
    @State private var error: String?
    @State private var showConsentDialog = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(L.import_social_subtitle.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.import_social_url_label.localized)
                            .font(.subheadline.weight(.semibold))
                        TextField(L.import_social_url_placeholder.localized, text: $urlText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.import_social_extra_label.localized)
                            .font(.subheadline.weight(.semibold))
                        Text(L.import_social_extra_hint.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField(L.import_social_extra_placeholder.localized, text: $extraText, axis: .vertical)
                            .lineLimit(4...10)
                            .textFieldStyle(.roundedBorder)
                    }

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    Button(action: { Task { await runImport() } }) {
                        HStack {
                            if loading { ProgressView().tint(.white) }
                            Text(L.import_social_submit.localized)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.5, blue: 0.3),
                                    Color(red: 0.85, green: 0.4, blue: 0.2),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(loading || urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(loading || urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(20)
            }
            .navigationTitle(L.import_social_title.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.cancel.localized) { dismiss() }
                }
            }
            .alert(L.consent_title.localized, isPresented: $showConsentDialog) {
                Button(L.consent_decline.localized, role: .cancel) {}
                Button(L.consent_accept.localized) {
                    OpenAIConsentManager.hasConsent = true
                    app.openAIConsentGranted = true
                }
            } message: {
                Text(L.consent_subtitle.localized)
            }
        }
    }

    private func runImport() async {
        guard OpenAIConsentManager.hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
        guard let token = app.accessToken else {
            await MainActor.run { error = L.errorNotLoggedIn.localized }
            return
        }
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return }

        await MainActor.run {
            loading = true
            error = nil
        }
        defer {
            Task { @MainActor in loading = false }
        }

        do {
            let txnID = await app.getOriginalTransactionId()
            _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: txnID)
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
            return
        }

        let extra = extraText.trimmingCharacters(in: .whitespacesAndNewlines)
        let dietary = app.systemContext()
        do {
            let recipe = try await app.backend.importRecipeFromSocialURL(
                url: trimmedURL,
                extraText: extra.isEmpty ? nil : extra,
                dietaryContext: dietary.isEmpty ? nil : dietary,
                accessToken: token
            )
            await MainActor.run {
                app.cachedRecipes = [recipe] + app.cachedRecipes.filter { $0.id != recipe.id }
                onFinished(recipe)
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
}
