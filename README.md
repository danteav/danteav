# Dot Rush — iPhone Game

Addictive one-tap endless runner with a full monetization system.

## Gameplay

- Tap the screen to make the dot jump
- Avoid blue column and floating obstacles
- Collect gold coins for bonus points
- Speed increases every 10 seconds
- Score runs continuously — compete for your high score

## Monetization (how you make money)

### Rewarded Video Ads (highest revenue potential)
- Players watch a ~30 second ad to earn a free life
- Powered by **Google AdMob** (rewarded ad format pays $5–$25 CPM)
- Ad shown on Game Over screen when player has 0 lives
- Also available in the Shop at any time

### In-App Purchases (StoreKit 2)
| Product | ID | Price |
|---|---|---|
| 5 Lives | `com.dotrush.lives5` | $0.99 |
| 20 Lives | `com.dotrush.lives20` | $2.99 |
| Remove Ads | `com.dotrush.removeads` | $1.99 |
| Unlimited Lives | `com.dotrush.unlimited` | $4.99 |

### Life Refill Timer
- Players start with 5 lives
- 1 life refills every 30 minutes (automatically, like Candy Crush)
- Encourages daily return visits

## Setup in Xcode

### 1. Open the project
```
open DotRush/DotRush.xcodeproj
```

### 2. Set your Team & Bundle ID
- Select the `DotRush` target → Signing & Capabilities
- Set your Apple Developer Team
- Change Bundle Identifier to something unique (e.g. `com.yourname.dotrush`)

### 3. Configure AdMob (for real ads)
1. Create account at [admob.google.com](https://admob.google.com)
2. Create an iOS app in AdMob → get your **App ID**
3. Replace `GADApplicationIdentifier` in `Info.plist`
4. Create a Rewarded ad unit → replace `rewardedAdUnitID` in `AdManager.swift`
5. Add the AdMob SDK via Swift Package Manager:
   - URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads`
   - Uncomment the real AdMob code in `AdManager.swift`

### 4. Configure In-App Purchases
1. In [App Store Connect](https://appstoreconnect.apple.com), create your app
2. Go to In-App Purchases → add the 4 product IDs listed above
3. Set prices and descriptions
4. The `StoreManager.swift` handles all StoreKit 2 logic automatically

### 5. Add In-App Purchase capability
- Target → Signing & Capabilities → + Capability → In-App Purchase

## Project Structure

```
DotRush/
├── DotRushApp.swift          # App entry point
├── Views/
│   ├── ContentView.swift     # Navigation hub
│   ├── MainMenuView.swift    # Start screen with lives display
│   ├── GameOverView.swift    # End screen with monetization options
│   ├── StoreView.swift       # Full shop UI
│   └── PauseView.swift       # Pause overlay
├── Game/
│   ├── GameView.swift        # SpriteKit wrapper
│   └── GameScene.swift       # Core game logic
└── Monetization/
    ├── LivesManager.swift    # Lives + auto-refill timer
    ├── StoreManager.swift    # StoreKit 2 IAP
    └── AdManager.swift       # AdMob rewarded ads
```

## Revenue Projections (rough estimates)

With 1,000 daily active users:
- Rewarded ads: ~500 ad views/day × $0.01–$0.02 = **$5–$10/day**
- IAP conversions at 2%: 20 purchases × avg $2 = **$40/day**
- Monthly potential: **$1,000–$1,500/month**

Scale to 10K DAU → $10K–$15K/month.

## Requirements

- Xcode 15+
- iOS 16+ deployment target
- Apple Developer account ($99/year) to submit to App Store
