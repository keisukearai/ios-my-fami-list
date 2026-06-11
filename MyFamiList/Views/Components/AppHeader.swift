import SwiftUI

struct AppHeader<Top: View, Right: View>: View {
    let title: String
    let sub: String?
    let onBack: (() -> Void)?
    let top: Top
    let right: Right

    init(
        _ title: String,
        sub: String? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder top: () -> Top,
        @ViewBuilder right: () -> Right
    ) {
        self.title = title
        self.sub = sub
        self.onBack = onBack
        self.top = top()
        self.right = right()
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.primary.opacity(0.08))
                .frame(width: 210, height: 210)
                .offset(x: 32, y: -60)

            VStack(alignment: .leading, spacing: 10) {
                top
                HStack(alignment: .bottom, spacing: 0) {
                    HStack(alignment: .center, spacing: 6) {
                        if let onBack {
                            Button(action: onBack) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(AppTheme.primary)
                            }
                            .padding(.trailing, 2)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundStyle(AppTheme.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            if let sub {
                                Text(sub)
                                    .font(.system(size: 13.5, weight: .medium))
                                    .foregroundStyle(AppTheme.textSec)
                            }
                        }
                    }
                    Spacer(minLength: 12)
                    right.padding(.bottom, 4)
                }
                .frame(minHeight: 48)
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipped()
        .background {
            AppTheme.soft
                .clipShape(UnevenRoundedRectangle(
                    bottomLeadingRadius: AppTheme.rCard + 10,
                    bottomTrailingRadius: AppTheme.rCard + 10
                ))
                .ignoresSafeArea(edges: .top)
        }
    }
}

extension AppHeader where Top == EmptyView, Right == EmptyView {
    init(_ title: String, sub: String? = nil, onBack: (() -> Void)? = nil) {
        self.init(title, sub: sub, onBack: onBack, top: { EmptyView() }, right: { EmptyView() })
    }
}

extension AppHeader where Right == EmptyView {
    init(_ title: String, sub: String? = nil, onBack: (() -> Void)? = nil, @ViewBuilder top: () -> Top) {
        self.init(title, sub: sub, onBack: onBack, top: top, right: { EmptyView() })
    }
}

extension AppHeader where Top == EmptyView {
    init(_ title: String, sub: String? = nil, onBack: (() -> Void)? = nil, @ViewBuilder right: () -> Right) {
        self.init(title, sub: sub, onBack: onBack, top: { EmptyView() }, right: right)
    }
}
