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
    @State private var showConsentDialog = false
    @State private var showRevokeConsentAlert = false
    @State private var hasConsent: Bool = OpenAIConsentManager.hasConsent

    var body: some View {
        chatContent
            .id(localizationManager.currentLanguage)
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
                                ChatBubble(message: msg, onRetry: retryLastMessage)
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
                .onChange(of: messages.count) { _, _ in
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
                
                // Dezent consent status indicator über dem Input-Bar (nur wenn Consent erteilt)
                if hasConsent {
                    HStack {
                        Spacer()
                        consentStatusIndicator
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                    }
                }
                
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
        .sheet(isPresented: $showConsentDialog) {
            OpenAIConsentDialog(
                onAccept: {
                    OpenAIConsentManager.hasConsent = true
                    hasConsent = true
                    // Continue with the last action
                },
                onDecline: {
                    // User declined, show message
                    messages.append(.init(role: .assistant, text: L.consent_required.localized))
                }
            )
        }
        .alert(
            L.settings_revoke_consent_confirm.localized,
            isPresented: $showRevokeConsentAlert
        ) {
            Button(L.settings_revoke_consent.localized, role: .destructive) {
                OpenAIConsentManager.resetConsent()
                hasConsent = false
                // Show confirmation message
                messages.append(.init(role: .assistant, text: L.consent_revoked.localized))
            }
            Button(L.cancel.localized, role: .cancel) {}
        } message: {
            Text(L.settings_revoke_consent_message.localized)
        }
        .onReceive(NotificationCenter.default.publisher(for: OpenAIConsentManager.consentChangedNotification)) { notification in
            // Update local state when consent changes
            if let newValue = notification.userInfo?["hasConsent"] as? Bool {
                hasConsent = newValue
            } else {
                hasConsent = OpenAIConsentManager.hasConsent
            }
        }
        .onAppear {
            // Initialize state
            hasConsent = OpenAIConsentManager.hasConsent
        }
    }
    
    // Dezent consent status indicator mit Opt-Out - Floating über Input-Bar
    private var consentStatusIndicator: some View {
        Button {
            showRevokeConsentAlert = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 12, weight: .medium))
                Text(L.chat_consent_active.localized)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel(L.chat_consent_active.localized)
        .accessibilityHint(L.chat_revoke_consent_hint.localized)
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                imagePreviewView
                inputContainerView
            }
            
            // Safe area spacer for home indicator
            Color.clear
                .frame(height: 0)
                .background(.ultraThinMaterial)
        }
    }
    
    @ViewBuilder
    private var imagePreviewView: some View {
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
                .accessibilityLabel(L.a11y_removeImage.localized)
                .accessibilityHint(L.a11y_removeAttachedImage.localized)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            )
            .padding(.horizontal, 16)
        }
    }
    
    private var inputContainerView: some View {
        HStack(spacing: 12) {
            imageButtonView
            inputFieldView
            sendButtonView
        }
        .padding(10)
        .background(inputContainerBackground)
        .padding(.horizontal, 16)
    }
    
    private var imageButtonView: some View {
        Button { showImageSourcePicker = true } label: {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
        }
        .accessibilityLabel(L.common_chooseImage.localized)
        .accessibilityHint(L.chat_bild_angehängt.localized)
        .scaleEffect(showImageSourcePicker ? 0.98 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showImageSourcePicker)
    }
    
    private var inputFieldView: some View {
        ZStack(alignment: .leading) {
            if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(pickedImageData == nil ? L.placeholder_askMe.localized : L.chat_frage_mich_alles_übers.localized)
                    .foregroundStyle(.white.opacity(0.5))
                    .font(.system(size: 14))
            }
            TextField("", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .tint(.white)
                .focused($isInputFocused)
                .accessibilityLabel(L.placeholder_askMe.localized)
                .accessibilityHint(L.chat_frage_mich_alles_übers.localized)
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
    }
    
    private var sendButtonView: some View {
        Button(action: { Task { if pickedImageData != nil { await sendImage() } else { await sendText() } } }) {
            Group {
                if sending { 
                    ProgressView().tint(.white) 
                } else { 
                    Image(systemName: "paperplane.fill").foregroundStyle(.white) 
                }
            }
            .frame(width: 42, height: 42)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], 
                    startPoint: .topLeading, 
                    endPoint: .bottomTrailing
                ), 
                in: Circle()
            )
            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .shadow(color: Color.orange.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .accessibilityLabel(sending ? L.loading.localized : L.sendMessage.localized)
        .accessibilityHint(L.sendMessage.localized)
        .disabled(sending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    private var inputContainerBackground: some View {
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
    }

    private func sendText() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            messages.append(.init(role: .assistant, text: L.errorJailbreakDetected.localized))
            return
        }
        
        guard await app.ensureAIAccess(for: .aiChat) else { return }
        
        // Check DSGVO consent before using OpenAI
        guard hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
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
            
            // Get original transaction ID for transaction-based rate limiting (if user has subscription)
            let transactionId = await app.getOriginalTransactionId()
            
            // Try to increment AI usage, but don't fail if backend is unreachable
            do { 
                _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: transactionId) 
            } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
                Logger.info("[ChatView] Backend unreachable, continuing without usage tracking", category: .network)
            } catch {
                if app.handleAISubscriptionDenied(error) { return }
                await MainActor.run { 
                    messages.append(.init(role: .assistant, text: ErrorMessageHelper.userFriendlyMessage(from: error), isError: true))
                }
                return
            }

            guard let openai = app.openAI else { throw NSError(domain: "no_api", code: 0) }
            let sys = app.chatSystemContext()
            let prefixed = (sys.isEmpty ? [] : [ChatMessage(role: .system, text: sys)]) + messages
            let reply = try await openai.chatReply(messages: prefixed, maxHistory: prefixed.count)
            await MainActor.run { messages.append(.init(role: .assistant, text: reply)) }
        } catch {
            if app.handleAISubscriptionDenied(error) { return }
            await MainActor.run { 
                let errorMsg = error.localizedDescription.contains("cannotFindHost") || error.localizedDescription.contains("cannotConnectToHost") 
                    ? L.errorNetworkConnection.localized 
                    : L.errorChatError.localized
                messages.append(.init(role: .assistant, text: errorMsg, isError: true))
            }
        }
    }


    private func sendImage() async {
        guard let data = pickedImageData else { return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            messages.append(.init(role: .assistant, text: L.errorJailbreakDetected.localized))
            pickedImageData = nil
            return
        }
        
        guard await app.ensureAIAccess(for: .aiChat) else { return }
        
        // Check DSGVO consent before using OpenAI
        guard hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
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
            
            // Get original transaction ID for transaction-based rate limiting (if user has subscription)
            let transactionId = await app.getOriginalTransactionId()
            
            // Try to increment AI usage, but don't fail if backend is unreachable
            do { 
                _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: transactionId) 
            } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
                Logger.info("[ChatView] Backend unreachable, continuing without usage tracking", category: .network)
            } catch {
                if app.handleAISubscriptionDenied(error) { return }
                await MainActor.run { 
                    messages.append(.init(role: .assistant, text: ErrorMessageHelper.userFriendlyMessage(from: error), isError: true))
                }
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
            if app.handleAISubscriptionDenied(error) { return }
            await MainActor.run { messages.append(.init(role: .assistant, text: L.errorImageAnalysisError.localized, isError: true)) }
        }
    }
    
    // Retry sending the last user message after an error
    private func retryLastMessage() {
        // Find the last user message before the error
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }
        
        // Remove the error message if it exists
        if let lastMessage = messages.last, lastMessage.isError {
            messages.removeLast()
        }
        
        // Retry sending: if it had an image, use sendImage, otherwise sendText
        if lastUserMessage.imageDataBase64 != nil {
            // Restore image data and text for retry
            if let imageData = Data(base64Encoded: lastUserMessage.imageDataBase64 ?? "") {
                Task {
                    await retrySendImage(text: lastUserMessage.text, imageData: imageData)
                }
            }
        } else {
            Task {
                await retrySendText(text: lastUserMessage.text)
            }
        }
    }
    
    // Retry send text without clearing input field
    private func retrySendText(text: String) async {
        guard !text.isEmpty else { return }
        
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            messages.append(.init(role: .assistant, text: L.errorJailbreakDetected.localized))
            return
        }
        
        guard await app.ensureAIAccess(for: .aiChat) else { return }
        
        // Check DSGVO consent before using OpenAI
        guard hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
        
        // Don't add user message again - it's already in the list
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
            
            // Get original transaction ID for transaction-based rate limiting (if user has subscription)
            let transactionId = await app.getOriginalTransactionId()
            
            // Try to increment AI usage, but don't fail if backend is unreachable
            do { 
                _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: transactionId) 
            } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
                Logger.info("[ChatView] Backend unreachable, continuing without usage tracking", category: .network)
            } catch {
                if app.handleAISubscriptionDenied(error) { return }
                await MainActor.run { 
                    messages.append(.init(role: .assistant, text: ErrorMessageHelper.userFriendlyMessage(from: error), isError: true))
                }
                return
            }

            guard let openai = app.openAI else { throw NSError(domain: "no_api", code: 0) }
            let sys = app.chatSystemContext()
            let prefixed = (sys.isEmpty ? [] : [ChatMessage(role: .system, text: sys)]) + messages
            let reply = try await openai.chatReply(messages: prefixed, maxHistory: prefixed.count)
            await MainActor.run { messages.append(.init(role: .assistant, text: reply)) }
        } catch {
            if app.handleAISubscriptionDenied(error) { return }
            await MainActor.run { 
                let errorMsg = error.localizedDescription.contains("cannotFindHost") || error.localizedDescription.contains("cannotConnectToHost") 
                    ? L.errorNetworkConnection.localized 
                    : L.errorChatError.localized
                messages.append(.init(role: .assistant, text: errorMsg, isError: true))
            }
        }
    }
    
    // Retry send image without clearing input field
    private func retrySendImage(text: String, imageData: Data) async {
        guard !text.isEmpty else { return }
        
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            messages.append(.init(role: .assistant, text: L.errorJailbreakDetected.localized))
            return
        }
        
        guard await app.ensureAIAccess(for: .aiChat) else { return }
        
        // Check DSGVO consent before using OpenAI
        guard hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
        
        // Don't add user message again - it's already in the list
        sending = true
        defer { sending = false }
        do {
            // Enforce rate limit before sending AI request
            guard let token = app.accessToken else {
                throw NSError(domain: "rate_limit", code: -1, userInfo: [NSLocalizedDescriptionKey: L.errorNotLoggedIn.localized])
            }
            
            // Get original transaction ID for transaction-based rate limiting (if user has subscription)
            let transactionId = await app.getOriginalTransactionId()
            
            // Try to increment AI usage, but don't fail if backend is unreachable
            do { 
                _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: transactionId) 
            } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
                Logger.info("[ChatView] Backend unreachable, continuing without usage tracking", category: .network)
            } catch {
                if app.handleAISubscriptionDenied(error) { return }
                await MainActor.run { 
                    messages.append(.init(role: .assistant, text: ErrorMessageHelper.userFriendlyMessage(from: error), isError: true))
                }
                return
            }

            guard let openai = app.openAI else { throw NSError(domain: "no_api", code: 0) }
            // First, get a concise ingredient breakdown from the image
            let analysis = try await openai.analyzeImage(imageData, userPrompt: "Analysiere dieses Bild und liste alle sichtbaren Zutaten/Lebensmittel auf.")
            
            // Build context for chat AI: previous messages (without the current image message)
            var contextMsgs: [ChatMessage] = []
            let sys = app.chatSystemContext()
            if !sys.isEmpty { contextMsgs.append(.init(role: .system, text: sys)) }
            
            // Add previous conversation history (excluding the last image message which is already in the list)
            // Find the last user message with image and exclude it from history
            let historyWithoutLastImage = messages.filter { msg in
                if msg.role == .user && msg.imageDataBase64 != nil {
                    // This is likely the message we're retrying, exclude it
                    return false
                }
                return true
            }
            contextMsgs.append(contentsOf: historyWithoutLastImage)
            
            // Add the image analysis as context
            contextMsgs.append(.init(role: .system, text: L.recipe_imageAnalysisPrefix.localized + analysis + L.recipe_imageAnalysisSuffix.localized))
            
            // Add the user's actual question (without image data, just text)
            contextMsgs.append(.init(role: .user, text: text))
            
            let reply = try await openai.chatReply(messages: contextMsgs, maxHistory: contextMsgs.count)
            await MainActor.run { messages.append(.init(role: .assistant, text: reply)) }
        } catch {
            if app.handleAISubscriptionDenied(error) { return }
            await MainActor.run { messages.append(.init(role: .assistant, text: L.errorImageAnalysisError.localized, isError: true)) }
        }
    }
}

private struct ChatBubble: View {
    @EnvironmentObject var app: AppState
    let message: ChatMessage
    let onRetry: () -> Void
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
                
                // Retry-Button bei Fehlermeldungen
                if message.isError && !isUser {
                    Button(action: onRetry) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text(L.ui_wiederholen.localized)
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
                    .accessibilityLabel(L.ui_wiederholen.localized)
                    .accessibilityHint(L.a11y_retryLastMessage.localized)
                    .padding(.top, 4)
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
                    // Bei Menüs: Nach Gängen gruppieren und strukturiert anzeigen
                    if (kind?.lowercased() == "menu") {
                        let groupedRecipes = groupRecipesByCourse(recipes)
                        let orderedCourses = orderCourses(Set(groupedRecipes.keys))
                        
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(orderedCourses, id: \.self) { course in
                                if let courseRecipes = groupedRecipes[course] {
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Gang-Name (in der jeweiligen Sprache)
                                        Text(course)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        
                                        // Rezepte dieses Gangs
                                        ForEach(Array(courseRecipes.enumerated()), id: \.offset) { idx, recipe in
                                            VStack(alignment: .leading, spacing: 6) {
                                                // Rezepttitel
                                                Text(recipe.name)
                                                    .font(.headline)
                                                    .foregroundStyle(.white)
                                                
                                                // Beschreibung
                                                if !recipe.description.isEmpty {
                                                    Text(recipe.description)
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white.opacity(0.85))
                                                }
                                            }
                                            .padding(.vertical, 8)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    
                                    // Weiße Linie zwischen den Gängen
                                    if course != orderedCourses.last {
                                        Divider()
                                            .background(Color.white)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                    } else {
                        // Normale Rezept-Vorschläge (nicht als Menü)
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(recipes.enumerated()), id: \.offset) { _, recipe in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Rezepttitel
                                    Text(recipe.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    
                                    // Beschreibung
                                    Text(recipe.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.85))
                                    
                                    // Einzeln-Button
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
                                    .accessibilityLabel(L.chat_erstelle_ein_rezept.localized)
                                    .accessibilityHint(L.a11y_createRecipeFor.localized(replacing: ["name": recipe.name]))
                                }
                                .padding(.vertical, 6)
                                
                                if recipe != recipes.last {
                                    Divider()
                                        .background(Color.white.opacity(0.2))
                                }
                            }
                        }
                    }


                    // Menü erstellen Button nur bei Menüs anzeigen - GANZ UNTEN
                    if showMenuButton {
                        VStack(spacing: 8) {
                            Button(action: { Task { await createMenu(from: recipes) } }) {
                                HStack(spacing: 6) {
                                    if creatingMenu { ProgressView().tint(.white) }
                                    Image(systemName: "folder.badge.plus")
                                    Text(createdMenuId == nil ? L.a11y_createMenu.localized : L.a11y_menuCreated.localized)
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
                            .accessibilityLabel(createdMenuId == nil ? L.a11y_createMenu.localized : L.a11y_menuCreated.localized)
                            .accessibilityHint(creatingMenu ? L.a11y_creatingMenu.localized : L.a11y_createMenuFromRecipes.localized)
                            .buttonStyle(.plain)
                            .disabled(creatingMenu || recipes.isEmpty)
                            
                            if let err = createError {
                                Text(err).font(.footnote).foregroundStyle(.red)
                            }
                        }
                        .padding(.top, 16)
                    } else {
                        if let err = createError {
                            Text(err).font(.footnote).foregroundStyle(.red)
                                .padding(.top, 8)
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
        .alert(L.nav_createRecipe.localized, isPresented: $showGenerationOptions) {
            Button(L.recipesCreateOwn.localized) {
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
            Button(L.generateRecipe.localized) {
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
                let nameLine = trimmed.replacingOccurrences(of: "🍴", with: "").trimmingCharacters(in: .whitespaces)
                
                // Extract course tag first (before processing name/description)
                let (lineWithoutCourse, foundCourse) = stripCourseTags(nameLine)
                currentCourse = foundCourse
                
                // Try to extract name from **bold** format
                var extractedName: String? = nil
                var remainingText: String? = nil
                
                // Pattern: **Name** description or **Name**⟦course:...⟧ description
                let boldPattern = #"\*\*([^*]+)\*\*"#
                if let boldRegex = try? NSRegularExpression(pattern: boldPattern, options: []),
                   let match = boldRegex.firstMatch(in: lineWithoutCourse, options: [], range: NSRange(location: 0, length: lineWithoutCourse.utf16.count)),
                   match.numberOfRanges >= 2,
                   let nameRange = Range(match.range(at: 1), in: lineWithoutCourse) {
                    extractedName = String(lineWithoutCourse[nameRange]).trimmingCharacters(in: .whitespaces)
                    // Get text after the closing **
                    let afterBoldRange = NSRange(location: match.range.upperBound, length: lineWithoutCourse.utf16.count - match.range.upperBound)
                    if afterBoldRange.length > 0,
                       let afterBold = Range(afterBoldRange, in: lineWithoutCourse) {
                        let afterText = String(lineWithoutCourse[afterBold]).trimmingCharacters(in: .whitespaces)
                        if !afterText.isEmpty {
                            remainingText = afterText
                        }
                    }
                }
                
                // Fallback: if no bold format, use entire line as name (strip course tag already done)
                if extractedName == nil || extractedName!.isEmpty {
                    // Remove any remaining markdown
                    var clean = lineWithoutCourse.replacingOccurrences(of: "**", with: "")
                    clean = clean.replacingOccurrences(of: "*", with: "")
                    extractedName = clean.trimmingCharacters(in: .whitespaces)
                }
                
                currentName = extractedName?.trimmingCharacters(in: .whitespaces) ?? ""
                // If there's remaining text on the same line, use it as description start
                currentDesc = remainingText?.trimmingCharacters(in: .whitespaces) ?? ""
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
    
    // Gruppiert Rezepte nach Gängen
    private func groupRecipesByCourse(_ recipes: [RecipeSuggestion]) -> [String: [RecipeSuggestion]] {
        var grouped: [String: [RecipeSuggestion]] = [:]
        let defaultCourse = "Hauptspeise" // Fallback für Rezepte ohne Gang
        
        for recipe in recipes {
            let course = recipe.course ?? defaultCourse
            if grouped[course] == nil {
                grouped[course] = []
            }
            grouped[course]?.append(recipe)
        }
        
        return grouped
    }
    
    // Sortiert Gänge in der richtigen Reihenfolge (unterstützt alle Sprachen)
    private func orderCourses(_ courses: Set<String>) -> [String] {
        // Normalisiere Gang-Namen zu kanonischen deutschen Namen für Sortierung
        func normalizeCourse(_ course: String) -> String {
            let normalized = course.lowercased()
            let mapping: [String: String] = [
                // German
                "vorspeise": "Vorspeise",
                "zwischengang": "Zwischengang",
                "hauptspeise": "Hauptspeise",
                "hauptgang": "Hauptspeise",
                "nachspeise": "Nachspeise",
                "dessert": "Nachspeise",
                "beilage": "Beilage",
                "suppengang": "Suppengang",
                "suppe": "Suppengang",
                "getränk": "Getränk",
                "getraenk": "Getränk",
                "amuse-bouche": "Amuse-Bouche",
                "aperitif": "Aperitif",
                "digestif": "Digestif",
                "käsegang": "Käsegang",
                "kaesegang": "Käsegang",
                // English
                "appetizer": "Vorspeise",
                "soup course": "Suppengang",
                "soup": "Suppengang",
                "intermediate course": "Zwischengang",
                "main course": "Hauptspeise",
                "main": "Hauptspeise",
                "side dish": "Beilage",
                "side": "Beilage",
                "cheese course": "Käsegang",
                "cheese": "Käsegang",
                "beverage": "Getränk",
                "drink": "Getränk",
                // Spanish
                "sopa": "Suppengang",
                "plato intermedio": "Zwischengang",
                "plato principal": "Hauptspeise",
                "principal": "Hauptspeise",
                "postre": "Nachspeise",
                "guarnición": "Beilage",
                "guarnicion": "Beilage",
                "quesos": "Käsegang",
                "queso": "Käsegang",
                "aperitivo": "Aperitif",
                "digestivo": "Digestif",
                "bebida": "Getränk",
                // French
                "entrée": "Vorspeise",
                "entree": "Vorspeise",
                "potage": "Suppengang",
                "plat intermédiaire": "Zwischengang",
                "plat intermediaire": "Zwischengang",
                "plat principal": "Hauptspeise",
                "accompagnement": "Beilage",
                "fromages": "Käsegang",
                "fromage": "Käsegang",
                "apéritif": "Aperitif",
                "boisson": "Getränk",
                // Italian
                "antipasto": "Vorspeise",
                "primo": "Suppengang",
                "piatto intermedio": "Zwischengang",
                "secondo": "Hauptspeise",
                "dolce": "Nachspeise",
                "contorno": "Beilage",
                "formaggi": "Käsegang",
                "formaggio": "Käsegang",
                "bevanda": "Getränk"
            ]
            return mapping[normalized] ?? course
        }
        
        // Definiere Reihenfolge basierend auf kanonischen deutschen Namen
        let courseOrder: [String] = [
            "Amuse-Bouche",
            "Aperitif",
            "Vorspeise",
            "Suppengang",
            "Zwischengang",
            "Hauptspeise",
            "Beilage",
            "Käsegang",
            "Nachspeise",
            "Digestif",
            "Getränk"
        ]
        
        // Sortiere nach definierter Reihenfolge, dann alphabetisch für nicht-definierte Gänge
        return courses.sorted { course1, course2 in
            let normalized1 = normalizeCourse(course1)
            let normalized2 = normalizeCourse(course2)
            
            let index1 = courseOrder.firstIndex(of: normalized1) ?? Int.max
            let index2 = courseOrder.firstIndex(of: normalized2) ?? Int.max
            
            if index1 != index2 {
                return index1 < index2
            }
            // Wenn beide nicht in der Liste sind, alphabetisch sortieren
            return course1 < course2
        }
    }
    
    // Gibt die Beschreibung für jeden Gang zurück (unterstützt alle Sprachen)
    private func courseDescription(_ course: String) -> String {
        // Normalisiere zu kanonischem Namen für Beschreibung
        func normalizeForDescription(_ course: String) -> String {
            let normalized = course.lowercased()
            let mapping: [String: String] = [
                // German
                "vorspeise": "Vorspeise",
                "zwischengang": "Zwischengang",
                "hauptspeise": "Hauptspeise",
                "hauptgang": "Hauptspeise",
                "nachspeise": "Nachspeise",
                "dessert": "Nachspeise",
                "beilage": "Beilage",
                "suppengang": "Suppengang",
                "suppe": "Suppengang",
                "getränk": "Getränk",
                "getraenk": "Getränk",
                "amuse-bouche": "Amuse-Bouche",
                "aperitif": "Aperitif",
                "digestif": "Digestif",
                "käsegang": "Käsegang",
                "kaesegang": "Käsegang",
                // English
                "appetizer": "Vorspeise",
                "soup course": "Suppengang",
                "soup": "Suppengang",
                "intermediate course": "Zwischengang",
                "main course": "Hauptspeise",
                "main": "Hauptspeise",
                "side dish": "Beilage",
                "side": "Beilage",
                "cheese course": "Käsegang",
                "cheese": "Käsegang",
                "beverage": "Getränk",
                "drink": "Getränk",
                // Spanish
                "sopa": "Suppengang",
                "plato intermedio": "Zwischengang",
                "plato principal": "Hauptspeise",
                "principal": "Hauptspeise",
                "postre": "Nachspeise",
                "guarnición": "Beilage",
                "guarnicion": "Beilage",
                "quesos": "Käsegang",
                "queso": "Käsegang",
                "aperitivo": "Aperitif",
                "digestivo": "Digestif",
                "bebida": "Getränk",
                // French
                "entrée": "Vorspeise",
                "entree": "Vorspeise",
                "potage": "Suppengang",
                "plat intermédiaire": "Zwischengang",
                "plat intermediaire": "Zwischengang",
                "plat principal": "Hauptspeise",
                "accompagnement": "Beilage",
                "fromages": "Käsegang",
                "fromage": "Käsegang",
                "apéritif": "Aperitif",
                "boisson": "Getränk",
                // Italian
                "antipasto": "Vorspeise",
                "primo": "Suppengang",
                "piatto intermedio": "Zwischengang",
                "secondo": "Hauptspeise",
                "dolce": "Nachspeise",
                "contorno": "Beilage",
                "formaggi": "Käsegang",
                "formaggio": "Käsegang",
                "bevanda": "Getränk"
            ]
            return mapping[normalized] ?? course
        }
        
        let normalizedCourse = normalizeForDescription(course)
        let descriptions: [String: String] = [
            "Amuse-Bouche": "Kleine Gaumenfreude zum Auftakt",
            "Aperitif": "Aperitif zum Anstoßen",
            "Vorspeise": "Leichte Speisen zum Auftakt",
            "Suppengang": "Warme Suppe zwischen den Gängen",
            "Zwischengang": "Kleiner Gang zwischen Hauptgängen",
            "Hauptspeise": "Das Hauptgericht des Menüs",
            "Beilage": "Beilagen zum Hauptgericht",
            "Käsegang": "Ausgewählte Käsesorten",
            "Nachspeise": "Süßer Abschluss des Menüs",
            "Digestif": "Digestif zum Ausklingen",
            "Getränk": "Getränke zum Menü"
        ]
        
        return descriptions[normalizedCourse] ?? "Köstlicher Gang"
    }

    private func createMenu(from suggestions: [RecipeSuggestion]) async {
        guard !suggestions.isEmpty else { return }
        
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            createError = L.errorJailbreakDetected.localized
            return
        }
        
        guard await app.ensureAIAccess(for: .aiRecipeGenerator) else { return }
        
        // Check DSGVO consent before using OpenAI
        guard OpenAIConsentManager.hasConsent else {
            await MainActor.run {
                createError = L.consent_required.localized
            }
            return
        }
        
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
            if app.handleAISubscriptionDenied(error) { return }
            await MainActor.run { 
                createError = ErrorMessageHelper.userFriendlyMessage(from: error)
            }
        }
    }
    
    // Validate and normalize course labels from AI (supports all languages)
    // Normalizes course names from different languages to a canonical form for display
    private func validateCourse(_ course: String?) -> String? {
        guard let c = course?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        let normalized = c.lowercased()
        
        // Map course names from all languages to canonical German names for consistency
        // The UI will display them as received, but we normalize for internal processing
        let validCourses: [String: String] = [
            // German
            "vorspeise": "Vorspeise",
            "zwischengang": "Zwischengang",
            "hauptspeise": "Hauptspeise",
            "hauptgang": "Hauptspeise",
            "nachspeise": "Nachspeise",
            "dessert": "Nachspeise",
            "beilage": "Beilage",
            "suppengang": "Suppengang",
            "suppe": "Suppengang",
            "getränk": "Getränk",
            "getraenk": "Getränk",
            "amuse-bouche": "Amuse-Bouche",
            "aperitif": "Aperitif",
            "digestif": "Digestif",
            "käsegang": "Käsegang",
            "kaesegang": "Käsegang",
            // English
            "appetizer": "Vorspeise",
            "soup course": "Suppengang",
            "soup": "Suppengang",
            "intermediate course": "Zwischengang",
            "main course": "Hauptspeise",
            "main": "Hauptspeise",
            "side dish": "Beilage",
            "side": "Beilage",
            "cheese course": "Käsegang",
            "cheese": "Käsegang",
            "beverage": "Getränk",
            "drink": "Getränk",
            // Spanish
            "sopa": "Suppengang",
            "plato intermedio": "Zwischengang",
            "plato principal": "Hauptspeise",
            "principal": "Hauptspeise",
            "postre": "Nachspeise",
            "guarnición": "Beilage",
            "guarnicion": "Beilage",
            "quesos": "Käsegang",
            "queso": "Käsegang",
            "aperitivo": "Aperitif",
            "digestivo": "Digestif",
            "bebida": "Getränk",
            // French
            "entrée": "Vorspeise",
            "entree": "Vorspeise",
            "potage": "Suppengang",
            "plat intermédiaire": "Zwischengang",
            "plat intermediaire": "Zwischengang",
            "plat principal": "Hauptspeise",
            "accompagnement": "Beilage",
            "fromages": "Käsegang",
            "fromage": "Käsegang",
            "apéritif": "Aperitif",
            "boisson": "Getränk",
            // Italian
            "antipasto": "Vorspeise",
            "primo": "Suppengang",
            "piatto intermedio": "Zwischengang",
            "secondo": "Hauptspeise",
            "dolce": "Nachspeise",
            "contorno": "Beilage",
            "formaggi": "Käsegang",
            "formaggio": "Käsegang",
            "bevanda": "Getränk"
        ]
        
        // Return the original course name (in its original language) if found in mapping
        // This preserves the language-specific names from the AI
        if let _ = validCourses[normalized] {
            return c  // Return original (preserves capitalization and language)
        }
        
        return nil
    }
    
    // Generate recipe automatically with essential preferences only
    private func generateAutomatic(recipeName: String, recipeDescription: String) async {
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            await MainActor.run {
                createError = L.errorJailbreakDetected.localized
            }
            return
        }
        
        guard await app.ensureAIAccess(for: .aiRecipeGenerator) else { return }
        
        // Check DSGVO consent before using OpenAI
        guard OpenAIConsentManager.hasConsent else {
            await MainActor.run {
                createError = L.consent_required.localized
            }
            return
        }
        
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
        
        // Get original transaction ID for transaction-based rate limiting
        let transactionId = await app.getOriginalTransactionId()
        
        // Try to increment AI usage, but don't fail if backend is unreachable
        do { 
            _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: transactionId) 
        } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
            Logger.info("[ChatView] Backend unreachable, continuing without usage tracking", category: .network)
        } catch {
            if app.handleAISubscriptionDenied(error) { return }
            await MainActor.run { 
                createError = ErrorMessageHelper.userFriendlyMessage(from: error)
            }
            return
        }
        
        guard let openai = app.openAI else { return }
        
        // DEBUG: Log dietary preferences in ChatView
        Logger.info("[DEBUG Dietary ChatView] ========== CHATVIEW DIETARY PREFERENCES DEBUG ==========", category: .data)
        Logger.info("[DEBUG Dietary ChatView] User ID: \(KeychainManager.get(key: "user_id") ?? "nil")", category: .data)
        Logger.info("[DEBUG Dietary ChatView] app.dietary.diets: \(app.dietary.diets)", category: .data)
        Logger.info("[DEBUG Dietary ChatView] app.dietary.allergies: \(app.dietary.allergies)", category: .data)
        print("🔍 [DEBUG Dietary ChatView] ========== CHATVIEW DIETARY PREFERENCES DEBUG ==========")
        print("🔍 [DEBUG Dietary ChatView] User ID: \(KeychainManager.get(key: "user_id") ?? "nil")")
        print("🔍 [DEBUG Dietary ChatView] app.dietary.diets: \(app.dietary.diets)")
        print("🔍 [DEBUG Dietary ChatView] app.dietary.allergies: \(app.dietary.allergies)")
        
        // Build essential dietary context: allergies, intolerances, and important diets only
        var essentialParts: [String] = []
        
        // ALWAYS include allergies and intolerances
        if !app.dietary.allergies.isEmpty {
            essentialParts.append("Allergien/Unverträglichkeiten: " + app.dietary.allergies.joined(separator: ", "))
            Logger.info("[DEBUG Dietary ChatView] Added allergies: \(app.dietary.allergies)", category: .data)
            print("🔍 [DEBUG Dietary ChatView] Added allergies: \(app.dietary.allergies)")
        }
        
        // Include ONLY important dietary preferences (halal, vegan, vegetarian, etc.)
        let importantDiets = ["halal", "vegan", "vegetarisch", "pescetarisch", "koscher"]
        let userImportantDiets = app.dietary.diets.filter { importantDiets.contains($0.lowercased()) }
        if !userImportantDiets.isEmpty {
            essentialParts.append("Ernährungsweisen: " + userImportantDiets.sorted().joined(separator: ", "))
            Logger.info("[DEBUG Dietary ChatView] Added important diets: \(userImportantDiets)", category: .data)
            print("🔍 [DEBUG Dietary ChatView] Added important diets: \(userImportantDiets)")
        } else {
            Logger.info("[DEBUG Dietary ChatView] NO important diets found (all diets: \(app.dietary.diets))", category: .data)
            print("🔍 [DEBUG Dietary ChatView] NO important diets found (all diets: \(app.dietary.diets))")
        }
        
        // WICHTIG: Ernährungsweisen müssen IMMER respektiert werden - Rezepte entsprechend anpassen
        let essentialContext = essentialParts.isEmpty ? "" : "WICHTIG: Allergien müssen IMMER vermieden werden. Ernährungsweisen müssen IMMER respektiert werden - wenn der Benutzer z.B. vegetarisch ist und 'Beef Stroganoff' anfordert, erstelle eine vegetarische Variante (z.B. mit Pilzen oder Seitan statt Rindfleisch). " + essentialParts.joined(separator: " | ")
        let languageContext = app.languageSystemPrompt()
        let fullContext = [essentialContext, languageContext].filter { !$0.isEmpty }.joined(separator: "\n")
        
        Logger.info("[DEBUG Dietary ChatView] Essential context: \(essentialContext)", category: .data)
        Logger.info("[DEBUG Dietary ChatView] Full context: \(fullContext)", category: .data)
        Logger.info("[DEBUG Dietary ChatView] ========== END CHATVIEW DIETARY PREFERENCES DEBUG ==========", category: .data)
        print("🔍 [DEBUG Dietary ChatView] Essential context: \(essentialContext)")
        print("🔍 [DEBUG Dietary ChatView] Full context: \(fullContext)")
        print("🔍 [DEBUG Dietary ChatView] ========== END CHATVIEW DIETARY PREFERENCES DEBUG ==========")
        
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
            if app.handleAISubscriptionDenied(error) { return }
            await MainActor.run { 
                createError = ErrorMessageHelper.userFriendlyMessage(from: error)
            }
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
