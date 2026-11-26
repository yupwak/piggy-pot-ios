import SwiftUI

struct WishlistView: View {
    @EnvironmentObject private var store: Store

    @State private var showNew = false
    @State private var editing: Wish?
    @State private var depositing: Wish?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    summaryCard

                    if store.wishes.isEmpty {
                        emptyCard
                    } else {
                        ForEach(store.wishes) { wish in
                            wishCard(wish)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("心愿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNew) {
                WishEditorView(wish: nil)
                    .environmentObject(store)
            }
            .sheet(item: $editing) { wish in
                WishEditorView(wish: wish)
                    .environmentObject(store)
            }
            .sheet(item: $depositing) { wish in
                WishDepositView(wish: wish)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - 汇总

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("一共攒了")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.wishes.count) 个心愿")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            Text(Money.text(store.totalWishSaved))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
            if store.totalWishTarget > 0 {
                Text("目标 \(Money.text(store.totalWishTarget))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .card(padding: 16)
    }

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)
            Text("还没有心愿")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text("把想买的东西加进来，标上价格，\n然后一笔一笔往里攒。")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button {
                showNew = true
            } label: {
                Text("加一个心愿")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 18)
                    .frame(height: 36)
                    .background(Color(hex: "F09E2E"), in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .card()
    }

    // MARK: - 心愿卡片

    private func wishCard(_ wish: Wish) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(hex: wish.colorHex).gradient)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: wish.symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(wish.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(subtitle(wish))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if !wish.isDone {
                    Button {
                        depositing = wish
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color(hex: wish.colorHex))
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.green)
                }
            }

            progressBar(wish)

            HStack(alignment: .firstTextBaseline) {
                Text(Money.text(wish.savedCents))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("/ \(Money.text(wish.targetCents))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(wish.progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .card(padding: 14)
        .onTapGesture {
            editing = wish
        }
    }

    private func progressBar(_ wish: Wish) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                Capsule(style: .continuous)
                    .fill(Color(hex: wish.colorHex).gradient)
                    .frame(width: max(6, geo.size.width * wish.progress))
            }
        }
        .frame(height: 8)
    }

    private func subtitle(_ wish: Wish) -> String {
        if wish.isDone { return "已经攒够了" }
        var parts: [String] = []
        parts.append("还差 \(Money.text(wish.remainingCents))")
        if let deadline = wish.deadline {
            let days = Calendar.current.dateComponents([.day], from: DateText.startOfDay(Date()), to: DateText.startOfDay(deadline)).day ?? 0
            if days >= 0 {
                parts.append(days == 0 ? "今天到期" : "还有 \(days) 天")
            } else {
                parts.append("已过期")
            }
        }
        return parts.joined(separator: " · ")
    }
}
