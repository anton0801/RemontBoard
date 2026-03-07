import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @StateObject private var authService = AuthService.shared
    @StateObject var appVM = AppViewModel()

    var body: some View {
        Group {
            switch authService.authState {
            case .loading:
                LoadingView()
            case .unauthenticated:
                if !hasSeenOnboarding {
                    OnboardingView().environmentObject(authService)
                } else {
                    AuthContainerView().environmentObject(authService)
                }
            case .authenticated, .guest:
                MainTabView()
                    .environmentObject(appVM)
                    .environmentObject(authService)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: authService.authState)
    }
}

// MARK: - LoadingView
struct LoadingView: View {
    @State private var rotate = false
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            BlueprintGridView().opacity(0.15)
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(AppColors.accentBlue.opacity(0.15), lineWidth: 3)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotate ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotate)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 20)).foregroundColor(AppColors.accent)
                }
                .onAppear { rotate = true }
                Text("Loading…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - MainTabView
struct MainTabView: View {
    @EnvironmentObject var appVM      : AppViewModel
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ApartmentView().environmentObject(appVM).tag(0)
                BudgetView().environmentObject(appVM).tag(1)
                ScheduleView().environmentObject(appVM).tag(2)
                // DefectsOverviewView().environmentObject(appVM).tag(3)
                StatsView().environmentObject(appVM).tag(3)
                ProfileView().environmentObject(appVM).environmentObject(authService).tag(4)
            }
            .edgesIgnoringSafeArea(.bottom)
            CustomTabBar(selectedTab: $selectedTab, user: authService.currentUser)
        }
        .edgesIgnoringSafeArea(.bottom)
        .overlay(alignment: .top) {
            if authService.currentUser?.isGuest == true {
                GuestTopBanner().environmentObject(authService)
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let user: AppUser?

    let tabs: [(icon: String, label: String)] = [
        ("building.2.fill",               "Rooms"),
        ("chart.bar.fill",                "Budget"),
        ("calendar",                      "Schedule"),
        ("chart.pie.fill",                "Analytics"),
        ("person.fill",                   "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = i }
                } label: {
                    VStack(spacing: 3) {
                        if i == 5, let u = user {
                            ZStack {
                                Circle()
                                    .fill(selectedTab == i ? AppColors.accent : u.avatarColor.opacity(0.3))
                                    .frame(width: 26, height: 26)
                                Text(u.initials)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(selectedTab == i ? AppColors.background : .white)
                            }
                        } else {
                            Image(systemName: tabs[i].icon)
                                .font(.system(size: 18))
                                .scaleEffect(selectedTab == i ? 1.18 : 1)
                        }
                        Text(tabs[i].label).font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(selectedTab == i ? AppColors.accent : Color.white.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10).padding(.bottom, 4)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
        }
        .background(
            AppColors.cardBackground
                .overlay(Rectangle().fill(AppColors.accent.opacity(0.6)).frame(height: 1), alignment: .top)
                .shadow(color: .black.opacity(0.3), radius: 12, y: -4)
        )
    }
}

// MARK: - GuestTopBanner
struct GuestTopBanner: View {
    @EnvironmentObject var authService: AuthService
    @State private var visible = true

    var body: some View {
        if visible {
            HStack(spacing: 10) {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 12)).foregroundColor(AppColors.accent)
                Text("Guest Mode — data won't sync")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                Spacer()
                Button("Sign In") { authService.signOut() }
                    .font(.system(size: 11, weight: .bold)).foregroundColor(AppColors.accent)
                Button { withAnimation { visible = false } } label: {
                    Image(systemName: "xmark").font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(AppColors.cardBackground.opacity(0.95))
            .overlay(Rectangle().fill(AppColors.accent).frame(height: 2), alignment: .bottom)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
