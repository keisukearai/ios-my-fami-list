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
                    Button("キャンセル") { dismiss() }
                }
            }
        }
        .task {
            product = await purchaseService.loadProduct()
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK") {}
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

            Text("FamiList Pro にアップグレード")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("家族みんなで使える\nすべての機能をロック解除")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProFeatureRow(icon: "person.3.fill", text: "グループを何個でも作成できる")
            ProFeatureRow(icon: "list.bullet", text: "リストを何個でも作成できる")
            ProFeatureRow(icon: "person.badge.plus", text: "メンバーを何人でも招待できる")
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

            Button("購入を復元") {
                Task { await performRestore() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Link("プライバシーポリシー", destination: URL(string: "https://kotoragk.com/familist/privacy")!)
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
