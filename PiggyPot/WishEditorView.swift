import SwiftUI

struct WishEditorView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    private let original: Wish?

    @State private var title: String
    @State private var targetText: String
    @State private var symbol: String
    @State private var colorHex: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var showDelete = false

    init(wish: Wish?) {
        original = wish
        _title = State(initialValue: wish?.title ?? "")
        _targetText = State(initialValue: wish.map { Money.editable($0.targetCents) } ?? "")
        _symbol = State(initialValue: wish?.symbol ?? "gift.fill")
        _colorHex = State(initialValue: wish?.colorHex ?? Palette.colors[0].hex)
        _hasDeadline = State(initialValue: wish?.deadline != nil)
        _deadline = State(initialValue: wish?.deadline ?? Date().addingTimeInterval(86400 * 30))
    }

    private var targetCents: Int? {
        guard let value = Money.parse(targetText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && targetCents != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color(hex: colorHex).gradient)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: symbol)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                        TextField("想买什么，比如 新耳机", text: $title)
                            .font(.system(size: 17))
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack {
                        Text("价格")
                        Spacer()
                        Text("¥")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $targetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 17, design: .rounded))
                            .frame(maxWidth: 140)
                    }
                } footer: {
                    Text("攒到这么多就算达成。")
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                        ForEach(Symbols.wishItems, id: \.self) { item in
                            Button {
                                symbol = item
                            } label: {
                                Image(systemName: item)
                                    .font(.system(size: 18))
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
                    Toggle("设定日期", isOn: $hasDeadline.animation())
                    if hasDeadline {
                        DatePicker("目标日期", selection: $deadline, displayedComponents: .date)
                    }
                } footer: {
                    Text("可选。设了日期会显示还剩几天。")
                }

                if let original, !original.deposits.isEmpty {
                    Section("攒钱记录") {
                        ForEach(original.deposits) { deposit in
                            HStack {
                                Text(DateText.day.string(from: deposit.date))
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("+\(Money.text(deposit.cents))")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                if let original {
                    Section {
                        Button("删除这个心愿", role: .destructive) {
                            showDelete = true
                        }
                    }
                    .confirmationDialog("删除「\(original.title)」？", isPresented: $showDelete, titleVisibility: .visible) {
                        Button("删除", role: .destructive) {
                            store.deleteWish(original)
                            dismiss()
                        }
                        Button("取消", role: .cancel) {}
                    }
                }
            }
            .navigationTitle(original == nil ? "新心愿" : "编辑心愿")
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
        guard let targetCents else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if var wish = original {
            wish.title = trimmed
            wish.targetCents = targetCents
            wish.symbol = symbol
            wish.colorHex = colorHex
            wish.deadline = hasDeadline ? deadline : nil
            store.updateWish(wish)
        } else {
            store.addWish(Wish(title: trimmed,
                               targetCents: targetCents,
                               symbol: symbol,
                               colorHex: colorHex,
                               deadline: hasDeadline ? deadline : nil))
        }
        dismiss()
    }
}
