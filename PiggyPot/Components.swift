import SwiftUI

/// 账户图标：彩色圆 + 白色符号
struct WalletBadge: View {
    let wallet: Wallet
    var size: CGFloat = 26

    var body: some View {
        Circle()
            .fill(wallet.color.gradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: wallet.symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}

/// 卡片底：系统分组色 + 20 圆角
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    var corner: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

extension View {
    func card(padding: CGFloat = 16, corner: CGFloat = 20) -> some View {
        modifier(CardBackground(padding: padding, corner: corner))
    }
}

/// 区块小标题
struct BlockTitle: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }
}

/// 一条记录
struct EntryRow: View {
    let entry: Entry
    let wallet: Wallet?
    var showsTime = true

    var body: some View {
        HStack(spacing: 12) {
            if let wallet {
                WalletBadge(wallet: wallet, size: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.note.isEmpty ? (wallet?.name ?? "未命名") : entry.note)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(Money.signedText(entry.signedCents))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(entry.kind == .income ? Color.green : Color.primary)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        var parts: [String] = []
        if let wallet { parts.append(wallet.name) }
        if showsTime { parts.append(DateText.clock.string(from: entry.date)) }
        return parts.joined(separator: " · ")
    }
}

/// 空状态
struct EmptyHint: View {
    let symbol: String
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            if let detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
