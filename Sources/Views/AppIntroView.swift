import SwiftUI

struct AppIntroView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    var onFinished: () -> Void

    @State private var storyIndex = 0
    @State private var slide3ImageIndex = 0

    private let storyCount = 4
    private let slide3Images = ["intro-slide-3a", "intro-slide-3b", "intro-slide-3c"]

    private var isCarouselStory: Bool { storyIndex == 3 }
    private var isLastPage: Bool {
        isCarouselStory && slide3ImageIndex >= slide3Images.count - 1
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.5, blue: 0.3),
                    Color(red: 0.85, green: 0.4, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button {
                            finish()
                        } label: {
                            Text(L.skip.localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .accessibilityLabel(L.skip.localized)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(height: 44)

                TabView(selection: $storyIndex) {
                    storyContent(
                        imageName: "penguin-chef",
                        textKey: L.intro_slide1,
                        isScreenshot: false
                    )
                    .tag(0)

                    storyContent(
                        imageName: "intro-slide-2",
                        textKey: L.intro_slide2,
                        isScreenshot: true
                    )
                    .tag(1)

                    storyContent(
                        imageName: "intro-slide-4",
                        textKey: L.intro_slide4,
                        isScreenshot: true
                    )
                    .tag(2)

                    carouselContent
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<storyCount, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(index == storyIndex ? 1 : 0.35))
                            .frame(width: index == storyIndex ? 22 : 8, height: 8)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: storyIndex)
                .padding(.bottom, 20)

                Button {
                    advance()
                } label: {
                    Text(isLastPage ? L.getStarted.localized : L.next.localized)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2))
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .id(localizationManager.currentLanguage)
            }
        }
    }

    private func storyContent(imageName: String, textKey: String, isScreenshot: Bool) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)
            if isScreenshot {
                screenshotFrame(imageName: imageName)
            } else {
                penguinImage(imageName: imageName)
            }
            headline(textKey, large: !isScreenshot)
            Spacer(minLength: 8)
        }
    }

    private var carouselContent: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)
            screenshotFrame(imageName: slide3Images[slide3ImageIndex])
                .transaction { $0.animation = nil }
            HStack(spacing: 6) {
                ForEach(0..<slide3Images.count, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(slide3ImageIndex == index ? 1 : 0.35))
                        .frame(width: 7, height: 7)
                }
            }
            headline(L.intro_slide3, large: false)
            Spacer(minLength: 8)
        }
    }

    private func headline(_ key: String, large: Bool) -> some View {
        Text(verbatim: key.localized)
            .font(.system(size: large ? 28 : 22, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .id("\(localizationManager.currentLanguage)-\(key)")
    }

    private func advance() {
        if isCarouselStory && slide3ImageIndex < slide3Images.count - 1 {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                slide3ImageIndex += 1
            }
            return
        }
        if storyIndex < storyCount - 1 {
            storyIndex += 1
            slide3ImageIndex = 0
        } else {
            finish()
        }
    }

    private func penguinImage(imageName: String) -> some View {
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 240, height: 240)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func screenshotFrame(imageName: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                shape
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.55))
                    )
                    .aspectRatio(9 / 19.5, contentMode: .fit)
            }
        }
        .clipShape(shape)
        .overlay(shape.stroke(Color.white.opacity(0.45), lineWidth: 2))
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
        .padding(.horizontal, 52)
        .accessibilityHidden(true)
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: AppIntroView.completedKey)
        onFinished()
    }

    static let completedKey = "app_intro_completed"

    static var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }
}
