import Foundation
import UIKit

// AdManager integrates with Google AdMob.
// Setup: Add GoogleMobileAds SDK via SPM (https://github.com/googleads/swift-package-manager-google-mobile-ads)
// Replace placeholder IDs with real AdMob unit IDs from admob.google.com
// Add GADApplicationIdentifier in Info.plist with your AdMob App ID

class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // Replace with real AdMob unit ID
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // AdMob test ID

    @Published var isAdReady = false
    @Published var isShowingAd = false

    private var rewardCompletion: ((Bool) -> Void)?

    // MARK: - Rewarded Ad

    // Call this on app launch and after each ad is shown
    func loadRewardedAd() {
        // GADRewardedAd.load(withAdUnitID: AdManager.rewardedAdUnitID, request: GADRequest()) { [weak self] ad, error in
        //     guard let self else { return }
        //     if let error { print("Rewarded ad failed: \(error)"); return }
        //     self.rewardedAd = ad
        //     self.rewardedAd?.fullScreenContentDelegate = self
        //     DispatchQueue.main.async { self.isAdReady = true }
        // }

        // Simulated for builds without AdMob SDK
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAdReady = true
        }
    }

    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard isAdReady else { completion(false); return }
        rewardCompletion = completion
        isShowingAd = true

        // With real AdMob SDK:
        // rewardedAd?.present(fromRootViewController: viewController) { [weak self] in
        //     completion(true)
        //     self?.isShowingAd = false
        //     self?.isAdReady = false
        //     self?.loadRewardedAd()
        // }

        // Simulated 5-second ad
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.isAdReady = false
            self.isShowingAd = false
            completion(true)
            self.loadRewardedAd()
        }
    }

    // MARK: - Banner Ad
    // In your SwiftUI view embed a UIViewRepresentable wrapping GADBannerView
    // Banner unit ID (test): ca-app-pub-3940256099942544/2934735716
}
