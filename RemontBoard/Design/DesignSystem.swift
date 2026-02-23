import SwiftUI

// MARK: - Colors
struct AppColors {
    static let background    = Color(hex: "#0A1628")
    static let cardBackground = Color(hex: "#1A2640")
    static let accent        = Color(hex: "#F5C842")
    static let accentBlue    = Color(hex: "#4A90D9")
    static let success       = Color(hex: "#5BC8A3")
    static let warning       = Color(hex: "#E87D5A")
    static let secondaryText = Color.white.opacity(0.55)
}

// MARK: - Color+Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red:     Double(r)/255,
                  green:   Double(g)/255,
                  blue:    Double(b)/255,
                  opacity: Double(a)/255)
    }
}

// MARK: - ScaleButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

extension View {
    func scaleButtonStyle() -> some View {
        buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Blueprint Grid
struct BlueprintGridView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 28
                var x: CGFloat = 0
                while x <= geo.size.width { path.move(to: CGPoint(x:x, y:0)); path.addLine(to: CGPoint(x:x, y:geo.size.height)); x += step }
                var y: CGFloat = 0
                while y <= geo.size.height { path.move(to: CGPoint(x:0, y:y)); path.addLine(to: CGPoint(x:geo.size.width, y:y)); y += step }
            }
            .stroke(Color(hex: "#4A90D9").opacity(0.10), lineWidth: 0.5)
        }
        .ignoresSafeArea()
    }
}

// MARK: - ProgressBar
struct ProgressBar: View {
    let value: Double   // 0…1
    @State private var animated = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [AppColors.accentBlue, AppColors.accent],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(animated ? min(value, 1) : 0), height: 6)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animated)
            }
        }
        .frame(height: 6)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { animated = true } }
    }
}
