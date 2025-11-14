import SwiftUI

// MARK: - Report Reason Sheet
struct ReportReasonSheet: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState
    
    let recipe: Recipe
    let onReported: () -> Void
    
    @State private var selectedReason: ReportReason?
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var reportSuccess = false
    
    enum ReportReason: String, CaseIterable, Identifiable {
        case nsfw = "NSFW/Unangemessen"
        case hate = "Hassrede/Diskriminierung"
        case spam = "Spam/Werbung"
        case irrelevant = "Nicht rezeptbezogen"
        case other = "Sonstiges"
        
        var id: String { rawValue }
        
        var apiValue: String {
            switch self {
            case .nsfw: return "nsfw"
            case .hate: return "hate"
            case .spam: return "spam"
            case .irrelevant: return "irrelevant"
            case .other: return "other"
            }
        }
        
        var icon: String {
            switch self {
            case .nsfw: return "eye.slash"
            case .hate: return "exclamationmark.triangle"
            case .spam: return "envelope.badge"
            case .irrelevant: return "questionmark.circle"
            case .other: return "ellipsis.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if reportSuccess {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text(L.report_reported.localized)
                            .font(.title2.bold())
                        
                        Text(L.ui_danke_für_deine_meldung.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Rezept Info
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L.report_reportRecipe.localized)
                                    .font(.headline)
                                Text(recipe.title)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Grund auswählen
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L.ui_grund_der_meldung.localized)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal)
                                
                                ForEach(ReportReason.allCases) { reason in
                                    Button(action: {
                                        selectedReason = reason
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: reason.icon)
                                                .font(.title3)
                                                .foregroundColor(selectedReason == reason ? .white : Color(red: 0.85, green: 0.4, blue: 0.2))
                                                .frame(width: 40)
                                            
                                            Text(reason.rawValue)
                                                .font(.body)
                                                .foregroundColor(selectedReason == reason ? .white : .primary)
                                            
                                            Spacer()
                                            
                                            if selectedReason == reason {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            selectedReason == reason ?
                                            Color(red: 0.85, green: 0.4, blue: 0.2) :
                                            Color(UIColor.secondarySystemGroupedBackground)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Optionale Details
                            if selectedReason != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L.ui_zusätzliche_details_optional.localized)
                                        .font(.subheadline.bold())
                                    
                                    TextEditor(text: $details)
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(.horizontal)
                            }
                            
                            // Submit Button
                            if let reason = selectedReason {
                                Button(action: submitReport) {
                                    HStack {
                                        if isSubmitting {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text(L.report_reportButton.localized)
                                        }
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(red: 0.85, green: 0.4, blue: 0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(isSubmitting)
                                .padding(.horizontal)
                                .padding(.top, 10)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(L.report_reportRecipe.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L.cancel.localized) {
                        dismiss()
                    }
                }
            }
        }
        .alert("Fehler", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitReport() {
        guard let reason = selectedReason else { return }
        
        Task {
            await performSubmit(reason: reason)
        }
    }
    
    private func performSubmit(reason: ReportReason) async {
        guard let token = app.accessToken else {
            await MainActor.run {
                errorMessage = "Nicht angemeldet"
                showError = true
            }
            return
        }
        
        await MainActor.run {
            isSubmitting = true
        }
        
        defer {
            Task { @MainActor in
                isSubmitting = false
            }
        }
        
        do {
            var url = Config.backendBaseURL
            url.append(path: "/reports/create")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "recipe_id": recipe.id,
                "reason": reason.apiValue,
                "details": details.isEmpty ? nil : details
            ].compactMapValues { $0 }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await SecureURLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            await MainActor.run {
                reportSuccess = true
            }
            
            // Wait a bit, then dismiss
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                onReported()
                dismiss()
            }
            
        } catch {
            print("[Report] Error: \(error)")
            await MainActor.run {
                errorMessage = "Meldung fehlgeschlagen: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}
