import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var hasAcceptedFairUse = false
    @State private var showFairUse = false
    
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
                                .accessibilityHidden(true)
                            
                            Text(L.paywallUnlimited.localized)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text(L.paywallSubtitle.localized)
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 40)
                        
                        // Features
                        VStack(spacing: 20) {
                            PaywallFeatureRow(
                                icon: "bubble.left.and.bubble.right.fill",
                                title: L.subscriptionAIChatUnlimited.localized,
                                description: L.subscriptionAINutritionAnalysis.localized
                            )
                            
                            PaywallFeatureRow(
                                icon: "wand.and.stars",
                                title: L.subscriptionAIRecipeGenerator.localized,
                                description: L.subscriptionNoLimits.localized
                            )
                            
                            PaywallFeatureRow(
                                icon: "chart.bar.fill",
                                title: L.subscriptionAINutritionAnalysis.localized,
                                description: L.paywallFeatureSecure.localized
                            )
                            
                            PaywallFeatureRow(
                                icon: "infinity",
                                title: L.subscriptionNoLimits.localized,
                                description: L.subscriptionNoLimits.localized
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Pricing
                        VStack(spacing: 16) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(L.paywallPrice.localized)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(L.paywallPerMonth.localized)
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            Text(L.subscriptionCancelAnytime.localized)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 8)
                        
                        // Debug Badge
                        #if DEBUG
                        Text("🧪 Debug: Simulated purchase")
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                            )
                        #endif
                        
                        // Fair Use Policy Checkbox
                        VStack(spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Button(action: { hasAcceptedFairUse.toggle() }) {
                                    Image(systemName: hasAcceptedFairUse ? "checkmark.square.fill" : "square")
                                        .font(.title3)
                                        .foregroundStyle(hasAcceptedFairUse ? Color(red: 0.2, green: 0.6, blue: 0.9) : .white.opacity(0.7))
                                }
                                .accessibilityLabel(hasAcceptedFairUse ? "Fair Use Policy akzeptiert" : "Fair Use Policy akzeptieren")
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(L.legalFairUseCheckbox.localized)
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                        
                                        Button(action: { showFairUse = true }) {
                                            Text(L.legalFairUseCheckboxLink.localized)
                                                .font(.subheadline)
                                                .underline()
                                                .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.9))
                                        }
                                        .accessibilityLabel(L.legalFairUseCheckboxLink.localized)
                                        .accessibilityHint("Öffnet die Fair Use Policy")
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.1))
                            )
                            
                            // CTA Button
                            Button(action: purchaseUnlimited) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(L.paywallSubscribeButton.localized)
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
                            .accessibilityLabel(isPurchasing ? L.loading.localized : L.paywallSubscribeButton.localized)
                            .accessibilityHint("Abonniert Unlimited und erhält Zugang zu allen KI-Funktionen")
                            .disabled(isPurchasing)
                            
                            Button(action: restorePurchases) {
                                HStack {
                                    if isRestoring {
                                        ProgressView()
                                            .tint(.white.opacity(0.7))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(L.paywallRestorePurchase.localized)
                                            .font(.subheadline)
                                    }
                                }
                                .foregroundStyle(.white.opacity(0.7))
                            }
                            .accessibilityLabel(isRestoring ? L.loading.localized : L.paywallRestorePurchase.localized)
                            .accessibilityHint("Stellt vorherige Käufe wieder her")
                            .disabled(isRestoring)
                        }
                        .padding(.horizontal, 24)
                        
                        // Free features info
                        VStack(spacing: 16) {
                            Text(L.paywallContinueFree.localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Text(L.subscriptionAllFeaturesExceptAI.localized)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Button(action: { dismiss() }) {
                                Text(L.paywallContinueFree.localized)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                            .accessibilityLabel(L.paywallContinueFree.localized)
                            .accessibilityHint("Schließt den Paywall und nutzt die App kostenlos")
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
                    .accessibilityLabel(L.cancel.localized)
                    .accessibilityHint("Schließt den Paywall")
                }
            }
            .alert(L.alert_error.localized, isPresented: $showError) {
                Button(L.button_ok.localized, role: .cancel) { }
            } message: {
                Text(errorMessage ?? L.errorGeneric.localized)
            }
            .sheet(isPresented: $showFairUse) {
                FairUseView()
            }
        }
        .id(localizationManager.currentLanguage) // Force re-render on language change
    }
    
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        return userFriendlyErrorMessage(from: errorDescription)
    }
    
    private func userFriendlyErrorMessage(from errorString: String) -> String {
        let errorDescription = errorString.lowercased()
        
        // Network errors
        if errorDescription.contains("cannotfindhost") || 
           errorDescription.contains("cannotconnecttohost") ||
           errorDescription.contains("network") ||
           errorDescription.contains("internet") {
            return L.errorNetworkConnection.localized
        }
        
        // StoreKit errors
        if errorDescription.contains("purchase") || 
           errorDescription.contains("storekit") ||
           errorDescription.contains("payment") {
            return L.errorPurchaseFailed.localized
        }
        
        // Rate limit errors
        if errorDescription.contains("rate limit") || 
           errorDescription.contains("limit exceeded") {
            return L.errorRateLimitExceeded.localized
        }
        
        // Generic fallback
        return L.errorGenericUserFriendly.localized
    }
    
    private func purchaseUnlimited() {
        // Validate Fair Use Policy acceptance
        guard hasAcceptedFairUse else {
            errorMessage = L.legalFairUseCheckboxRequired.localized
            showError = true
            return
        }
        
        isPurchasing = true
        errorMessage = nil
        
        Task {
            // Use real StoreKit purchase flow (works with StoreKit Configuration file in Debug)
            await app.purchaseStoreKit()
            
            await MainActor.run {
                isPurchasing = false
                
                // Check if purchase was successful
                if app.isSubscribed {
                    dismiss()
                } else if let errorString = app.error {
                    errorMessage = userFriendlyErrorMessage(from: errorString)
                    showError = true
                } else {
                    // User cancelled - no error, just don't dismiss
                    // This prevents false "success" state
                }
            }
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
                        errorMessage = L.settings_keine_aktiven_käufe_gefunden.localized
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    errorMessage = userFriendlyErrorMessage(from: error)
                    showError = true
                }
            }
        }
    }
}

// MARK: - Feature Row Component
private struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 40)
            
            VStack(alignment: .center, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
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
