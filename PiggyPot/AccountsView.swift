import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: Store
    @AppStorage("appearance") private var appearance = 0

    @State private var editingWallet: Wallet?
    @State private var showNew = false

    var body: some View {
        List {
            Section {
                if store.wallets.isEmpty {
                    Text("还没有账户")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.wallets) { wallet in
                    NavigationLink {
                        AccountEditorView(wallet: wallet)
                            .environmentObject(store)
                    } label: {
                        HStack(spacing: 12) {
                            WalletBadge(wallet: wallet, size: 32)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(wallet.name)
                                    .font(.system(size: 16))
                                Text("初始 \(Money.text(wallet.initialCents)) · \(countText(wallet))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Money.text(store.balance(wallet.id)))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: delete)
                .onMove(perform: store.moveWallets)
            } header: {
                Text("账户")
            } footer: {
                Text("删除账户会一并删掉这个账户下的记录。")
            }

            Section("外观") {
                Picker("外观", selection: $appearance) {
                    Text("自动").tag(0)
                    Text("浅色").tag(1)
                    Text("深色").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 0)
                    .listRowBackground(Color.clear)
            } footer: {
                Text("存钱罐 1.0.0 · 只做记录，不联网、不存钱。")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("账户管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNew = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showNew) {
            AccountEditorView(wallet: nil)
                .environmentObject(store)
        }
    }

    private func countText(_ wallet: Wallet) -> String {
        let count = store.entries(for: wallet.id).count
        return "\(count) 笔记录"
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            store.deleteWallet(store.wallets[index])
        }
    }
}
