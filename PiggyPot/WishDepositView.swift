import SwiftUI

struct WishDepositView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    let wish: Wish

    @State private var amountText = ""
    @State private var date = Date()
    @FocusState private var focused: Bool

    private var cents: Int? {
        guard let value = Money.parse(amountText), value > 0 else { return nil }
        return value
    }

    private let quickAmounts = [1, 5, 10, 20, 50, 100]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: wish.colorHex).gradient)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: wish.symbol)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(wish.title)
                                .font(.system(size: 15, weight: .medium))
                            Text("还差 \(Money.text(wish.remainingCents))")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(wish.progress * 100))%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("¥")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .focused($focused)
                    }
                    .padding(.vertical, 4)

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
                    Text("这次攒多少")
                }

                Section {
                    DatePicker("时间", selection: $date)
                }
            }
            .navigationTitle("存一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("记下") { save() }
                        .disabled(cents == nil)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                focused = true
            }
        }
    }

    private func save() {
        guard let cents else { return }
        store.deposit(to: wish.id, cents: cents, date: date)
        dismiss()
    }
}
