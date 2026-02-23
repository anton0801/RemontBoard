import SwiftUI

struct OnboardingPage {
    let icon     : String
    let title    : String
    let subtitle : String
    let color    : Color
}

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(icon: "building.2.fill",
                       title: "Plan Your Apartment",
                       subtitle: "Create rooms, set areas and renovation types. Your entire flat in one place.",
                       color: Color(hex: "#4A90D9")),
        OnboardingPage(icon: "list.bullet.clipboard.fill",
                       title: "Track Every Task",
                       subtitle: "Add tasks with deadlines, mark progress, and never miss a renovation step.",
                       color: Color(hex: "#F5C842")),
        OnboardingPage(icon: "chart.bar.fill",
                       title: "Smart Budget Control",
                       subtitle: "Compare plan vs actual, see material costs, labor and unexpected expenses instantly.",
                       color: Color(hex: "#5BC8A3")),
        OnboardingPage(icon: "hammer.fill",
                       title: "Material Calculator",
                       subtitle: "Enter room size, pick coverage — get exact amounts and cost estimates by tier.",
                       color: Color(hex: "#E87D5A")),
        OnboardingPage(icon: "exclamationmark.triangle.fill",
                       title: "Defect Journal",
                       subtitle: "Document cracks, leaks and issues with photos. Build a complete defect log.",
                       color: Color(hex: "#A78BFA"))
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            BlueprintGridView().opacity(0.18)

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") { hasSeenOnboarding = true }
                        .foregroundColor(AppColors.accent)
                        .font(.system(size: 14, weight: .semibold))
                        .padding()
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        OnboardingPageView(page: page).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Indicators + Button
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? AppColors.accent : Color.white.opacity(0.25))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }

                    Button(action: nextPage) {
                        HStack(spacing: 8) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accent)
                        .cornerRadius(16)
                        .shadow(color: AppColors.accent.opacity(0.38), radius: 14, y: 7)
                    }
                    .padding(.horizontal, 32)
                    .scaleButtonStyle()
                }
                .padding(.bottom, 50)
            }
        }
    }

    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring()) { currentPage += 1 }
        } else {
            hasSeenOnboarding = true
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 200, height: 200)
                // Rotating ring
                Circle()
                    .stroke(page.color.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 178, height: 178)
                    .rotationEffect(.degrees(appeared ? 360 : 0))
                    .animation(.linear(duration: 9).repeatForever(autoreverses: false), value: appeared)
                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 72))
                    .foregroundColor(page.color)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: appeared)
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
            }
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)

            Spacer()
            Spacer()
        }
        .onAppear  { appeared = true  }
        .onDisappear { appeared = false }
    }
}
