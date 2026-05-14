import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var livesManager: LivesManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.14).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Current lives banner
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Your Lives")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.gray)
                                HStack(spacing: 4) {
                                    ForEach(0..<LivesManager.maxLives, id: \.self) { i in
                                        Image(systemName: i < livesManager.lives ? "heart.fill" : "heart")
                                            .foregroundColor(i < livesManager.lives ? Color(red: 1, green: 0.3, blue: 0.5) : .gray)
                                    }
                                }
                            }
                            Spacer()
                            if !livesManager.timeUntilNextLife.isEmpty {
                                VStack(alignment: .trailing) {
                                    Text("Next life")
                                        .font(.caption).foregroundColor(.gray)
                                    Text(livesManager.timeUntilNextLife)
                                        .font(.title3.monospacedDigit().bold())
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))

                        // Watch ad section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Free Option", icon: "gift.fill", color: .green)
                            WatchAdCard()
                        }

                        // IAP products
                        if !storeManager.products.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Lives Packs", icon: "heart.fill", color: Color(red: 1, green: 0.3, blue: 0.5))
                                ForEach(storeManager.products.filter { $0.id.contains("lives") }, id: \.id) { product in
                                    ProductCard(product: product) {
                                        purchaseProduct(product)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Premium", icon: "star.fill", color: Color(red: 1, green: 0.85, blue: 0))
                                ForEach(storeManager.products.filter { !$0.id.contains("lives") }, id: \.id) { product in
                                    PremiumProductCard(product: product,
                                                       isPurchased: storeManager.purchasedProductIDs.contains(product.id)) {
                                        purchaseProduct(product)
                                    }
                                }
                            }
                        } else {
                            // Fallback when no StoreKit products loaded (simulator / no App Store Connect setup)
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Lives Packs", icon: "heart.fill", color: Color(red: 1, green: 0.3, blue: 0.5))
                                MockProductCard(title: "5 Lives", price: "$0.99", icon: "❤️❤️❤️❤️❤️") { livesManager.addLives(5) }
                                MockProductCard(title: "20 Lives", price: "$2.99", icon: "💯", badge: "BEST VALUE") { livesManager.addLives(20) }
                            }
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Premium", icon: "star.fill", color: Color(red: 1, green: 0.85, blue: 0))
                                MockProductCard(title: "Remove Ads", price: "$1.99", icon: "🚫") {}
                                MockProductCard(title: "Unlimited Lives", price: "$4.99", icon: "♾️", badge: "POPULAR") {}
                            }
                        }

                        Button { Task { await storeManager.restorePurchases() } } label: {
                            Text("Restore Purchases")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(red: 1, green: 0.3, blue: 0.5))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func purchaseProduct(_ product: Product) {
        Task {
            await storeManager.purchase(product)
            // Grant lives for consumables
            let livesGranted = storeManager.livesForProduct(ProductID(rawValue: product.id) ?? .fiveLives)
            if livesGranted > 0 { livesManager.addLives(livesGranted) }
        }
    }
}

struct SectionHeader: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline.weight(.bold))
            .foregroundColor(color)
    }
}

struct WatchAdCard: View {
    @State private var isWatching = false
    @State private var done = false
    @EnvironmentObject var livesManager: LivesManager

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.green.opacity(0.2)).frame(width: 50, height: 50)
                Image(systemName: "play.rectangle.fill").foregroundColor(.green).font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Watch a Short Ad")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(done ? "✓ Reward claimed" : "Earn 1 free life • Takes ~30 sec")
                    .font(.caption)
                    .foregroundColor(done ? .green : .gray)
            }
            Spacer()
            if !done {
                Button {
                    isWatching = true
                    AdManager.shared.showRewardedAd(from: UIViewController()) { rewarded in
                        DispatchQueue.main.async {
                            isWatching = false
                            if rewarded { livesManager.addLives(1); done = true }
                        }
                    }
                } label: {
                    Text(isWatching ? "..." : "Watch")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color.green))
                }
                .disabled(isWatching)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 1))
    }
}

struct ProductCard: View {
    let product: Product; let action: () -> Void
    var body: some View {
        HStack {
            Image(systemName: "heart.fill").foregroundColor(Color(red: 1, green: 0.3, blue: 0.5)).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName).font(.headline).foregroundColor(.white)
                Text(product.description).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Button(action: action) {
                Text(product.displayPrice)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color(red: 1, green: 0.3, blue: 0.5)))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
    }
}

struct PremiumProductCard: View {
    let product: Product; let isPurchased: Bool; let action: () -> Void
    var body: some View {
        HStack {
            Image(systemName: isPurchased ? "checkmark.seal.fill" : "star.fill")
                .foregroundColor(Color(red: 1, green: 0.85, blue: 0)).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName).font(.headline).foregroundColor(.white)
                Text(product.description).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            if isPurchased {
                Text("Owned").font(.subheadline.bold()).foregroundColor(.green)
            } else {
                Button(action: action) {
                    Text(product.displayPrice)
                        .font(.subheadline.bold()).foregroundColor(.black)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color(red: 1, green: 0.85, blue: 0)))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
    }
}

struct MockProductCard: View {
    let title: String; let price: String; let icon: String
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        HStack {
            Text(icon).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.headline).foregroundColor(.white)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(Color(red: 1, green: 0.85, blue: 0)))
                    }
                }
                Text("Tap to purchase").font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Button(action: action) {
                Text(price)
                    .font(.subheadline.bold()).foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color(red: 1, green: 0.3, blue: 0.5)))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
    }
}
