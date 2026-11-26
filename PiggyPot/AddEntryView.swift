import SwiftUI

struct AddEntryView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    var editing: Entry? = nil

    @State private var kind: EntryKind = .expense
    @State private var amountText = ""
    @State private var walletID: UUID?
    @State private var note = ""
    @State private var date = Date()
    @State private var didLoad = false
    @FocusState private var amountFocused: Bool

    private var cents: Int? {
        guard let value = Money.parse(amountText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool { cents != nil && walletID != nil }

    private let quickAmounts = [1, 5, 10, 20, 50, 100]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("类型", selection: $kind) {
                        ForEach(EntryKind.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("¥")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .focused($amountFocused)
                    }
                    .padding(.vertical, 6)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickAmounts, id: \.self) { value in
                                Button("\(value)") {
                                    amountText = "\(value)"
                                }
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text(kind == .expense ? "花出去多少" : "进来多少")
                }

                Section {
                    if store.wallets.isEmpty {
                        Text("先去账户管理添加一个账户")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("从哪来 / 到哪去", selection: $walletID) {
                            ForEach(store.wallets) { wallet in
                                Text(wallet.name).tag(Optional(wallet.id))
                            }
                        }
                    }
                    TextField("备注（选填）", text: $note)
                    DatePicker("时间", selection: $date)
                }

                if editing != nil {
                    Section {
                        Button("删除这条记录", role: .destructive) {
                            if let editing {
                                store.delete(editing)
                            }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "记一笔" : "改一改")
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
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true

        if let editing {
            kind = editing.kind
            amountText = Money.editable(editing.cents)
            walletID = editing.walletID
            note = editing.note
            date = editing.date
        } else {
            walletID = store.wallets.first?.id
            amountFocused = true
        }
    }

    private func save() {
        guard let cents, let walletID else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if var editing {
            editing.walletID = walletID
            editing.cents = cents
            editing.kind = kind
            editing.note = trimmed
            editing.date = date
            store.update(editing)
        } else {
            store.add(Entry(walletID: walletID, cents: cents, kind: kind, note: trimmed, date: date))
        }
        dismiss()
    }
}
