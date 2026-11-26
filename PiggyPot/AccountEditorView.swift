import SwiftUI

struct AccountEditorView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    private let original: Wallet?

    @State private var name: String
    @State private var symbol: String
    @State private var colorHex: String
    @State private var initialText: String
    @State private var showDelete = false

    init(wallet: Wallet?) {
        original = wallet
        _name = State(initialValue: wallet?.name ?? "")
        _symbol = State(initialValue: wallet?.symbol ?? Symbols.items[0])
        _colorHex = State(initialValue: wallet?.colorHex ?? Palette.colors[0].hex)
        _initialText = State(initialValue: Money.editable(wallet?.initialCents ?? 0))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color(hex: colorHex).gradient)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: symbol)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                        TextField("账户名，比如 支付宝", text: $name)
                            .font(.system(size: 17))
                    }
                    .padding(.vertical, 4)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                        ForEach(Symbols.items, id: \.self) { item in
                            Button {
                                symbol = item
                            } label: {
                                Image(systemName: item)
                                    .font(.system(size: 19))
                                    .frame(width: 38, height: 38)
                                    .foregroundStyle(symbol == item ? Color.white : Color.secondary)
                                    .background(
                                        Circle().fill(symbol == item ? Color(hex: colorHex) : Color(.tertiarySystemFill))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                        ForEach(Palette.colors) { item in
                            Button {
                                colorHex = item.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: item.hex))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white)
                                            .opacity(colorHex == item.hex ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack {
                        Text("初始余额")
                        Spacer()
                        TextField("0", text: $initialText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 17, design: .rounded))
                    }
                } footer: {
                    Text("账户里现在本来有多少。之后每一笔加减都记在记录里。")
                }

                if let original {
                    Section {
                        Button("删除账户", role: .destructive) {
                            showDelete = true
                        }
                    }
                    .confirmationDialog("删除「\(original.name)」？", isPresented: $showDelete, titleVisibility: .visible) {
                        Button("删除", role: .destructive) {
                            store.deleteWallet(original)
                            dismiss()
                        }
                        Button("取消", role: .cancel) {}
                    }
                }
            }
            .navigationTitle(original == nil ? "新账户" : "编辑账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let initial = Money.parse(initialText) ?? 0

        if var wallet = original {
            wallet.name = trimmed
            wallet.symbol = symbol
            wallet.colorHex = colorHex
            wallet.initialCents = initial
            store.updateWallet(wallet)
        } else {
            store.addWallet(Wallet(name: trimmed, symbol: symbol, colorHex: colorHex, initialCents: initial))
        }
        dismiss()
    }
}
