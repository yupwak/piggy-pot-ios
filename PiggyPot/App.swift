import SwiftUI

@main
struct PiggyPotApp: App {
    @StateObject private var store = Store()
    @AppStorage("appearance") private var appearance = 0

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(appearance == 1 ? .light : (appearance == 2 ? .dark : nil))
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("记账", systemImage: "yensign.circle.fill")
                }
            WishlistView()
                .tabItem {
                    Label("心愿", systemImage: "heart.fill")
                }
        }
        .tint(Color(hex: "F09E2E"))
    }
}
