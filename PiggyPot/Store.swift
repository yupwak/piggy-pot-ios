import Foundation
import Combine

final class Store: ObservableObject {
    @Published private(set) var wallets: [Wallet] = []
    @Published private(set) var entries: [Entry] = []
    @Published private(set) var wishes: [Wish] = []

    private let fileURL: URL

    private struct Snapshot: Codable {
        var wallets: [Wallet]
        var entries: [Entry]
        var wishes: [Wish]
    }

    /// 旧版本文件没有心愿单
    private struct LegacySnapshot: Codable {
        var wallets: [Wallet]
        var entries: [Entry]
    }

    init() {
        let fm = FileManager.default
        let dir = (try? fm.url(for: .applicationSupportDirectory,
                               in: .userDomainMask,
                               appropriateFor: nil,
                               create: true)) ?? fm.temporaryDirectory
        fileURL = dir.appendingPathComponent("qianji.json")
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
                wishes = snapshot.wishes
            } else if let legacy = try? decoder.decode(LegacySnapshot.self, from: data) {
                wallets = legacy.wallets
                entries = legacy.entries.sorted { $0.date > $1.date }
                wishes = []
            }
        }

        if wallets.isEmpty {
            seed()
            save()
        }
    }

    private func save() {
        let snapshot = Snapshot(wallets: wallets, entries: entries, wishes: wishes)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func seed() {
        wallets = [
            Wallet(name: "支付宝", symbol: "wallet.pass.fill", colorHex: "3B82F6", initialCents: 0),
            Wallet(name: "微信", symbol: "bubble.left.fill", colorHex: "34C759", initialCents: 0),
            Wallet(name: "银行卡", symbol: "creditcard.fill", colorHex: "8E8E93", initialCents: 0),
            Wallet(name: "现金", symbol: "banknote", colorHex: "F0A22E", initialCents: 0)
        ]
        entries = []
        wishes = []
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

    // MARK: - 心愿单

    func addWish(_ wish: Wish) {
        wishes.append(wish)
        save()
    }

    func updateWish(_ wish: Wish) {
        if let index = wishes.firstIndex(where: { $0.id == wish.id }) {
            wishes[index] = wish
            save()
        }
    }

    func deleteWish(_ wish: Wish) {
        wishes.removeAll { $0.id == wish.id }
        save()
    }

    func deposit(to wishID: UUID, cents: Int, date: Date) {
        guard cents > 0, let index = wishes.firstIndex(where: { $0.id == wishID }) else { return }
        wishes[index].deposits.append(WishDeposit(cents: cents, date: date))
        wishes[index].deposits.sort { $0.date > $1.date }
        save()
    }

    func removeLastDeposit(of wishID: UUID) {
        guard let index = wishes.firstIndex(where: { $0.id == wishID }),
              !wishes[index].deposits.isEmpty else { return }
        wishes[index].deposits.removeLast()
        save()
    }

    var totalWishSaved: Int { wishes.reduce(0) { $0 + $1.savedCents } }
    var totalWishTarget: Int { wishes.reduce(0) { $0 + $1.targetCents } }

    func moveWallets(from source: IndexSet, to destination: Int) {
        wallets.move(fromOffsets: source, toOffset: destination)
        save()
    }
}
