import SwiftUI

struct SocialRecipeImportView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    var initialURL: String? = nil
    var autoStartFromShare: Bool = false
    var onFinished: (Recipe) -> Void

    @State private var urlText: String = ""
    @State private var loading = false
    @State private var error: String?
    @State private var showConsentDialog = false
    @State private var didTriggerAutoStart = false
    @State private var selectedTweaks: Set<String> = []
    @State private var tweakText: String = ""
    @State private var showTweaks = false
    @FocusState private var isFocused: Bool

    private static let availableTweaks: [(slug: String, labelKey: String)] = [
        ("vegan", "category.vegan"),
        ("vegetarian", "category.vegetarian"),
        ("pescetarian", "category.pescetarian"),
        ("gluten-free", "category.glutenFree"),
        ("lactose-free", "category.lactoseFree"),
        ("low-carb", "category.lowCarb"),
        ("high-protein", "category.highProtein"),
        ("halal", "category.halal"),
        ("kosher", "category.kosher"),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.78, blue: 0.68),
                        Color(red: 0.95, green: 0.74, blue: 0.64),
                        Color(red: 0.93, green: 0.66, blue: 0.55),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if loading {
                    loadingOverlay
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // URL input
                            SocialImportLabel(L.import_social_url_label.localized)

                            HStack(spacing: 10) {
                                Image(systemName: "link")
                                    .foregroundStyle(.white.opacity(0.6))
                                TextField(L.import_social_url_placeholder.localized, text: $urlText)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .foregroundStyle(.white)
                                    .tint(.white)
                                    .focused($isFocused)

                                if !urlText.isEmpty {
                                    Button { urlText = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                            }
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            // Tweak section
                            tweakSection

                            if let error {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error)
                                }
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.red.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            // Import button
                            Button(action: { Task { await runImport() } }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "wand.and.stars")
                                    Text(L.import_social_submit.localized)
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.5, blue: 0.3),
                                            Color(red: 0.85, green: 0.4, blue: 0.2),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: Capsule()
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 6)
                            }
                            .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                            .padding(.top, 4)
                        }
                        .foregroundStyle(.white)
                        .padding(16)
                        .contentShape(Rectangle())
                        .onTapGesture { isFocused = false }
                    }
                }
            }
            .navigationTitle(L.import_social_title.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.cancel.localized) { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .interactiveDismissDisabled(loading && autoStartFromShare)
            .alert(L.consent_title.localized, isPresented: $showConsentDialog) {
                Button(L.consent_decline.localized, role: .cancel) {}
                Button(L.consent_accept.localized) {
                    OpenAIConsentManager.hasConsent = true
                    app.openAIConsentGranted = true
                    if autoStartFromShare {
                        Task { await runImport() }
                    }
                }
            } message: {
                Text(L.consent_subtitle.localized)
            }
            .onAppear {
                if urlText.isEmpty, let initialURL, !initialURL.isEmpty {
                    urlText = initialURL
                }
                guard autoStartFromShare, !didTriggerAutoStart else { return }
                let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                didTriggerAutoStart = true
                Task { await runImport() }
            }
        }
    }

    // MARK: - Loading overlay

    private var loadingOverlay: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text(L.import_social_processing.localized)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .shadow(color: Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.2), radius: 30, x: 0, y: 5)
            )
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Tweak section

    @ViewBuilder
    private var tweakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showTweaks.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline)
                    Text(L.import_social_tweak_title.localized)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: showTweaks ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            if !showTweaks && (!selectedTweaks.isEmpty || !tweakText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                let summary = [
                    selectedTweaks.isEmpty ? nil : selectedTweaks.sorted().joined(separator: ", "),
                    tweakText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "\"\(tweakText.trimmingCharacters(in: .whitespacesAndNewlines))\""
                ].compactMap { $0 }
                Text(summary.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            if showTweaks {
                Text(L.import_social_tweak_subtitle.localized)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                ImportTweakChips(
                    tweaks: Self.availableTweaks,
                    selection: $selectedTweaks
                )

                TextField(L.import_social_tweak_prompt_placeholder.localized, text: $tweakText, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused($isFocused)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Import logic

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

        await MainActor.run {
            loading = true
            error = nil
            isFocused = false
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

        let dietary = app.systemContext()
        let lang = app.currentLanguageCode()
        do {
            let tweaks = selectedTweaks.isEmpty ? nil : Array(selectedTweaks)
            let trimmedTweak = tweakText.trimmingCharacters(in: .whitespacesAndNewlines)
            let recipe = try await app.backend.importRecipeFromSocialURL(
                url: trimmedURL,
                recipeLanguage: lang,
                dietaryContext: dietary.isEmpty ? nil : dietary,
                recipeTweaks: tweaks,
                tweakText: trimmedTweak.isEmpty ? nil : trimmedTweak,
                accessToken: token
            )
            Logger.info("[SocialImport] runImport success recipeId=\(recipe.id)", category: .data)
            await MainActor.run {
                app.cachedRecipes = [recipe] + app.cachedRecipes.filter { $0.id != recipe.id }
                onFinished(recipe)
                dismiss()
            }
        } catch {
            Logger.error("[SocialImport] importRecipeFromSocialURL failed", error: error, category: .network)
            await MainActor.run {
                self.error = importErrorMessage(for: error)
            }
        }
    }

    private func importErrorMessage(for error: Error) -> String {
        let ns = error as NSError
        if ns.domain == "Backend",
           ns.code == 422,
           let detail = ns.userInfo[NSLocalizedDescriptionKey] as? String,
           detail == "INSUFFICIENT_FOOD_METADATA" {
            return L.import_social_insufficient_info.localized
        }
        return error.localizedDescription
    }
}

// MARK: - Section label (matches RecipeCreatorView GroupBoxLabel)

private struct SocialImportLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Tweak chips (wrap layout)

private struct ImportTweakChips: View {
    let tweaks: [(slug: String, labelKey: String)]
    @Binding var selection: Set<String>
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        VStack {
            GeometryReader { geo in
                generateContent(in: geo)
            }
            .frame(height: totalHeight)
        }
    }

    private func chip(slug: String, label: String) -> some View {
        let isOn = selection.contains(slug)
        return Text(label)
            .font(.callout.weight(.medium))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Group {
                    if isOn {
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.5, blue: 0.3),
                                Color(red: 0.85, green: 0.4, blue: 0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.08)
                    }
                }
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isOn { selection.remove(slug) } else { selection.insert(slug) }
                }
            }
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(tweaks, id: \.slug) { tweak in
                chip(slug: tweak.slug, label: tweak.labelKey.localized)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if tweak.slug == tweaks.last!.slug { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if tweak.slug == tweaks.last!.slug { height = 0 }
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
