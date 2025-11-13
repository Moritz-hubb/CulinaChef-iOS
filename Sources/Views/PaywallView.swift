import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.78, blue: 0.68),
                Color(red: 0.95, green: 0.74, blue: 0.64),
                Color(red: 0.93, green: 0.66, blue: 0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 64))
                                .foregroundStyle(.white)
                                .shadow(color: .white.opacity(0.3), radius: 20)
                            
                            Text("Unlimited")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("Schalte alle AI-Features frei")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Features
                        VStack(spacing: 20) {
                            FeatureRow(
                                icon: "bubble.left.and.bubble.right.fill",
                                title: "AI Recipe Chat",
                                description: "Lass dir Rezepte von der AI empfehlen"
                            )
                            
                            FeatureRow(
                                icon: "wand.and.stars",
                                title: "AI Rezept-Generator",
                                description: "Erstelle kreative Rezepte mit AI"
                            )
                            
                            FeatureRow(
                                icon: "chart.bar.fill",
                                title: "AI Rezept-Analyse",
                                description: "Intelligente Nährwert-Analysen"
                            )
                            
                            FeatureRow(
                                icon: "infinity",
                                title: "Unbegrenzte Nutzung",
                                description: "Keine Limits, nur Kreativität"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Pricing
                        VStack(spacing: 16) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("5,99€")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("/ Monat")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            Text("Jederzeit kündbar")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 8)
                        
                        // Debug Badge
                        #if DEBUG
                        Text("🧪 Debug-Modus: Simulierter Kauf")
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                            )
                        #endif
                        
                        // CTA Button
                        VStack(spacing: 12) {
                            Button(action: purchaseUnlimited) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Unlimited freischalten")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .foregroundStyle(.white)
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
                            .disabled(isPurchasing)
                            
                            Button(action: restorePurchases) {
                                HStack {
                                    if isRestoring {
                                        ProgressView()
                                            .tint(.white.opacity(0.7))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Käufe wiederherstellen")
                                            .font(.subheadline)
                                    }
                                }
                                .foregroundStyle(.white.opacity(0.7))
                            }
                            .disabled(isRestoring)
                        }
                        .padding(.horizontal, 24)
                        
                        // Free features info
                        VStack(spacing: 16) {
                            Text("Kostenlos bleiben?")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Text("Alle anderen Features wie Rezeptverwaltung, Einkaufsliste und Community Library bleiben kostenlos verfügbar.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Button(action: { dismiss() }) {
                                Text("Kostenlos fortfahren")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                            .padding(.horizontal, 48)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .alert("Fehler", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Ein unbekannter Fehler ist aufgetreten")
            }
        }
    }
    
    private func purchaseUnlimited() {
        isPurchasing = true
        errorMessage = nil
        
        Task {
            #if DEBUG
            // In Debug: Use simulated purchase (no Apple Developer Account needed)
            app.subscribeSimulated()
            
            await MainActor.run {
                isPurchasing = false
                dismiss()
            }
            #else
            // In Production: Use real StoreKit
            await app.purchaseStoreKit()
            
            await MainActor.run {
                isPurchasing = false
                
                // Check if purchase was successful
                if app.isSubscribed {
                    dismiss()
                } else if let error = app.error {
                    errorMessage = error
                    showError = true
                }
            }
            #endif
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        errorMessage = nil
        
        Task {
            do {
                try await app.storeKit.restore()
                
                // Check if user now has active subscription
                let hasAccess = await app.storeKit.hasActiveEntitlement()
                
                await MainActor.run {
                    isRestoring = false
                    
                    if hasAccess {
                        dismiss()
                    } else {
                        errorMessage = "Keine aktiven Käufe gefunden"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Feature Row Component
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    PaywallView()
        .environmentObject(AppState())
}
