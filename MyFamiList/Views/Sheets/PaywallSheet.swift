import SwiftUI
import StoreKit

struct PaywallSheet: View {
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.dismiss) private var dismiss
    @State private var product: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    featuresSection
                    Spacer(minLength: 0)
                    purchaseSection
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("FamiList Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("Cancel")) { dismiss() }
                }
            }
        }
        .task {
            product = await purchaseService.loadProduct()
        }
        .alert(loc("Error"), isPresented: $showingError) {
            Button(loc("OK")) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: purchaseService.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("Upgrade to FamiList Pro")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Unlock all features for your family")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProFeatureRow(icon: "person.3.fill", text: loc("Create unlimited groups"))
            ProFeatureRow(icon: "list.bullet", text: loc("Create unlimited lists"))
            ProFeatureRow(icon: "person.badge.plus", text: loc("Invite unlimited members"))
        }
        .padding(20)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await performPurchase() }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(purchaseButtonLabel)
                    }
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor)
                )
            }
            .disabled(isPurchasing)
            .padding(.horizontal)

            Button(loc("Restore Purchase")) {
                Task { await performRestore() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Link(loc("Privacy Policy"), destination: URL(string: "https://kotoragk.com/familist/privacy")!)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var purchaseButtonLabel: String {
        if let product {
            return "\(product.displayPrice) で購入（買い切り）"
        }
        return "読み込み中…"
    }

    private func performPurchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await purchaseService.purchase()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func performRestore() async {
        do {
            try await purchaseService.restore()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            Text(text)
                .font(.body)
        }
    }
}
