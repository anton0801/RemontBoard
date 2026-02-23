import SwiftUI

// MARK: - RootView
struct RootView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @StateObject var appVM = AppViewModel()

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else {
                MainTabView()
                    .environmentObject(appVM)
            }
        }
        .animation(.easeInOut, value: hasSeenOnboarding)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ApartmentView()
                    .environmentObject(appVM)
                    .tag(0)
                BudgetView()
                    .environmentObject(appVM)
                    .tag(1)
                ScheduleView()
                    .environmentObject(appVM)
                    .tag(2)
                DefectsOverviewView()
                    .environmentObject(appVM)
                    .tag(3)
            }
            .edgesIgnoringSafeArea(.bottom)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - CustomTabBar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("building.2.fill", "Apartment"),
        ("chart.bar.fill",  "Budget"),
        ("calendar",        "Schedule"),
        ("exclamationmark.triangle.fill", "Defects")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 20))
                            .scaleEffect(selectedTab == i ? 1.18 : 1)
                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(selectedTab == i ? AppColors.accent : Color.white.opacity(0.38))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.bottom, 4)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
        }
        .background(
            AppColors.cardBackground
                .overlay(Rectangle().fill(AppColors.accent).frame(height: 2), alignment: .top)
        )
    }
}
