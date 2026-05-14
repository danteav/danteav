import SwiftUI

struct MainMenuView: View {
    @Binding var gameState: GameState
    @EnvironmentObject var livesManager: LivesManager
    @State private var showStore = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.12), Color(red: 0.1, green: 0.05, blue: 0.2)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("DOT")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("RUSH")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(red: 1, green: 0.3, blue: 0.5), Color(red: 0.6, green: 0.2, blue: 1)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                }
                .scaleEffect(pulse ? 1.03 : 1)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }

                Spacer().frame(height: 50)

                // Dot preview animation
                DotPreviewAnimation()

                Spacer().frame(height: 50)

                // Lives indicator
                HStack(spacing: 4) {
                    ForEach(0..<LivesManager.maxLives, id: \.self) { i in
                        Image(systemName: i < livesManager.lives ? "heart.fill" : "heart")
                            .foregroundColor(i < livesManager.lives ? Color(red: 1, green: 0.3, blue: 0.5) : .gray)
                            .font(.title3)
                    }
                    if livesManager.lives < LivesManager.maxLives {
                        Text("  +\(livesManager.timeUntilNextLife)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 24)

                // Play button
                Button {
                    if livesManager.lives > 0 {
                        gameState = .playing
                    } else {
                        showStore = true
                    }
                } label: {
                    Text(livesManager.lives > 0 ? "PLAY" : "GET LIVES")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 220, height: 60)
                        .background(
                            livesManager.lives > 0
                            ? LinearGradient(colors: [Color(red: 1, green: 0.3, blue: 0.5), Color(red: 0.8, green: 0.1, blue: 0.7)],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 1, green: 0.3, blue: 0.5).opacity(0.5), radius: 15)
                }

                Spacer().frame(height: 16)

                // Shop button
                Button { showStore = true } label: {
                    Label("Shop", systemImage: "bag.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 1, green: 0.85, blue: 0))
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
                }

                Spacer()

                Text("Tap to jump • Avoid obstacles • Collect coins")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 30)
        }
        .sheet(isPresented: $showStore) {
            StoreView()
        }
    }
}

struct DotPreviewAnimation: View {
    @State private var yOffset: CGFloat = 0
    @State private var obstacles: [CGFloat] = [300, 500]

    var body: some View {
        ZStack {
            // Ground line
            Rectangle()
                .fill(Color(red: 0.2, green: 0.8, blue: 0.6))
                .frame(height: 3)
                .frame(maxWidth: .infinity)
                .offset(y: 30)

            // Player dot
            Circle()
                .fill(Color(red: 1, green: 0.3, blue: 0.5))
                .frame(width: 28, height: 28)
                .offset(x: -80, y: yOffset)
                .shadow(color: Color(red: 1, green: 0.3, blue: 0.5).opacity(0.6), radius: 8)

            // Obstacle
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.2, green: 0.7, blue: 1))
                .frame(width: 18, height: 50)
                .offset(x: 60, y: 6)
        }
        .frame(height: 80)
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                yOffset = -30
            }
        }
    }
}
