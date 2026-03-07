import SwiftUI

@main
struct RemontBoardApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ZStack {
                SplashScreenView()
            }
        }
    }
}
