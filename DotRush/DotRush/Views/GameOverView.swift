import SwiftUI

struct GameOverView: View {
    @Binding var gameState: GameState
    @EnvironmentObject var livesManager: LivesManager
    @EnvironmentObject var storeManager: StoreManager

    @AppStorage("highScore") private var highScore = 0
    @State private var finalScore: Int = 0
    @State private var showStore = false
    @State private var isWatchingAd = false
    @State private var adWatched = false
    @State private var showAdSuccess = false
    @State private var appearAnim = false

    var isNewHighScore: Bool { finalScore > highScore }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Score card
                VStack(spacing: 12) {
                    Text(isNewHighScore ? "NEW BEST!" : "GAME OVER")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(isNewHighScore ? Color(red: 1, green: 0.85, blue: 0) : .white)

                    Text("\(finalScore)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(red: 1, green: 0.3, blue: 0.5), Color(red: 0.6, green: 0.2, blue: 1)],
                                           startPoint: .leading, endPoint: .trailing)
                        )

                    HStack(spacing: 20) {
                        VStack {
                            Text("BEST")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.gray)
                            Text("\(max(highScore, finalScore))")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        Divider().frame(height: 30).background(.gray)
                        VStack {
                            Text("LIVES")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.gray)
                            HStack(spacing: 2) {
                                ForEach(0..<min(livesManager.lives, 5), id: \.self) { _ in
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(Color(red: 1, green: 0.3, blue: 0.5))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                .padding(28)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .scaleEffect(appearAnim ? 1 : 0.8)
                .opacity(appearAnim ? 1 : 0)

                Spacer().frame(height: 40)

                // Continue options
                VStack(spacing: 14) {
                    if livesManager.lives > 0 {
                        // Play again with a life
                        ActionButton(
                            title: "PLAY AGAIN",
                            subtitle: "Uses 1 life (\(livesManager.lives) left)",
                            icon: "play.fill",
                            gradient: [Color(red: 1, green: 0.3, blue: 0.5), Color(red: 0.8, green: 0.1, blue: 0.7)]
                        ) {
                            gameState = .playing
                        }
                    } else {
                        // No lives — monetization options
                        Text("You're out of lives!")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if !storeManager.hasUnlimitedLives {
                            // Watch ad for free life
                            if !adWatched {
                                ActionButton(
                                    title: "WATCH AD",
                                    subtitle: "Free • Get 1 life instantly",
                                    icon: "play.rectangle.fill",
                                    gradient: [Color(red: 0.2, green: 0.7, blue: 1), Color(red: 0.1, green: 0.4, blue: 0.9)]
                                ) {
                                    watchAd()
                                }
                                .disabled(isWatchingAd)
                                .overlay(isWatchingAd ? ProgressView().tint(.white) : nil)
                            } else {
                                Text("✓ Thanks for watching!")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }

                            // Buy lives
                            ActionButton(
                                title: "BUY LIVES",
                                subtitle: "Starting at $0.99",
                                icon: "bag.fill",
                                gradient: [Color(red: 1, green: 0.85, blue: 0), Color(red: 1, green: 0.6, blue: 0)]
                            ) {
                                showStore = true
                            }
                        }
                    }

                    // Wait for refill
                    if livesManager.lives < LivesManager.maxLives && !livesManager.timeUntilNextLife.isEmpty {
                        HStack {
                            Image(systemName: "clock")
                            Text("Next life in \(livesManager.timeUntilNextLife)")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)

                Spacer().frame(height: 24)

                // Menu button
                Button {
                    gameState = .menu
                } label: {
                    Text("Main Menu")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            // Grab score from UserDefaults written by GameScene
            finalScore = UserDefaults.standard.integer(forKey: "lastScore")
            if finalScore > highScore { highScore = finalScore }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) { appearAnim = true }
        }
        .sheet(isPresented: $showStore) { StoreView() }
        .alert("Ad Complete!", isPresented: $showAdSuccess) {
            Button("Let's Go!") { gameState = .playing }
        } message: {
            Text("You earned 1 life. Good luck!")
        }
    }

    private func watchAd() {
        isWatchingAd = true
        AdManager.shared.showRewardedAd(from: topViewController()) { rewarded in
            DispatchQueue.main.async {
                isWatchingAd = false
                if rewarded {
                    adWatched = true
                    livesManager.addLives(1)
                    showAdSuccess = true
                }
            }
        }
    }

    private func topViewController() -> UIViewController {
        let scenes = UIApplication.shared.connectedScenes
        let scene = scenes.first as? UIWindowScene
        return scene?.windows.first?.rootViewController ?? UIViewController()
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: gradient.first?.opacity(0.4) ?? .clear, radius: 10, y: 4)
        }
    }
}
