import SwiftUI
import CatchFiveUI

@main
struct CatchFiveApp: App {
    var body: some Scene {
        // `-stage <name>` at launch opens that state for headless screenshots (names in `RootView.init`); normally absent.
        WindowGroup { RootView(model: GameModel.loadDefault(), stage: UserDefaults.standard.string(forKey: "stage")) }
    }
}
