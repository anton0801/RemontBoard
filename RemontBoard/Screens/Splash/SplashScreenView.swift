import SwiftUI
import Combine

struct SplashScreenView: View {

    @State private var logoScale   : CGFloat = 0.3
    @State private var logoOpacity : Double  = 0
    @State private var gridOpacity : Double  = 0
    @State private var taglineOp   : Double  = 0
    @State private var ringRotation: Double  = 0
    @State private var particles   : [SplashParticle] = []
    
    @StateObject private var store = Store()
    @State private var streams = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(gridOpacity)

                ForEach(particles) { p in
                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: p.size, height: p.size)
                        .position(p.position)
                        .opacity(p.opacity)
                }

                VStack(spacing: 24) {
                    // Logo ring + icon
                    ZStack {
                        Circle()
                            .fill(AppColors.accent.opacity(0.08))
                            .frame(width: 130, height: 130)

                        Circle()
                            .stroke(
                                AngularGradient(colors: [AppColors.accent, AppColors.accentBlue, AppColors.accent],
                                                center: .center),
                                lineWidth: 2
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(ringRotation))
                            .animation(.linear(duration: 6).repeatForever(autoreverses: false),
                                       value: ringRotation)

                        VStack(spacing: 4) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 42))
                                .foregroundColor(AppColors.accent)
                            Image(systemName: "ruler.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.accentBlue)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    VStack(spacing: 8) {
                        Text("Remont Board")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Your Renovation Command Center")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.accent.opacity(0.85))
                        ProgressView()
                            .tint(.white)
                    }
                    .opacity(taglineOp)
                    .offset(y: taglineOp == 0 ? 20 : 0)
                }
                
                NavigationLink(
                    destination: RemontWebView().navigationBarHidden(true),
                    isActive: $store.state.ui.navigateToWeb
                ) { EmptyView() }

                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $store.state.ui.navigateToMain
                ) { EmptyView() }
            }
            .onAppear {
                animate()
                store.dispatch(.initialize)
                setupStreams()
            }
            .fullScreenCover(isPresented: $store.state.ui.showPermissionPrompt) {
                RemontNotificationView(store: store)
            }
            .fullScreenCover(isPresented: $store.state.ui.showOfflineView) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { store.dispatch(.trackingReceived($0)) }
            .store(in: &streams)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { store.dispatch(.navigationReceived($0)) }
            .store(in: &streams)
    }
    
    private func animate() {
        // Grid
        withAnimation(.easeIn(duration: 0.6)) { gridOpacity = 0.3 }
        // Particles
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        particles = (0..<22).map { _ in
            SplashParticle(
                position: CGPoint(x: CGFloat.random(in: 0...w), y: CGFloat.random(in: 0...h)),
                size: CGFloat.random(in: 2...7),
                opacity: Double.random(in: 0.15...0.55)
            )
        }
        // Logo
        withAnimation(.spring(response: 0.7, dampingFraction: 0.48).delay(0.25)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }
        ringRotation = 360
        // Tagline
        withAnimation(.easeOut(duration: 0.5).delay(0.85)) { taglineOp = 1 }
    }
}

struct SplashParticle: Identifiable {
    let id       = UUID()
    var position : CGPoint
    var size     : CGFloat
    var opacity  : Double
}
