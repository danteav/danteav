import SwiftUI

struct PauseView: View {
    @Binding var gameState: GameState
    @State private var scene: GameScene?

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Button {
                    gameState = .playing
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 52)
                        .background(Capsule().fill(Color(red: 1, green: 0.3, blue: 0.5)))
                }

                Button {
                    gameState = .menu
                } label: {
                    Text("Main Menu")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
