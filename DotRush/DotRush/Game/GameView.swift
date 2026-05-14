import SwiftUI
import SpriteKit

struct GameView: View {
    @Binding var gameState: GameState
    @EnvironmentObject var livesManager: LivesManager
    @EnvironmentObject var storeManager: StoreManager

    @State private var finalScore = 0
    @State private var scene: GameScene?

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            // Pause button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        gameState = .paused
                        scene?.isPaused = true
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                            .background(Circle().fill(.white.opacity(0.15)))
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
        }
        .onAppear {
            let s = GameScene(size: UIScreen.main.bounds.size)
            s.scaleMode = .resizeFill
            s.gameDelegate = GameSceneCoordinator(onEnd: { score in
                finalScore = score
                gameState = .gameOver
            })
            s.configure(lives: livesManager.lives)
            scene = s
            _ = livesManager.useLife()
        }
    }
}

// Bridges SpriteKit delegate to SwiftUI
class GameSceneCoordinator: NSObject, GameSceneDelegate {
    let onEnd: (Int) -> Void
    init(onEnd: @escaping (Int) -> Void) { self.onEnd = onEnd }
    func gameDidEnd(score: Int) { DispatchQueue.main.async { self.onEnd(score) } }
    func gameDidPause() {}
}
