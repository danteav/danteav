import SwiftUI

struct ContentView: View {
    @EnvironmentObject var livesManager: LivesManager
    @State private var gameState: GameState = .menu

    var body: some View {
        ZStack {
            switch gameState {
            case .menu:
                MainMenuView(gameState: $gameState)
            case .playing:
                GameView(gameState: $gameState)
            case .gameOver:
                GameOverView(gameState: $gameState)
            case .paused:
                PauseView(gameState: $gameState)
            }
        }
        .ignoresSafeArea()
    }
}

enum GameState {
    case menu, playing, gameOver, paused
}
