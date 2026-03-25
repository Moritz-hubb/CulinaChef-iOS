import SwiftUI

/// Importiert ein Rezept aus einem Social-Media-Link über das Backend (Metadaten + KI).
struct SocialRecipeImportView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    /// Vom Share Sheet gesetzt (TikTok → CulinaChef)
    var initialURL: String? = nil
    var initialExtra: String? = nil

    var onFinished: (Recipe) -> Void

    @State private var urlText: String = ""
    @State private var extraText: String = ""
    @State private var loading = false
    @State private var error: String?
    @State private var showConsentDialog = false
    @State private var metadataPreview: SocialMetadataPreview?
    @State private var metadataLoading = false
    @State private var metadataError: String?

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

                    metadataSection

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
            .onAppear {
                #if DEBUG
                Logger.debug(
                    "[SocialImport] SocialRecipeImportView onAppear initialURL_len=\(initialURL?.count ?? 0) initialExtra=\(initialExtra != nil)",
                    category: .ui
                )
                #endif
                if urlText.isEmpty, let u = initialURL, !u.isEmpty {
                    urlText = u
                }
                if extraText.isEmpty, let e = initialExtra, !e.isEmpty {
                    extraText = e
                }
                let raw = urlText.isEmpty ? (initialURL ?? "") : urlText
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    #if DEBUG
                    Logger.debug("[SocialImport] skip metadata preview: empty url", category: .ui)
                    #endif
                    return
                }
                Task { await loadMetadataPreview(for: trimmed) }
            }
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L.import_social_metadata_heading.localized)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(L.import_social_metadata_reload.localized) {
                    Task {
                        let u = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !u.isEmpty else { return }
                        await loadMetadataPreview(for: u)
                    }
                }
                .font(.subheadline)
                .disabled(metadataLoading || urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Text(L.import_social_metadata_hint.localized)
                .font(.caption)
                .foregroundColor(.secondary)

            if metadataLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(L.import_social_metadata_loading.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            // Keine Warnung, wenn bereits Titel (o. ä.) aus der Vorschau da ist — Beschreibung ist optional.
            if let metaErr = metadataError, !hasRecognizedMetadataForDisplay {
                Text(metaErr)
                    .font(.footnote)
                    .foregroundColor(.orange)
            }
            if let preview = metadataPreview {
                VStack(alignment: .leading, spacing: 10) {
                    socialMetaRow(L.import_social_metadata_platform.localized, preview.platform)
                    socialMetaRow(L.import_social_metadata_author.localized, preview.author_name)
                    socialMetaRow(L.import_social_metadata_title.localized, preview.title)
                    socialMetaRow(L.import_social_metadata_description.localized, preview.description)
                    if let snippet = preview.raw_snippet,
                       !snippet.isEmpty,
                       snippet != preview.description,
                       snippet != preview.title {
                        socialMetaRow(L.import_social_metadata_snippet.localized, snippet)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func socialMetaRow(_ label: String, _ value: String?) -> some View {
        let text = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text.isEmpty ? L.import_social_metadata_empty.localized : text)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    private func loadMetadataPreview(for url: String) async {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run {
                metadataPreview = nil
                metadataError = nil
            }
            #if DEBUG
            Logger.debug("[SocialImport] loadMetadataPreview aborted: empty url", category: .ui)
            #endif
            return
        }
        guard let token = app.accessToken else {
            await MainActor.run {
                metadataError = L.import_social_metadata_need_login.localized
                metadataPreview = nil
            }
            Logger.warning("[SocialImport] loadMetadataPreview: not logged in", category: .ui)
            return
        }
        #if DEBUG
        Logger.debug("[SocialImport] loadMetadataPreview start url=\(trimmed.prefix(160))", category: .ui)
        #endif
        await MainActor.run {
            metadataLoading = true
            metadataError = nil
        }
        defer {
            Task { @MainActor in metadataLoading = false }
        }
        do {
            let preview = try await app.backend.previewSocialMetadata(url: trimmed, accessToken: token)
            await MainActor.run {
                metadataPreview = preview
                metadataError = nil
            }
            #if DEBUG
            Logger.debug(
                "[SocialImport] loadMetadataPreview success platform=\(preview.platform) title=\(preview.title?.prefix(80) ?? "nil") desc_len=\(preview.description?.count ?? 0)",
                category: .ui
            )
            #endif
        } catch {
            await MainActor.run {
                metadataPreview = nil
                metadataError = error.localizedDescription
            }
            Logger.error("[SocialImport] loadMetadataPreview failed", error: error, category: .network)
        }
    }

    private func runImport() async {
        guard OpenAIConsentManager.hasConsent else {
            Logger.debug("[SocialImport] runImport blocked: no OpenAI consent", category: .ui)
            await MainActor.run { showConsentDialog = true }
            return
        }
        guard let token = app.accessToken else {
            Logger.warning("[SocialImport] runImport: not logged in", category: .ui)
            await MainActor.run { error = L.errorNotLoggedIn.localized }
            return
        }
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return }

        #if DEBUG
        Logger.debug("[SocialImport] runImport start url=\(trimmedURL.prefix(160))", category: .ui)
        #endif

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
            Logger.error("[SocialImport] incrementAIUsage failed", error: error, category: .network)
            await MainActor.run {
                self.error = error.localizedDescription
            }
            return
        }

        let extra = extraText.trimmingCharacters(in: .whitespacesAndNewlines)
        let dietary = app.systemContext()
        #if DEBUG
        Logger.debug(
            "[SocialImport] runImport preflight snapshot=\(metadataSnapshotForImport != nil) url_len=\(trimmedURL.count) preview_url=\(metadataPreview?.url.prefix(120) ?? "nil") urls_match=\(metadataSnapshotForImport != nil)",
            category: .ui
        )
        #endif
        do {
            let recipe = try await app.backend.importRecipeFromSocialURL(
                url: trimmedURL,
                extraText: extra.isEmpty ? nil : extra,
                dietaryContext: dietary.isEmpty ? nil : dietary,
                accessToken: token,
                prefetchedTitle: metadataPreview?.title,
                prefetchedDescription: metadataPreview?.description,
                prefetchedAuthor: metadataPreview?.author_name,
                metadataSnapshot: metadataSnapshotForImport
            )
            Logger.info("[SocialImport] runImport success recipeId=\(recipe.id)", category: .data)
            await MainActor.run {
                app.cachedRecipes = [recipe] + app.cachedRecipes.filter { $0.id != recipe.id }
                onFinished(recipe)
                dismiss()
            }
        } catch {
            Logger.error("[SocialImport] importRecipeFromSocialURL failed", error: error, category: .network)
            Logger.error(
                "[SocialImport] runImport failure detail describing=\(String(describing: error)) localized=\(error.localizedDescription)",
                category: .network
            )
            await MainActor.run {
                self.error = importErrorMessage(
                    for: error,
                    hasUsableMetadataPreview: hasRecognizedMetadataForDisplay
                )
            }
        }
    }

    /// Wenn die Vorschau zur aktuellen URL passt, senden wir dieselbe Payload wie `preview-social-metadata` —
    /// das Backend nutzt sie dann ohne zweiten Metadaten-Fetch (identisch zum Test-Bereich).
    private var metadataSnapshotForImport: SocialMetadataPreview? {
        guard let preview = metadataPreview else { return nil }
        let current = normalizedSocialURL(urlText)
        guard !current.isEmpty, normalizedSocialURL(preview.url) == current else { return nil }
        return preview
    }

    private func normalizedSocialURL(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Mindestens Titel, Beschreibung oder Snippet aus der Vorschau — dann keine orange „Metadaten“-Warnung.
    private var hasRecognizedMetadataForDisplay: Bool {
        guard let p = metadataPreview else { return false }
        if let t = p.title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return true }
        if let d = p.description?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty { return true }
        if let s = p.raw_snippet?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { return true }
        return false
    }

    private func importErrorMessage(for error: Error, hasUsableMetadataPreview: Bool) -> String {
        if hasUsableMetadataPreview {
            return L.import_social_import_failed_hint.localized
        }
        return error.localizedDescription
    }
}
