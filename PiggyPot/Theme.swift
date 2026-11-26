import SwiftUI

enum Palette {
    struct Item: Identifiable, Hashable {
        let hex: String
        let name: String
        var id: String { hex }
    }

    static let colors: [Item] = [
        Item(hex: "F09E2E", name: "琥珀"),
        Item(hex: "3B82F6", name: "蓝"),
        Item(hex: "34C759", name: "绿"),
        Item(hex: "FF3B30", name: "红"),
        Item(hex: "8B5CF6", name: "紫"),
        Item(hex: "F472B6", name: "粉"),
        Item(hex: "22B8CF", name: "青"),
        Item(hex: "FF9500", name: "橙"),
        Item(hex: "8E8E93", name: "灰"),
        Item(hex: "5856D6", name: "靛")
    ]
}

enum Symbols {
    static let items: [String] = [
        "wallet.pass.fill",
        "creditcard.fill",
        "banknote",
        "yensign.circle.fill",
        "bubble.left.fill",
        "iphone",
        "building.columns.fill",
        "gift.fill",
        "cart.fill",
        "cup.and.saucer.fill",
        "car.fill",
        "house.fill"
    ]
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

extension Wallet {
    var color: Color { Color(hex: colorHex) }
}
