import SwiftUI
// DEVELOPMENT MODE: RevenueCat import disabled
// import RevenueCat
import UIKit

/// Modern RevenueCat Paywall View with offerings support
/// 
/// DEVELOPMENT MODE: This view is stubbed out to allow compilation without RevenueCat module.
/// Before launch, uncomment RevenueCat import and restore all functionality.
struct RevenueCatPaywallView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var revenueCat = RevenueCatManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var hasAcceptedFairUse = false
    @State private var showFairUse = false
    @State private var selectedPackage: Any? // Package? - DEVELOPMENT MODE
    @State private var showCustomerCenter = false
    
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
                            FeatureRow(
                                icon: "bubble.left.and.bubble.right.fill",
                                title: L.subscriptionAIChatUnlimited.localized,
                                description: L.subscriptionAINutritionAnalysis.localized
                            )
                            
                            FeatureRow(
                                icon: "wand.and.stars",
                                title: L.subscriptionAIRecipeGenerator.localized,
                                description: L.subscriptionNoLimits.localized
                            )
                            
                            FeatureRow(
                                icon: "chart.bar.fill",
                                title: L.subscriptionAINutritionAnalysis.localized,
                                description: L.paywallFeatureSecure.localized
                            )
                            
                            FeatureRow(
                                icon: "infinity",
                                title: L.subscriptionNoLimits.localized,
                                description: L.subscriptionNoLimits.localized
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Subscription Packages
                        if revenueCat.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding()
                        } else if revenueCat.availablePackages.isEmpty {
                            // Fallback: Show default pricing if no packages available
                            VStack(spacing: 16) {
                                Text(L.paywallPrice.localized)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(L.paywallPerMonth.localized)
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(.top, 8)
                        } else {
                            VStack(spacing: 16) {
                                // Monthly Package
                                if let monthlyPackage = revenueCat.monthlyPackage {
                                    PackageCard(
                                        package: monthlyPackage,
                                        isSelected: selectedPackage != nil, // DEVELOPMENT MODE: Simplified check
                                        // PRODUCTION: isSelected: selectedPackage?.identifier == monthlyPackage.identifier,
                                        onSelect: { selectedPackage = monthlyPackage }
                                    )
                                }
                                
                                // Yearly Package (with discount badge)
                                if let yearlyPackage = revenueCat.yearlyPackage {
                                    PackageCard(
                                        package: yearlyPackage,
                                        isSelected: selectedPackage != nil, // DEVELOPMENT MODE: Simplified check
                                        // PRODUCTION: isSelected: selectedPackage?.identifier == yearlyPackage.identifier,
                                        onSelect: { selectedPackage = yearlyPackage },
                                        showDiscount: true,
                                        discountPercentage: calculateDiscount(monthly: revenueCat.monthlyPackage, yearly: yearlyPackage)
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Purchase Button
                        if let selectedPackage = selectedPackage {
                            Button(action: {
                                Task {
                                    await purchasePackage(selectedPackage)
                                }
                            }) {
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
                                .background(hasAcceptedFairUse ? Color.white : Color.white.opacity(0.5))
                                .foregroundStyle(hasAcceptedFairUse ? Color.orange : Color.white.opacity(0.7))
                                .cornerRadius(16)
                            }
                            .disabled(isPurchasing || !hasAcceptedFairUse)
                            .padding(.horizontal, 24)
                        } else if !revenueCat.isLoading && revenueCat.availablePackages.isEmpty {
                            // Show disabled button if no packages available
                            Button(action: {}) {
                                Text(L.paywallSubscribeButton.localized)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white.opacity(0.3))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                    .cornerRadius(16)
                            }
                            .disabled(true)
                            .padding(.horizontal, 24)
                        }
                        
                        // Restore & Customer Center
                        HStack(spacing: 24) {
                            Button(action: {
                                Task {
                                    await restorePurchases()
                                }
                            }) {
                                Text(L.paywallRestorePurchase.localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .disabled(isRestoring)
                            
                            if revenueCat.canShowCustomerCenter {
                                Button(action: {
                                    revenueCat.showCustomerCenter()
                                }) {
                                    Text(L.manageSubscription.localized)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        // Fair Use Agreement
                        VStack(spacing: 12) {
                            Button(action: {
                                showFairUse = true
                            }) {
                                HStack {
                                    Image(systemName: hasAcceptedFairUse ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(hasAcceptedFairUse ? .white : .white.opacity(0.7))
                                    Text(L.legalFairUseCheckbox.localized)
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Spacer()
                                }
                            }
                            
                            Text(L.subscriptionCancelAnytime.localized)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .sheet(isPresented: $showFairUse) {
                FairUseView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .task {
                // DEVELOPMENT MODE: Disabled
                // await revenueCat.loadOfferings()
                // // Auto-select first package when offerings are loaded
                // if selectedPackage == nil, let firstPackage = revenueCat.availablePackages.first {
                //     selectedPackage = firstPackage
                // }
            }
        }
    }
    
    // MARK: - Actions
    
    private func purchasePackage(_ package: Any) async { // Package
        // DEVELOPMENT MODE: Not available
        showError(message: "Purchase not available in development mode")
        return
        
        // PRODUCTION (uncomment before launch):
        // guard hasAcceptedFairUse else {
        //     showError(message: L.legalFairUseCheckboxRequired.localized)
        //     return
        // }
        // 
        // isPurchasing = true
        // errorMessage = nil
        // 
        // do {
        //     let (_, customerInfo) = try await revenueCat.purchase(package: package)
        //     
        //     // Check if purchase was successful
        //     if customerInfo.entitlements[RevenueCatManager.unlimitedEntitlementID]?.isActive == true {
        //         // Update app state
        //         await app.loadSubscriptionStatus()
        //         
        //         // Dismiss paywall
        //         await MainActor.run {
        //             dismiss()
        //         }
        //     } else {
        //         showError(message: "Purchase completed but subscription is not active")
        //     }
        // } catch {
        //     if let revenueCatError = error as? RevenueCatError,
        //        revenueCatError == .userCancelled {
        //         // User cancelled - don't show error
        //         return
        //     }
        //     showError(message: error.localizedDescription)
        // }
        // 
        // isPurchasing = false
    }
    
    private func restorePurchases() async {
        isRestoring = true
        errorMessage = nil
        
        do {
            try await revenueCat.restorePurchases()
            
            if revenueCat.isSubscribed {
                app.loadSubscriptionStatus()
                await MainActor.run {
                    dismiss()
                }
            } else {
                showError(message: L.settings_keine_aktiven_käufe_gefunden.localized)
            }
        } catch {
            showError(message: error.localizedDescription)
        }
        
        isRestoring = false
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func calculateDiscount(monthly: Any?, yearly: Any?) -> Int? { // Package?
        // DEVELOPMENT MODE: Returns nil
        return nil
        
        // PRODUCTION (uncomment before launch):
        // guard let monthly = monthly,
        //       let yearly = yearly else { return nil }
        // 
        // let monthlyPrice = NSDecimalNumber(decimal: monthly.storeProduct.price).doubleValue
        // let yearlyPrice = NSDecimalNumber(decimal: yearly.storeProduct.price).doubleValue
        // let monthlyYearlyTotal = monthlyPrice * 12
        // 
        // guard monthlyYearlyTotal > 0 else { return nil }
        // 
        // let discount = ((monthlyYearlyTotal - yearlyPrice) / monthlyYearlyTotal) * 100
        // return Int(discount.rounded())
    }
}

// MARK: - Package Card

struct PackageCard: View {
    let package: Any // Package - DEVELOPMENT MODE
    let isSelected: Bool
    let onSelect: () -> Void
    var showDiscount: Bool = false
    var discountPercentage: Int? = nil
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // DEVELOPMENT MODE: Placeholder text
                        Text("Subscription Package")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        // PRODUCTION: Text(package.storeProduct.localizedTitle)
                        
                        if showDiscount, let discount = discountPercentage {
                            Text("\(discount)% OFF")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    
                    // DEVELOPMENT MODE: Placeholder text
                    Text("Unlimited access to all features")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    // PRODUCTION: Text(package.storeProduct.localizedDescription)
                    
                    // DEVELOPMENT MODE: Placeholder text
                    Text("$9.99")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    // PRODUCTION: Text(package.storeProduct.localizedPriceString)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 32)
            
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

