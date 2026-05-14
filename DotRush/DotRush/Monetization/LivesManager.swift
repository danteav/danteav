import Foundation
import Combine

class LivesManager: ObservableObject {
    static let maxLives = 5
    static let refillIntervalSeconds: TimeInterval = 30 * 60 // 30 min per life

    @Published var lives: Int
    @Published var nextLifeRefillDate: Date?

    private var timer: AnyCancellable?
    private let livesKey = "com.dotrush.lives"
    private let refillDateKey = "com.dotrush.refillDate"

    init() {
        let saved = UserDefaults.standard.integer(forKey: "com.dotrush.lives")
        lives = saved > 0 ? saved : LivesManager.maxLives

        if let date = UserDefaults.standard.object(forKey: "com.dotrush.refillDate") as? Date {
            nextLifeRefillDate = date
        }

        startRefillTimer()
    }

    func useLife() -> Bool {
        guard lives > 0 else { return false }
        lives -= 1
        save()
        if lives < LivesManager.maxLives && nextLifeRefillDate == nil {
            scheduleNextRefill()
        }
        return true
    }

    func addLives(_ count: Int) {
        lives = min(lives + count, LivesManager.maxLives)
        if lives == LivesManager.maxLives {
            nextLifeRefillDate = nil
            timer?.cancel()
        }
        save()
    }

    var timeUntilNextLife: String {
        guard let date = nextLifeRefillDate else { return "" }
        let remaining = max(0, date.timeIntervalSinceNow)
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func scheduleNextRefill() {
        let date = Date().addingTimeInterval(LivesManager.refillIntervalSeconds)
        nextLifeRefillDate = date
        UserDefaults.standard.set(date, forKey: refillDateKey)
    }

    private func startRefillTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkRefill()
            }
    }

    private func checkRefill() {
        guard let date = nextLifeRefillDate, Date() >= date else { return }
        if lives < LivesManager.maxLives {
            lives += 1
            save()
        }
        if lives < LivesManager.maxLives {
            scheduleNextRefill()
        } else {
            nextLifeRefillDate = nil
            UserDefaults.standard.removeObject(forKey: refillDateKey)
        }
    }

    private func save() {
        UserDefaults.standard.set(lives, forKey: livesKey)
    }
}
