import Foundation
import Combine

final class Store: ObservableObject {
    @Published private(set) var wallets: [Wallet] = []
    @Published private(set) var entries: [Entry] = []

    private let fileURL: URL

    private struct Snapshot: Codable {
        var wallets: [Wallet]
        var entries: [Entry]
    }

    init() {
        let fm = FileManager.default
        let dir = (try? fm.url(for: .applicationSupportDirectory,
                               in: .userDomainMask,
                               appropriateFor: nil,
                               create: true)) ?? fm.temporaryDirectory
        fileURL = dir.appendingPathComponent("piggy-pot.json")
        load()
    }

    // MARK: - 读写

    private func load() {
        if let data = try? Data(contentsOf: fileURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let snapshot = try? decoder.decode(Snapshot.self, from: data) {
                wallets = snapshot.wallets
                entries = snapshot.entries.sorted { $0.date > $1.date }
            }
        }

        if wallets.isEmpty {
            seed()
            save()
        }
    }

    private func save() {
        let snapshot = Snapshot(wallets: wallets, entries: entries)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func seed() {
        let alipay = Wallet(name: "支付宝", symbol: "wallet.pass.fill", colorHex: "3B82F6", initialCents: 3000)
        let wechat = Wallet(name: "微信", symbol: "bubble.left.fill", colorHex: "34C759", initialCents: 300)
        let bank = Wallet(name: "银行卡", symbol: "creditcard.fill", colorHex: "8E8E93", initialCents: 128000)
        let cash = Wallet(name: "现金", symbol: "banknote", colorHex: "F0A22E", initialCents: 5000)
        wallets = [alipay, wechat, bank, cash]

        let cal = Calendar.current
        let now = Date()
        entries = [
            Entry(walletID: wechat.id, cents: 5000, kind: .income, note: "卖了个旧键盘",
                  date: cal.date(byAdding: .day, value: -3, to: now) ?? now),
            Entry(walletID: alipay.id, cents: 1250, kind: .expense, note: "早饭",
                  date: cal.date(byAdding: .day, value: -1, to: now) ?? now),
            Entry(walletID: bank.id, cents: 19900, kind: .expense, note: "话费充值",
                  date: cal.date(byAdding: .day, value: -1, to: now) ?? now),
            Entry(walletID: cash.id, cents: 800, kind: .income, note: "找回的零钱", date: now)
        ].sorted { $0.date > $1.date }
    }

    // MARK: - 查询

    func wallet(_ id: UUID) -> Wallet? {
        wallets.first { $0.id == id }
    }

    func balance(_ walletID: UUID) -> Int {
        let base = wallet(walletID)?.initialCents ?? 0
        return base + entries.filter { $0.walletID == walletID }.reduce(0) { $0 + $1.signedCents }
    }

    var totalCents: Int {
        wallets.reduce(0) { $0 + balance($1.id) }
    }

    var monthIncomeCents: Int {
        entries.filter { $0.kind == .income && isThisMonth($0.date) }.reduce(0) { $0 + $1.cents }
    }

    var monthExpenseCents: Int {
        entries.filter { $0.kind == .expense && isThisMonth($0.date) }.reduce(0) { $0 + $1.cents }
    }

    func entries(for walletID: UUID?) -> [Entry] {
        guard let walletID else { return entries }
        return entries.filter { $0.walletID == walletID }
    }

    private func isThisMonth(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - 记录

    func add(_ entry: Entry) {
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        save()
    }

    func update(_ entry: Entry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            entries.sort { $0.date > $1.date }
            save()
        }
    }

    func delete(_ entry: Entry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func delete(entries ids: Set<UUID>) {
        entries.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - 账户

    func addWallet(_ wallet: Wallet) {
        wallets.append(wallet)
        save()
    }

    func updateWallet(_ wallet: Wallet) {
        if let index = wallets.firstIndex(where: { $0.id == wallet.id }) {
            wallets[index] = wallet
            save()
        }
    }

    func deleteWallet(_ wallet: Wallet) {
        wallets.removeAll { $0.id == wallet.id }
        entries.removeAll { $0.walletID == wallet.id }
        save()
    }

    func moveWallets(from source: IndexSet, to destination: Int) {
        wallets.move(fromOffsets: source, toOffset: destination)
        save()
    }
}
