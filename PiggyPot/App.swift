import SwiftUI

@main
struct PiggyPotApp: App {
    @StateObject private var store = Store()
    @AppStorage("appearance") private var appearance = 0

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(appearance == 1 ? .light : (appearance == 2 ? .dark : nil))
        }
    }
}
