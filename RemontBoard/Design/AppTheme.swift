import SwiftUI

// MARK: - AppTheme (new in v1.1)
// Centralised theme that can be extended to support light mode in future
struct AppTheme {
    // Gradients
    static let heroGradient = LinearGradient(
        colors: [AppColors.accentBlue.opacity(0.18), AppColors.background],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let accentGradient = LinearGradient(
        colors: [AppColors.accent, Color(hex: "#FFD95C")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let successGradient = LinearGradient(
        colors: [AppColors.success, Color(hex: "#4BFFC0").opacity(0.8)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let cardShadow = Color.black.opacity(0.22)

    // Haptics
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - Haptic modifier
struct HapticModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    func body(content: Content) -> some View {
        content.simultaneousGesture(TapGesture().onEnded { AppTheme.impact(style) })
    }
}

extension View {
    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        modifier(HapticModifier(style: style))
    }
}

// MARK: - Card modifier (reusable card style)
struct CardStyle: ViewModifier {
    var borderColor: Color = AppColors.accentBlue.opacity(0.25)
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1))
            .shadow(color: AppTheme.cardShadow, radius: 8, y: 3)
    }
}

extension View {
    func cardStyle(border: Color = AppColors.accentBlue.opacity(0.25)) -> some View {
        modifier(CardStyle(borderColor: border))
    }
}

// MARK: - Shimmer loading effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0)
                        ]),
                        startPoint: UnitPoint(x: phase, y: 0),
                        endPoint:   UnitPoint(x: phase + 0.4, y: 0)
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * phase)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Toast notification
struct ToastView: View {
    let message : String
    let icon    : String
    let color   : Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground.opacity(0.97))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24)
            .stroke(color.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isShowing : Bool
    let message            : String
    let icon               : String
    let color              : Color

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if isShowing {
                ToastView(message: message, icon: icon, color: color)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation(.spring()) { isShowing = false }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isShowing)
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String,
               icon: String = "checkmark.circle.fill",
               color: Color = AppColors.success) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, icon: icon, color: color))
    }
}

// MARK: - Animated counter
struct AnimatedCounter: View {
    let value    : Double
    let prefix   : String
    let suffix   : String
    let fontSize : CGFloat
    @State private var displayed: Double = 0

    var body: some View {
        Text("\(prefix)\(Int(displayed))\(suffix)")
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) { displayed = value }
            }
            .onChange(of: value) { newVal in
                withAnimation(.easeOut(duration: 0.8)) { displayed = newVal }
            }
    }
}

// MARK: - Confetti burst (simple particle effect for task completion)
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var visible = true

    let colors: [Color] = [AppColors.accent, AppColors.accentBlue, AppColors.success, .purple, .pink]

    var body: some View {
        ZStack {
            if visible {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .position(p.position)
                        .opacity(p.opacity)
                }
            }
        }
        .onAppear { burst() }
        .allowsHitTesting(false)
    }

    private func burst() {
        let center = CGPoint(x: UIScreen.main.bounds.width / 2,
                             y: UIScreen.main.bounds.height / 2)
        particles = (0..<30).map { _ in
            ConfettiParticle(
                position: center,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 5...12),
                opacity: 1.0
            )
        }
        withAnimation(.easeOut(duration: 1.0)) {
            for i in particles.indices {
                let angle = Double.random(in: 0...(2 * .pi))
                let dist  = CGFloat.random(in: 80...220)
                particles[i].position = CGPoint(
                    x: center.x + cos(angle) * dist,
                    y: center.y + sin(angle) * dist
                )
                particles[i].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { visible = false }
    }
}

struct ConfettiParticle: Identifiable {
    let id    = UUID()
    var position: CGPoint
    var color    : Color
    var size     : CGFloat
    var opacity  : Double
}
