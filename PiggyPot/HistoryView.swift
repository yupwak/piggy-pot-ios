import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: Store

    let wallet: Wallet?

    @State private var editing: Entry?

    private struct DayGroup: Identifiable {
        let day: Date
        let entries: [Entry]
        var id: Date { day }
        var income: Int { entries.filter { $0.kind == .income }.reduce(0) { $0 + $1.cents } }
        var expense: Int { entries.filter { $0.kind == .expense }.reduce(0) { $0 + $1.cents } }
    }

    private var items: [Entry] { store.entries(for: wallet?.id) }

    private var groups: [DayGroup] {
        let grouped = Dictionary(grouping: items) { DateText.startOfDay($0.date) }
        return grouped
            .map { DayGroup(day: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        List {
            if items.isEmpty {
                EmptyHint(symbol: "tray", title: "还没有记录")
                    .listRowBackground(Color.clear)
            }

            ForEach(groups) { group in
                Section {
                    ForEach(group.entries) { entry in
                        Button {
                            editing = entry
                        } label: {
                            EntryRow(entry: entry, wallet: store.wallet(entry.walletID))
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button("删除", role: .destructive) {
                                store.delete(entry)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(DateText.dayLabel(group.day))
                        Spacer()
                        if group.income > 0 {
                            Text("+\(Money.text(group.income))")
                                .foregroundStyle(.green)
                        }
                        if group.expense > 0 {
                            Text("−\(Money.text(group.expense))")
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.system(size: 12))
                }
            }

            Section {
                HStack {
                    Text("结余")
                        .font(.system(size: 15))
                    Spacer()
                    Text(Money.text(wallet.map { store.balance($0.id) } ?? store.totalCents))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            }
        }
        .navigationTitle(wallet?.name ?? "全部记录")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { entry in
            AddEntryView(editing: entry)
                .environmentObject(store)
        }
    }
}
