import SwiftUI

/// Retired standalone policy. Kept so old navigation cannot show the previous
/// "Unlimited means unconstrained" text. The binding limits live in the Terms.
struct FairUseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var isGerman: Bool {
        localizationManager.currentLanguage == "de"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(isGerman ? "Die separate Fair-Use-Policy gibt es nicht mehr." : "The separate Fair Use Policy has been retired.")
                        .font(.title3.weight(.semibold))
                    Text(isGerman
                         ? "Die Nutzungsgrenzen von CulinaAi Premium stehen in den AGB, Abschnitt Premium-Kontingente: 100 KI-Einheiten pro Tag, 1.000 pro Kalendermonat, 10 Bilder pro Tag, höchstens 3 Bilder pro Anfrage, 2 Einheiten für einen Social-Import und 1 Einheit plus eine Einheit je Gericht bei der KI-Essensplanung. Gleichzeitig gelten standardmäßig 3 KI-Anfragen pro Konto."
                         : "CulinaAi Premium limits are in the Terms, Premium allowances: 100 AI units per day, 1,000 per calendar month, 10 images per day, at most 3 images per request, 2 units for a social import, and 1 unit plus one unit per meal for an AI meal plan. By default, 3 AI requests per account can run at once.")
                    Text(isGerman
                         ? "Manuelle Rezepte und die Einkaufsliste bleiben ohne KI-Kontingent nutzbar."
                         : "Manual recipes and the shopping list stay available without using the AI allowance.")
                }
                .padding(20)
            }
            .navigationTitle(isGerman ? "Premium-Kontingente" : "Premium allowances")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.done.localized) { dismiss() }
                }
            }
        }
    }
}
