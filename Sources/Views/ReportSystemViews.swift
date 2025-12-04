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
        case nsfw
        case hate
        case spam
        case irrelevant
        case other
        
        var id: String { apiValue }
        
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
        
        var localizedTitle: String {
            switch self {
            case .nsfw: return L.reportReasonInappropriate.localized
            case .hate: return L.reportReasonMisleading.localized
            case .spam: return L.reportReasonSpam.localized
            case .irrelevant: return L.reportReason.localized
            case .other: return L.reportReasonOther.localized
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching app design
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
                
                if reportSuccess {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.5, blue: 0.3),
                                            Color(red: 0.85, green: 0.4, blue: 0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(L.report_reported.localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(L.ui_danke_für_deine_meldung.localized)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Rezept Info Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L.report_reportRecipe.localized)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                
                                Text(recipe.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Grund auswählen
                            VStack(alignment: .leading, spacing: 16) {
                                Text(L.ui_grund_der_meldung.localized)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                ForEach(ReportReason.allCases) { reason in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedReason = reason
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        selectedReason == reason ?
                                                        LinearGradient(
                                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ) :
                                                        LinearGradient(
                                                            colors: [
                                                                Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.2),
                                                                Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.2)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 48, height: 48)
                                                
                                                Image(systemName: reason.icon)
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(
                                                        selectedReason == reason ?
                                                        .white :
                                                        Color(red: 0.85, green: 0.4, blue: 0.2)
                                                    )
                                            }
                                            
                                            Text(reason.localizedTitle)
                                                .font(.system(size: 16, weight: selectedReason == reason ? .semibold : .regular))
                                                .foregroundColor(selectedReason == reason ? .white : .white.opacity(0.9))
                                            
                                            Spacer()
                                            
                                            if selectedReason == reason {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            Group {
                                                if selectedReason == reason {
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.95, green: 0.5, blue: 0.3),
                                                            Color(red: 0.85, green: 0.4, blue: 0.2)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                } else {
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.15),
                                                            Color.white.opacity(0.05)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                }
                                            }
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(
                                                    selectedReason == reason ?
                                                    LinearGradient(
                                                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ) :
                                                    LinearGradient(
                                                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: selectedReason == reason ? 1.5 : 1
                                                )
                                        )
                                        .shadow(
                                            color: selectedReason == reason ?
                                            Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.3) :
                                            .black.opacity(0.1),
                                            radius: selectedReason == reason ? 12 : 8,
                                            y: selectedReason == reason ? 6 : 4
                                        )
                                    }
                                    .accessibilityLabel(reason.localizedTitle)
                                    .accessibilityHint(selectedReason == reason ? "Aktuell ausgewählt" : "Wählt diesen Grund aus")
                                    .accessibilityAddTraits(selectedReason == reason ? .isSelected : [])
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // Optionale Details
                            if selectedReason != nil {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(L.ui_zusätzliche_details_optional.localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    TextEditor(text: $details)
                                        .frame(height: 120)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 1.5
                                                        )
                                                )
                                        )
                                        .scrollContentBackground(.hidden)
                                        .foregroundColor(.white)
                                        .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                                        .accessibilityLabel("Zusätzliche Details")
                                        .accessibilityHint("Optionale zusätzliche Informationen zur Meldung")
                                }
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // Submit Button
                            if selectedReason != nil {
                                Button(action: submitReport) {
                                    HStack(spacing: 12) {
                                        if isSubmitting {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.system(size: 18, weight: .semibold))
                                            Text(L.report_reportButton.localized)
                                                .font(.system(size: 18, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.95, green: 0.5, blue: 0.3),
                                                Color(red: 0.85, green: 0.4, blue: 0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.4), radius: 16, y: 8)
                                }
                                .accessibilityLabel(isSubmitting ? L.loading.localized : L.report_reportButton.localized)
                                .accessibilityHint("Sendet die Meldung ab")
                                .disabled(isSubmitting)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle(L.report_reportRecipe.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L.cancel.localized) {
                        dismiss()
                    }
                    .foregroundColor(.white)
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
            Logger.error("Report submission failed", error: error, category: .network)
            await MainActor.run {
                errorMessage = "Meldung fehlgeschlagen: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}
