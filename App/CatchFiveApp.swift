import SwiftUI
import CatchFiveUI

@main
struct CatchFiveApp: App {
    var body: some Scene {
        // `-stage picker|curtain|seat|bidding|table|result` at launch opens that state for headless screenshots; normally absent.
        WindowGroup { RootView(model: GameModel.loadDefault(), stage: UserDefaults.standard.string(forKey: "stage")) }
    }
}
