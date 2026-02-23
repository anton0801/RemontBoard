import SwiftUI

@main
struct RemontBoardApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView(onFinish: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    })
                    .transition(.opacity)
                    .zIndex(1)
                } else {
                    RootView()
                        .transition(.opacity)
                        .zIndex(0)
                }
            }
        }
    }
}
