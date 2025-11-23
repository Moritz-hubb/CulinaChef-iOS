import SwiftUI

struct LoadingView: View {
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
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
            
            VStack(spacing: 24) {
                Spacer()
                
                // App Name with gradient
                Text("CulinaAi")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Animated loading bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                        
                        // Animated progress bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(width: 200, height: 4)
                
                Spacer()
            }
        }
        .onAppear {
            // Start continuous animation from 0 to 1 and back
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                progress = 1.0
            }
        }
    }
}

#Preview {
    LoadingView()
}

