import SwiftUI
import PhotosUI

struct CommunityUploadSheet: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState
    
    let recipe: Recipe
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var uploadedImages: [UIImage] = []
    @State private var imageUrls: [String] = [] // URLs from recipe or uploaded
    
    @State private var isUploading = false
    @State private var moderationStatus: String? = nil
    @State private var moderationReason: String? = nil
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var uploadSuccess = false
    
    init(recipe: Recipe) {
        self.recipe = recipe
        
        // Pre-fill images if recipe has them
        if let imageUrl = recipe.image_url {
            let urls: [String] = {
                if imageUrl.contains("_0.") {
                    var arr = [imageUrl]
                    let u1 = imageUrl.replacingOccurrences(of: "_0.", with: "_1.")
                    let u2 = imageUrl.replacingOccurrences(of: "_0.", with: "_2.")
                    arr.append(u1)
                    arr.append(u2)
                    return arr
                }
                return [imageUrl]
            }()
            _imageUrls = State(initialValue: urls)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
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
                    VStack(alignment: .leading, spacing: 20) {
                        // Recipe Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L.shareRecipeOriginal.localized)
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.7))
                            Text(recipe.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.4))
                        )
                        
                        // Images Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(L.shareRecipeImage.localized)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(imageUrls.count + uploadedImages.count)/1")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            
                            // Display existing images
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Existing recipe images
                                    ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, urlString in
                                        if let url = URL(string: urlString) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 100, height: 100)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                        .overlay(alignment: .topTrailing) {
                                                            Button(action: { imageUrls.remove(at: index) }) {
                                                                Image(systemName: "xmark.circle.fill")
                                                                    .foregroundStyle(.white)
                                                                    .background(Circle().fill(.black.opacity(0.5)))
                                                            }
                                                            .padding(4)
                                                        }
                                                default:
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(.ultraThinMaterial.opacity(0.4))
                                                        .frame(width: 100, height: 100)
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Uploaded images
                                    ForEach(Array(uploadedImages.enumerated()), id: \.offset) { index, uiImage in
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(alignment: .topTrailing) {
                                                Button(action: { uploadedImages.remove(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.white)
                                                        .background(Circle().fill(.black.opacity(0.5)))
                                                }
                                                .padding(4)
                                            }
                                    }
                                    
                                    // Add photo button
                                    if (imageUrls.count + uploadedImages.count) < 1 {
                                        PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 1, matching: .images) {
                                            VStack {
                                                Image(systemName: "plus")
                                                    .font(.title2)
                                                Text(L.shareRecipePhoto.localized)
                                                    .font(.caption)
                                            }
                                            .foregroundStyle(.white)
                                            .frame(width: 100, height: 100)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(.ultraThinMaterial.opacity(0.4))
                                            )
                                        }
                                        .onChange(of: selectedPhotos) { _, newItems in
                                            Task { await loadPhotos(newItems) }
                                        }
                                    }
                                }
                            }
                            
                            Text(L.community_bild_ist_optional_max.localized)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        
                        // Moderation Status
                        if let status = moderationStatus {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: status == "Freigegeben" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    Text(status == "Freigegeben" ? "Freigegeben" : "Abgelehnt")
                                        .font(.headline)
                                }
                                .foregroundStyle(status == "Freigegeben" ? .green : .red)
                                
                                if let reason = moderationReason, status != "Freigegeben" {
                                    Text(reason)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial.opacity(0.4))
                            )
                        }
                        
                        // Success Message
                        if uploadSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(L.community_erfolgreich_in_der_community.localized)
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(.green)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white)
                            )
                        }
                        
                        // Publish Button
                        Button(action: publishToCommunity) {
                            HStack {
                                if isUploading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(L.community_veröffentlichen.localized)
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(canPublish ? Color(red: 0.85, green: 0.4, blue: 0.2) : Color.gray.opacity(0.5))
                            )
                        }
                        .disabled(!canPublish || isUploading)
                        
                        Text(L.community_mit_der_veröffentlichung_wird.localized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Community Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .alert(L.alert_error.localized, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canPublish: Bool {
        !isUploading
    }
    
    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    uploadedImages.append(uiImage)
                }
            }
        }
        await MainActor.run {
            selectedPhotos.removeAll()
        }
    }
    
    private func publishToCommunity() {
        Task {
            await performPublish()
        }
    }
    
    private func performPublish() async {
        // Block uploads on jailbroken devices
        if app.isJailbroken {
            await MainActor.run {
                errorMessage = L.errorJailbreakCommunityUpload.localized
                showError = true
            }
            return
        }
        
        guard let token = app.accessToken else {
            await MainActor.run {
                errorMessage = "Nicht angemeldet"
                showError = true
            }
            return
        }
        
        await MainActor.run {
            isUploading = true
            moderationStatus = nil
            moderationReason = nil
        }
        
        defer {
            Task { @MainActor in
                isUploading = false
            }
        }
        
        do {
            // Convert uploaded images to base64 data URLs
            var allImageUrls = imageUrls
            for image in uploadedImages {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    let base64 = data.base64EncodedString()
                    allImageUrls.append("data:image/jpeg;base64,\(base64)")
                }
            }
            
            // Build request body
            let body: [String: Any] = [
                "recipe_id": recipe.id,
                "image_urls": allImageUrls
            ]
            
            // Call backend /community/publish endpoint
            var url = Config.backendBaseURL
            url.append(path: "/community/publish")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await SecureURLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.error("Community upload response is not HTTPURLResponse", category: .network)
                throw URLError(.badServerResponse)
            }
            
            Logger.debug("Community upload response status: \(httpResponse.statusCode)", category: .network)
            
            if httpResponse.statusCode == 403 {
                // Moderation failed
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detail = json["detail"] as? String {
                    await MainActor.run {
                        moderationStatus = "Denied"
                        moderationReason = detail
                    }
                } else {
                    throw URLError(.badServerResponse)
                }
            } else if (200...299).contains(httpResponse.statusCode) {
                // Success
                await MainActor.run {
                    moderationStatus = "Freigegeben"
                    uploadSuccess = true
                }
                
                // Wait a bit, then dismiss
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    app.selectedRecipeForUpload = nil
                    dismiss()
                }
            } else {
                throw URLError(.badServerResponse)
            }
            
        } catch {
            Logger.error("Community upload failed", error: error, category: .network)
            await MainActor.run {
                errorMessage = userFriendlyErrorMessage(from: error)
                showError = true
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
        
        // Upload errors
        if errorDescription.contains("upload") || 
           errorDescription.contains("failed") {
            return L.errorUploadFailed.localized
        }
        
        // Generic fallback
        return L.errorGenericUserFriendly.localized
    }
}
