import SwiftUI
import PhotosUI

struct ChatView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var sending = false
    @FocusState private var isInputFocused: Bool

    @State private var showPhotoPicker = false
    @State private var showImageSourcePicker = false
    @State private var pickedImageData: Data?
    @State private var imageSourceType: UIImagePickerController.SourceType = .camera

    var body: some View {
        Group {
            if app.hasAccess(to: .aiChat) {
                chatContent
            } else {
                paywallContent
            }
        }
    }
    
    private var chatContent: some View {
        ZStack {
            // Background with depth and gradient
LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.68), Color(red: 0.95, green: 0.74, blue: 0.64), Color(red: 0.93, green: 0.66, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard)
            
            // Chat list filling the full height
            ScrollViewReader { proxy in
                ScrollView {
                    if messages.isEmpty {
                        EmptyStateView()
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 500)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(messages) { msg in
                                ChatBubble(message: msg)
                                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                            }
                            
                            // Nachdenkender Pinguin während des Ladens
                            if sending {
                                CulinaThinkingPenguinView()
                                    .transition(.scale.combined(with: .opacity))
                                    .id("thinkingPenguin")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 120) // Space for input bar
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = false
                }
                .onChange(of: messages.count) { _ in
                    // Only scroll to last message if NOT currently sending
                    if !sending {
                        withAnimation(.easeOut) {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: sending) { _, isSending in
                    if isSending {
                        // Scroll to penguin when it appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut) {
                                proxy.scrollTo("thinkingPenguin", anchor: .bottom)
                            }
                        }
                    } else {
                        // When sending completes, scroll to last message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut) {
                                proxy.scrollTo(messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Input bar overlay at bottom
            VStack {
                Spacer()
                inputBar
                    .background(.clear)
                    .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea(.keyboard)
        .confirmationDialog(L.common_chooseImage.localized, isPresented: $showImageSourcePicker, titleVisibility: .visible) {
            Button(L.common_takePhoto.localized) {
                imageSourceType = .camera
                showPhotoPicker = true
            }
            Button(L.common_chooseFromGallery.localized) {
                imageSourceType = .photoLibrary
                showPhotoPicker = true
            }
            Button(L.cancel.localized, role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showPhotoPicker) {
            ImagePicker(isPresented: $showPhotoPicker, sourceType: imageSourceType) { data in
                pickedImageData = data
            }
        }
    }
    
    private var paywallContent: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.68), Color(red: 0.95, green: 0.74, blue: 0.64), Color(red: 0.93, green: 0.66, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .white.opacity(0.3), radius: 20)
                
                VStack(spacing: 12) {
                    Text("AI Chat")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Diese Funktion ist nur für Unlimited-Mitglieder verfügbar")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: { Task { await app.purchaseStoreKit() } }) {
                    Text("Unlimited freischalten")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 300)
                        .frame(height: 56)
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
                .padding(.top, 16)
            }
            .padding()
        }
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Image preview (if attached)
                if let imgData = pickedImageData, let uiImg = UIImage(data: imgData) {
                    HStack {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        Text(L.chat_bild_angehängt.localized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Button {
                            pickedImageData = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.6))
                                .font(.system(size: 20))
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.8)
                    )
                    .padding(.horizontal, 16)
                }
                
                HStack(spacing: 12) {
                    // Image button (camera/gallery)
                    Button { showImageSourcePicker = true } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                    }
                    .scaleEffect(showImageSourcePicker ? 0.98 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showImageSourcePicker)

                    // Input field
                    ZStack(alignment: .leading) {
                        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(pickedImageData == nil ? L.placeholder_askMe.localized : "Beschreibe, was du mit dem Bild machen möchtest…")
                                .foregroundStyle(.white.opacity(0.5))
                                .font(.system(size: 14))
                        }
                        TextField("", text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .tint(.white)
                            .focused($isInputFocused)
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

                    // Send button
                    Button(action: { Task { if pickedImageData != nil { await sendImage() } else { await sendText() } } }) {
                        Group {
                            if sending { ProgressView().tint(.white) } else { Image(systemName: "paperplane.fill").foregroundStyle(.white) }
                        }
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
            }
            
            // Safe area spacer for home indicator
            Color.clear
                .frame(height: 0)
                .background(.ultraThinMaterial)
        }
    }

    private func sendText() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        
        let userMsg = ChatMessage(role: .user, text: text)
        messages.append(userMsg)
        // Update hidden intent summary for subsequent recipe generation
        let summary = app.summarizeIntent(from: text)
        if !summary.isEmpty { await MainActor.run { app.intentSummary = summary } }
        sending = true
        defer { sending = false }
        do {
            // Enforce rate limit before sending AI request
            guard let token = app.accessToken else {
                throw NSError(domain: "rate_limit", code: -1, userInfo: [NSLocalizedDescriptionKey: L.errorNotLoggedIn.localized])
            }
            // Try to increment AI usage, but don't fail if backend is unreachable
            do { 
                _ = try await app.backend.incrementAIUsage(accessToken: token) 
            } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
                print("[ChatView] Backend unreachable, continuing without usage tracking")
            } catch {
                await MainActor.run { messages.append(.init(role: .assistant, text: error.localizedDescription)) }
                return
            }

            guard let openai = app.openAI else { throw NSError(domain: "no_api", code: 0) }
            let sys = app.chatSystemContext()
            let prefixed = (sys.isEmpty ? [] : [ChatMessage(role: .system, text: sys)]) + messages
            let reply = try await openai.chatReply(messages: prefixed, maxHistory: prefixed.count)
            await MainActor.run { messages.append(.init(role: .assistant, text: reply)) }
        } catch {
            await MainActor.run { messages.append(.init(role: .assistant, text: "Fehler: \(error.localizedDescription)")) }
        }
    }


    private func sendImage() async {
        guard let data = pickedImageData else { return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        
        // Show the user message that includes an image and their prompt
        let b64 = data.base64EncodedString()
        messages.append(.init(role: .user, text: text, imageDataBase64: b64))
        sending = true
        defer {
            pickedImageData = nil
            sending = false
        }
        do {
            // Enforce rate limit before sending AI request
            guard let token = app.accessToken else {
                throw NSError(domain: "rate_limit", code: -1, userInfo: [NSLocalizedDescriptionKey: L.errorNotLoggedIn.localized])
            }
            // Try to increment AI usage, but don't fail if backend is unreachable
            do { 
                _ = try await app.backend.incrementAIUsage(accessToken: token) 
            } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
                print("[ChatView] Backend unreachable, continuing without usage tracking")
            } catch {
                await MainActor.run { messages.append(.init(role: .assistant, text: error.localizedDescription)) }
                return
            }

            guard let openai = app.openAI else { throw NSError(domain: "no_api", code: 0) }
            // First, get a concise ingredient breakdown from the image
            let analysis = try await openai.analyzeImage(data, userPrompt: "Analysiere dieses Bild und liste alle sichtbaren Zutaten/Lebensmittel auf.")
            
            // Build context for chat AI: previous messages (without the current image message)
            var contextMsgs: [ChatMessage] = []
            let sys = app.chatSystemContext()
            if !sys.isEmpty { contextMsgs.append(.init(role: .system, text: sys)) }
            
            // Add previous conversation history (excluding the just-added image message)
            let historyWithoutLastImage = messages.dropLast()
            contextMsgs.append(contentsOf: historyWithoutLastImage)
            
            // Add the image analysis as context
            contextMsgs.append(.init(role: .system, text: L.recipe_imageAnalysisPrefix.localized + analysis + L.recipe_imageAnalysisSuffix.localized))
            
            // Add the user's actual question (without image data, just text)
            contextMsgs.append(.init(role: .user, text: text))
            
            let reply = try await openai.chatReply(messages: contextMsgs, maxHistory: contextMsgs.count)
            await MainActor.run { messages.append(.init(role: .assistant, text: reply)) }
        } catch {
            await MainActor.run { messages.append(.init(role: .assistant, text: "Fehler bei Bildanalyse: \(error.localizedDescription)")) }
        }
    }
}

private struct ChatBubble: View {
    @EnvironmentObject var app: AppState
    let message: ChatMessage
    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 24) }
            VStack(alignment: .leading, spacing: 8) {
                if let b64 = message.imageDataBase64, let data = Data(base64Encoded: b64), let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                // Parse und zeige Rezeptvorschläge
                if !isUser {
                    RecipeSuggestionsView(text: message.text)
                } else {
                    Text(message.text)
                        .foregroundStyle(.white)
                }
            }
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
            if !isUser { Spacer(minLength: 24) }
        }
        .id(message.id)
        .padding(.horizontal, 4)
    }
}

// MARK: - Recipe Suggestions View
private struct RecipeSuggestionsView: View {
    @EnvironmentObject var app: AppState
    let text: String
    @State private var creatingMenu = false
    @State private var createdMenuId: String? = nil
    @State private var createError: String? = nil
    @State private var showGenerationOptions = false
    @State private var selectedRecipe: RecipeSuggestion? = nil
    @State private var generatingAuto = false
    @State private var autoPlan: RecipePlan? = nil
    @State private var showAutoResult = false
    @State private var scrollTarget: String? = nil
    
    var body: some View {
        // Extract classification and strip it from the display text
        let kind = extractKind(from: text)
        let cleanedText = stripKindTag(text)
        let recipes = parseRecipes(from: cleanedText)
        let showMenuButton = shouldShowMenuButton(kind: kind, recipes: recipes, originalText: cleanedText)
        
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 16) {
            // Always show the main content first
            Group {
                if recipes.isEmpty {
                    // Kein Rezeptformat erkannt, normalen Text anzeigen (ohne versteckte Tags)
                    Text(cleanedText)
                        .foregroundStyle(.white)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(recipes.enumerated()), id: \.offset) { _, recipe in
                        VStack(alignment: .leading, spacing: 8) {
                            // Kurs-Label bei Menüs anzeigen (über dem Titel)
                            if (kind?.lowercased() == "menu"), let course = recipe.course {
                                Text(course)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.12), in: Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            }
                            
                            // Rezepttitel
                            Text(recipe.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            // Beschreibung
                            Text(recipe.description)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                            
                            // Einzeln-Button nur anzeigen, wenn NICHT als Menü klassifiziert
                            if (kind?.lowercased() != "menu") {
                                Button(action: {
                                    selectedRecipe = recipe
                                    showGenerationOptions = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "wand.and.stars")
                                        Text(L.chat_erstelle_ein_rezept.localized)
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        in: Capsule()
                                    )
                                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                                    .shadow(color: Color.orange.opacity(0.3), radius: 6, x: 0, y: 3)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        
                        if recipe != recipes.last {
                            Divider()
                                .background(Color.white.opacity(0.2))
                        }
                    }


                    // Menü erstellen Button nur bei Menüs anzeigen
                    if showMenuButton {
                        Button(action: { Task { await createMenu(from: recipes) } }) {
                            HStack(spacing: 6) {
                                if creatingMenu { ProgressView().tint(.white) }
                                Image(systemName: "folder.badge.plus")
                                Text(createdMenuId == nil ? "Menü erstellen" : "Menü erstellt ✓")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ), in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: Color.orange.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(creatingMenu || recipes.isEmpty)
                    }
                        if let err = createError {
                            Text(err).font(.footnote).foregroundStyle(.red)
                        }
                    }
                }
            }
            
                // Show loading state below suggestions when generating automatically
                if generatingAuto {
                    SearchingPenguinView()
                        .frame(maxWidth: .infinity)
                        .id("autoGenerating")
                }
            }
            .onChange(of: scrollTarget) { _, newTarget in
                if let target = newTarget {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut) {
                            proxy.scrollTo(target, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .alert("Rezept erstellen", isPresented: $showGenerationOptions) {
            Button("Benutzerdefiniert") {
                if let recipe = selectedRecipe {
                    app.pendingRecipeGoal = recipe.name
                    app.pendingRecipeDescription = recipe.description
                    if let mid = createdMenuId {
                        app.pendingTargetMenuId = mid
                        app.pendingSuggestionNameToRemove = recipe.name
                    }
                    app.selectedTab = 1
                }
            }
            Button("Automatisch") {
                if let recipe = selectedRecipe {
                    Task { await generateAutomatic(recipeName: recipe.name, recipeDescription: recipe.description) }
                }
            }
            Button(L.cancel.localized, role: .cancel) {}
        } message: {
            Text(L.chat_wähle_wie_das_rezept.localized)
        }
        .sheet(isPresented: $showAutoResult) {
            if let plan = autoPlan {
                RecipeResultView(plan: plan)
            }
        }
    }
    
    // MARK: - Helpers
    private func extractKind(from text: String) -> String? {
        // Matches ⟦kind: menu⟧ or ⟦kind: ideas⟧ (case-insensitive, anywhere)
        let pattern = #"\⟦\s*kind\s*:\s*([^\⟧]+)\⟧"#
        guard let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        if let m = rx.firstMatch(in: text, options: [], range: range), m.numberOfRanges >= 2, let r1 = Range(m.range(at: 1), in: text) {
            return String(text[r1]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        return nil
    }

    private func stripKindTag(_ text: String) -> String {
        let pattern = #"\s*\⟦\s*kind\s*:\s*[^\⟧]+\⟧\s*$"#
        if let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines]) {
            let range = NSRange(location: 0, length: (text as NSString).length)
            return rx.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }


    private func shouldShowMenuButton(kind: String?, recipes: [RecipeSuggestion], originalText: String) -> Bool {
        if kind?.lowercased() == "menu" { return true }
        if kind?.lowercased() == "ideas" { return false }
        // Fallback Heuristik: mindestens 3 Rezepte und >=2 verschiedene Gänge oder 'menü' im Text
        let courses = Set(recipes.compactMap { $0.course?.lowercased() })
        if recipes.count >= 3 && courses.count >= 2 { return true }
        if originalText.lowercased().contains("menü") || originalText.lowercased().contains("menue") { return true }
        return false
    }

    private func parseRecipes(from text: String) -> [RecipeSuggestion] {
        var recipes: [RecipeSuggestion] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentName: String?
        var currentDesc: String = ""
        var currentCourse: String? = nil
        
        let coursePattern = #"\⟦\s*course\s*:\s*([^\⟧]+)\⟧"#
        let courseRegex = try? NSRegularExpression(pattern: coursePattern, options: [.caseInsensitive])
        
        func stripCourseTags(_ s: String) -> (String, String?) {
            guard let rx = courseRegex else { return (s, nil) }
            let ns = s as NSString
            let range = NSRange(location: 0, length: ns.length)
            var found: String? = nil
            var result = s
            if let m = rx.firstMatch(in: s, options: [], range: range) {
                if m.numberOfRanges >= 2, let r1 = Range(m.range(at: 1), in: s) {
                    found = String(s[r1]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if let fullR = Range(m.range(at: 0), in: s) {
                    result.removeSubrange(fullR)
                }
            }
            return (result.trimmingCharacters(in: .whitespaces), found)
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("🍴") {
                // finalize previous
                if let name = currentName, !name.isEmpty {
                    recipes.append(RecipeSuggestion(name: name, description: currentDesc.trimmingCharacters(in: .whitespacesAndNewlines), course: currentCourse))
                }
                // parse new title line with optional course tag
                var nameLine = trimmed.replacingOccurrences(of: "🍴", with: "").trimmingCharacters(in: .whitespaces)
                nameLine = nameLine.replacingOccurrences(of: "**", with: "")
                nameLine = nameLine.replacingOccurrences(of: "*", with: "")
                let (clean, foundCourse) = stripCourseTags(nameLine)
                currentName = clean.trimmingCharacters(in: .whitespaces)
                currentDesc = ""
                currentCourse = foundCourse
            } else if currentName != nil {
                // append description, strip any course tag if present here
                let (clean, foundCourse) = stripCourseTags(trimmed)
                if let c = foundCourse { currentCourse = c }
                currentDesc += (currentDesc.isEmpty ? "" : " ") + clean
            }
        }
        if let name = currentName, !name.isEmpty {
            recipes.append(RecipeSuggestion(name: name, description: currentDesc.trimmingCharacters(in: .whitespacesAndNewlines), course: currentCourse))
        }
        return recipes
    }

    private func guessOccasion(from text: String) -> String? {
        let t = text.lowercased()
        let pairs: [(String, String)] = [
            ("weihnacht", "Weihnachten"), ("weihnacht", "Weihnachten"), ("silvester", "Silvester"), ("oster", "Ostern"),
            ("geburtstag", "Geburtstag"), ("valentin", "Valentinstag"), ("frühl", "Frühling"), ("fruehl", "Frühling"), ("sommer", "Sommer"), ("herbst", "Herbst"), ("winter", "Winter"), ("grill", "Grillabend"), ("halloween", "Halloween"), ("muttertag", "Muttertag")
        ]
        return pairs.first(where: { t.contains($0.0) })?.1
    }

    private func createMenu(from suggestions: [RecipeSuggestion]) async {
        guard !suggestions.isEmpty else { return }
        creatingMenu = true
        createError = nil
        defer { creatingMenu = false }
        guard let token = app.accessToken, let userId = KeychainManager.get(key: "user_id") else {
            createError = L.errorNotLoggedIn.localized
            return
        }
        do {
            // Generate a name
            let titles = suggestions.map { $0.name }
            var title = "KI-Menü"
            if let openai = app.openAI {
                let occ = guessOccasion(from: text)
                if let named = try? await openai.generateMenuName(occasion: occ, courseTitles: titles) { title = named }
            } else {
                // Fallback heuristic
                if let occ = guessOccasion(from: text) { title = "\(occ) Menü" }
                else if let main = titles.first { title = "Menü: \(main)" }
            }
            // Create menu in Supabase
            let menu = try await app.createMenu(title: title, accessToken: token, userId: userId)
            // Persist suggestions as placeholders (validate and normalize course tags)
            let placeholders = suggestions.map { s in 
                let validatedCourse = validateCourse(s.course) ?? app.guessCourse(name: s.name, description: s.description)
                return AppState.MenuSuggestion(name: s.name, description: s.description, course: validatedCourse)
            }
            app.addMenuSuggestions(placeholders, to: menu.id)
            // Navigate to Meine Rezepte and preselect the new menu
            await MainActor.run {
                self.createdMenuId = menu.id
                app.lastCreatedMenu = menu
                app.pendingSelectMenuId = menu.id
                app.selectedTab = 2
            }
            // Start auto-generation of all recipes in the background
            Task { await app.autoGenerateRecipesForMenu(menu: menu, suggestions: placeholders) }
        } catch {
            await MainActor.run { createError = error.localizedDescription }
        }
    }
    
    // Validate and normalize course labels from AI
    private func validateCourse(_ course: String?) -> String? {
        guard let c = course?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        let normalized = c.lowercased()
        
        // Valid courses as defined in system prompt
        let validCourses: [String: String] = [
            "vorspeise": "Vorspeise",
            "zwischengang": "Zwischengang",
            "hauptspeise": "Hauptspeise",
            "hauptgang": "Hauptspeise",
            "nachspeise": "Nachspeise",
            "dessert": "Nachspeise",
            "beilage": "Beilage",
            "getränk": "Getränk",
            "getraenk": "Getränk",
            "amuse-bouche": "Amuse-Bouche",
            "aperitif": "Aperitif",
            "digestif": "Digestif",
            "käsegang": "Käsegang",
            "kaesegang": "Käsegang"
        ]
        
        return validCourses[normalized]
    }
    
    // Generate recipe automatically with essential preferences only
    private func generateAutomatic(recipeName: String, recipeDescription: String) async {
        await MainActor.run {
            generatingAuto = true
            scrollTarget = "autoGenerating"
        }
        defer { 
            Task { @MainActor in
                generatingAuto = false
                scrollTarget = nil
            }
        }
        
        // Enforce rate limit
        guard let token = app.accessToken else { return }
        // Try to increment AI usage, but don't fail if backend is unreachable
        do { 
            _ = try await app.backend.incrementAIUsage(accessToken: token) 
        } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
            print("[ChatView] Backend unreachable, continuing without usage tracking")
        } catch {
            await MainActor.run { createError = error.localizedDescription }
            return
        }
        
        guard let openai = app.openAI else { return }
        
        // Build essential dietary context: allergies, intolerances, and important diets only
        var essentialParts: [String] = []
        
        // ALWAYS include allergies and intolerances
        if !app.dietary.allergies.isEmpty {
            essentialParts.append("Allergien/Unverträglichkeiten: " + app.dietary.allergies.joined(separator: ", "))
        }
        
        // Include ONLY important dietary preferences (halal, vegan, vegetarian, etc.)
        let importantDiets = ["halal", "vegan", "vegetarisch", "pescetarisch", "koscher"]
        let userImportantDiets = app.dietary.diets.filter { importantDiets.contains($0.lowercased()) }
        if !userImportantDiets.isEmpty {
            essentialParts.append("Ernährungsweisen: " + userImportantDiets.sorted().joined(separator: ", "))
        }
        
        let essentialContext = essentialParts.isEmpty ? "" : "Berücksichtige strikt folgende Nutzerpräferenzen bei diesem Rezept. Ersetze verbotene Zutaten durch passende Alternativen. " + essentialParts.joined(separator: " | ")
        let languageContext = app.languageSystemPrompt()
        let fullContext = [essentialContext, languageContext].filter { !$0.isEmpty }.joined(separator: "\n")
        
        // Combine recipe name with description for better context
        let recipeGoal = recipeDescription.isEmpty ? recipeName : "\(recipeName): \(recipeDescription)"
        
        do {
            let plan = try await openai.generateRecipePlan(
                goal: recipeGoal,
                timeMinutesMin: nil,
                timeMinutesMax: nil,
                nutrition: NutritionConstraint(
                    calories_min: nil, calories_max: nil,
                    protein_min_g: nil, protein_max_g: nil,
                    fat_min_g: nil, fat_max_g: nil,
                    carbs_min_g: nil, carbs_max_g: nil
                ),
                categories: Array(userImportantDiets),
                servings: 4,
                dietaryContext: fullContext
            )
            await MainActor.run {
                // Store menu info if this came from a menu suggestion
                if let mid = createdMenuId {
                    app.pendingTargetMenuId = mid
                    app.pendingSuggestionNameToRemove = recipeName
                }
                self.autoPlan = plan
                self.showAutoResult = true
            }
        } catch {
            await MainActor.run { createError = error.localizedDescription }
        }
    }
}

private struct RecipeSuggestion: Equatable {
    let name: String
    let description: String
    let course: String?
}

// MARK: - Searching Penguin View
private struct SearchingPenguinView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                // Suchender Pinguin
                if let bundlePath = Bundle.main.path(forResource: "penguin-searching", ofType: "png", inDirectory: "Assets.xcassets/penguin-searching.imageset"),
                   let uiImage = UIImage(contentsOfFile: bundlePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isAnimating ? 12 : 8)
                        .offset(y: isAnimating ? -8 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                } else if let uiImage = UIImage(named: "penguin-searching") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isAnimating ? 12 : 8)
                        .offset(y: isAnimating ? -8 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                } else {
                    // Fallback: Lupe Emoji
                    Text("🔍")
                        .font(.system(size: 60))
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isAnimating ? 12 : 8)
                        .offset(y: isAnimating ? -8 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                // Text mit animierten Punkten
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text(L.chat_ich_suche_nach_einem.localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        // Animierte Punkte
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Text(".")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .opacity(isAnimating ? 0.3 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.8)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                        value: isAnimating
                                    )
                            }
                        }
                    }
                    
                    Text(L.chat_das_perfekte_rezept_ist.localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Thinking Penguin View (shared)
struct CulinaThinkingPenguinView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Nachdenkender Pinguin - Links
            if let bundlePath = Bundle.main.path(forResource: "penguin-thinking", ofType: "png", inDirectory: "Assets.xcassets/penguin-thinking.imageset"),
               let uiImage = UIImage(contentsOfFile: bundlePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .opacity(isAnimating ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
            } else if let uiImage = UIImage(named: "penguin-thinking") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .opacity(isAnimating ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
            } else {
                // Fallback: thinking emoji
                Text("🤔")
                    .font(.system(size: 35))
                    .opacity(isAnimating ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            // Animierte Punkte
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 8, height: 8)
                        .opacity(isAnimating ? 0.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Rectangle().fill(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 6)
            
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 4)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    @State private var isFloating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                // Pinguin Illustration - schwebend
                if let bundlePath = Bundle.main.path(forResource: "penguin-chef", ofType: "png", inDirectory: "Assets.xcassets/penguin-chef.imageset"),
                   let uiImage = UIImage(contentsOfFile: bundlePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isFloating ? 12 : 8)
                        .offset(y: isFloating ? -8 : 0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isFloating)
                } else if let uiImage = UIImage(named: "penguin-chef") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isFloating ? 12 : 8)
                        .offset(y: isFloating ? -8 : 0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isFloating)
                } else {
                    // Fallback: Pinguin Emoji
                    Text("🐧")
                        .font(.system(size: 80))
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isFloating ? 12 : 8)
                        .offset(y: isFloating ? -8 : 0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isFloating)
                }
                
                // Text unter dem Pinguin
                VStack(spacing: 8) {
                    Text(L.chat_frage_mich_alles_übers.localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(L.chat_rezepte_zutaten_tipps_tricks.localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            isFloating = true
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType = .camera
    var onPicked: (Data) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        if isPresented {
            // no-op; presentation is handled by SwiftUI
        } else {
            uiViewController.dismiss(animated: true)
        }
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.isPresented = false
            if let img = info[.originalImage] as? UIImage, let data = img.jpegData(compressionQuality: 0.85) {
                parent.onPicked(data)
            }
        }
    }
}