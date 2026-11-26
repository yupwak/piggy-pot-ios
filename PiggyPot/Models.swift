import Foundation

/// 一条记录的类型
enum EntryKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }
    var title: String { self == .expense ? "支出" : "收入" }
    var sign: Int { self == .income ? 1 : -1 }
}

/// 钱放在哪儿：支付宝、微信、银行卡、现金……
struct Wallet: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var symbol: String
    var colorHex: String
    var initialCents: Int = 0
    var createdAt: Date = Date()
}

/// 一笔进出记录
struct Entry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var walletID: UUID
    var cents: Int
    var kind: EntryKind
    var note: String
    var date: Date

    var signedCents: Int { kind.sign * cents }
}

/// 心愿单：想买的东西，一笔一笔往里攒
struct WishDeposit: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var cents: Int
    var date: Date
}

struct Wish: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var targetCents: Int
    var symbol: String
    var colorHex: String
    var deadline: Date? = nil
    var createdAt: Date = Date()
    var deposits: [WishDeposit] = []

    var savedCents: Int { deposits.reduce(0) { $0 + $1.cents } }
    var remainingCents: Int { max(0, targetCents - savedCents) }
    var isDone: Bool { targetCents > 0 && savedCents >= targetCents }

    var progress: Double {
        guard targetCents > 0 else { return 0 }
        return min(1.0, Double(savedCents) / Double(targetCents))
    }
}

/// 钱数格式与解析（全部用分，避免小数误差）
enum Money {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        return f
    }()

    static func text(_ cents: Int) -> String {
        let value = Double(abs(cents)) / 100.0
        let body = formatter.string(from: NSNumber(value: value)) ?? "0.00"
        return "¥" + body
    }

    static func signedText(_ cents: Int) -> String {
        (cents < 0 ? "−" : "+") + text(cents)
    }

    static func editable(_ cents: Int) -> String {
        if cents % 100 == 0 { return "\(cents / 100)" }
        return String(format: "%.2f", Double(cents) / 100.0)
    }

    static func parse(_ input: String) -> Int? {
        var s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "¥", with: "")
        s = s.replacingOccurrences(of: ",", with: "")
        s = s.replacingOccurrences(of: "，", with: "")
        s = s.replacingOccurrences(of: " ", with: "")
        guard !s.isEmpty, s.count <= 12 else { return nil }
        guard let value = Double(s), value.isFinite, value >= 0 else { return nil }
        let cents = (value * 100).rounded()
        guard cents <= Double(Int.max / 4) else { return nil }
        return Int(cents)
    }
}

enum DateText {
    static let day: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f
    }()

    static let clock: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm"
        return f
    }()

    static let month: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月"
        return f
    }()

    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "今天" }
        if cal.isDateInYesterday(date) { return "昨天" }
        return day.string(from: date)
    }
}
