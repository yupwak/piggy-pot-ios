import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @State private var showAdd = false
    @State private var selectedWallet: Wallet?
    @State private var showAll = false

    private var recent: [Entry] { Array(store.entries.prefix(6)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    totalCard
                    walletsGrid
                    BlockTitle(title: "最近记录", trailing: store.entries.isEmpty ? nil : "共 \(store.entries.count) 笔")
                    recentCard
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("存钱罐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AccountsView()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .medium))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addBar
            }
            .sheet(isPresented: $showAdd) {
                AddEntryView()
                    .environmentObject(store)
            }
            .navigationDestination(item: $selectedWallet) { wallet in
                HistoryView(wallet: wallet)
                    .environmentObject(store)
            }
            .navigationDestination(isPresented: $showAll) {
                HistoryView(wallet: nil)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - 总资产

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("总资产")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.wallets.count) 个账户")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Text(Money.text(store.totalCents))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            HStack(spacing: 22) {
                stat("本月收入", Money.text(store.monthIncomeCents), .green)
                stat("本月支出", Money.text(store.monthExpenseCents), .red)
            }
        }
        .card(padding: 18)
    }

    private func stat(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
    }

    // MARK: - 账户

    private var walletsGrid: some View {
        VStack(spacing: 10) {
            if store.wallets.isEmpty {
                EmptyHint(symbol: "wallet.pass", title: "还没有账户", detail: "右上角进账户管理，先把支付宝、微信加上")
                    .card()
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)],
                          spacing: 10) {
                    ForEach(store.wallets) { wallet in
                        Button {
                            selectedWallet = wallet
                        } label: {
                            walletCard(wallet)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func walletCard(_ wallet: Wallet) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                WalletBadge(wallet: wallet, size: 22)
                Text(wallet.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            Text(Money.text(store.balance(wallet.id)))
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 14, corner: 18)
    }

    // MARK: - 最近记录

    private var recentCard: some View {
        VStack(spacing: 0) {
            if recent.isEmpty {
                EmptyHint(symbol: "tray", title: "还没有记录", detail: "点下面的「记一笔」开始")
            } else {
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, entry in
                    EntryRow(entry: entry, wallet: store.wallet(entry.walletID))
                    if index < recent.count - 1 {
                        Divider().padding(.leading, 44)
                    }
                }
                if store.entries.count > recent.count {
                    Divider()
                    Button {
                        showAll = true
                    } label: {
                        HStack {
                            Text("全部记录")
                                .font(.system(size: 15))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(Color(hex: "F09E2E"))
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card(padding: 16)
    }

    private var footer: some View {
        Text("记录只存在这台手机上，不上传、不同步。")
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    // MARK: - 底部按钮

    private var addBar: some View {
        Button {
            showAdd = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                Text("记一笔")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(hex: "F09E2E"))
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color(.systemGroupedBackground))
    }
}
