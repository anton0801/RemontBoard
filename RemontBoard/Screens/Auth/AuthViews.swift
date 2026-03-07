import SwiftUI

// MARK: - AuthContainerView
struct AuthContainerView: View {
    @State private var mode: AuthMode = .login

    enum AuthMode { case login, register }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            BlueprintGridView().opacity(0.18)
            // Glow blobs
            GlowBlob(color: AppColors.accent,    x: 0.8, y: 0.15, size: 320)
            GlowBlob(color: AppColors.accentBlue, x: 0.1, y: 0.75, size: 280)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    AuthLogoHeader()
                    AuthModeToggle(mode: $mode)
                        .padding(.top, 32)

                    if mode == .login {
                        LoginFormView(switchToRegister: { withAnimation(.spring()) { mode = .register } })
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal:   .move(edge: .trailing).combined(with: .opacity)))
                    } else {
                        RegisterFormView(switchToLogin: { withAnimation(.spring()) { mode = .login } })
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)))
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Glow blob
struct GlowBlob: View {
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(color.opacity(0.07))
                .frame(width: size, height: size)
                .blur(radius: 80)
                .position(x: geo.size.width * x, y: geo.size.height * y)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Logo header
struct AuthLogoHeader: View {
    @State private var rotate = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.1))
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(
                        AngularGradient(colors: [AppColors.accent, AppColors.accentBlue, .clear, AppColors.accent],
                                        center: .center),
                        lineWidth: 1.5)
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(rotate ? 360 : 0))
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: rotate)
                VStack(spacing: 3) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 36))
                        .foregroundColor(AppColors.accent)
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accentBlue)
                }
            }
            .onAppear { rotate = true }

            VStack(spacing: 6) {
                Text("Remont Board")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Plan smart. Build better.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Mode Toggle
struct AuthModeToggle: View {
    @Binding var mode: AuthContainerView.AuthMode
    var body: some View {
        HStack(spacing: 0) {
            ForEach([(AuthContainerView.AuthMode.login, "Sign In"),
                     (AuthContainerView.AuthMode.register, "Sign Up")], id: \.1) { m, label in
                Button { withAnimation(.spring()) { mode = m } } label: {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(mode == m ? AppColors.background : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(mode == m ? AppColors.accent : Color.clear)
                        .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .padding(.horizontal, 28)
    }
}

// MARK: - LoginFormView
struct LoginFormView: View {
    var switchToRegister: () -> Void
    @EnvironmentObject var authService: AuthService

    @State private var email       = ""
    @State private var password    = ""
    @State private var isLoading   = false
    @State private var errorMsg    = ""
    @State private var showForgot  = false
    @State private var showPwd     = false
    @State private var shake       = false

    var body: some View {
        VStack(spacing: 20) {
            // Fields
            VStack(spacing: 12) {
                AuthTextField(icon: "envelope.fill",    placeholder: "Email address",  text: $email,    keyboard: .emailAddress)
                AuthSecureField(icon: "lock.fill",      placeholder: "Password",       text: $password, show: $showPwd)
            }
            .padding(.horizontal, 28)
            .offset(x: shake ? -8 : 0)
            .animation(.default, value: shake)

            // Error
            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.warning)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            // Forgot password
            HStack {
                Spacer()
                Button("Forgot password?") { showForgot = true }
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.accentBlue)
            }
            .padding(.horizontal, 28)

            // Sign In button
            AuthActionButton(title: "Sign In", isLoading: isLoading) { signIn() }
                .padding(.horizontal, 28)

            // Divider
            AuthDivider()

            // Guest
            GuestButton()

        }
        .padding(.top, 24)
        .sheet(isPresented: $showForgot) { ForgotPasswordView() }
    }

    private func signIn() {
        errorMsg = ""
        isLoading = true
        authService.signIn(email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success: break
            case .failure(let err):
                errorMsg = err.errorDescription ?? "Error"
                withAnimation(.default) { shake = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
            }
        }
    }
}

// MARK: - RegisterFormView
struct RegisterFormView: View {
    var switchToLogin: () -> Void
    @EnvironmentObject var authService: AuthService

    @State private var name        = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var confirm     = ""
    @State private var isLoading   = false
    @State private var errorMsg    = ""
    @State private var showPwd     = false
    @State private var shake       = false

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                AuthTextField(icon: "person.fill",      placeholder: "Your name",       text: $name,     keyboard: .default)
                AuthTextField(icon: "envelope.fill",    placeholder: "Email address",   text: $email,    keyboard: .emailAddress)
                AuthSecureField(icon: "lock.fill",      placeholder: "Password (min 6 chars)", text: $password, show: $showPwd)
                AuthSecureField(icon: "lock.shield.fill", placeholder: "Confirm password", text: $confirm, show: $showPwd)
            }
            .padding(.horizontal, 28)
            .offset(x: shake ? -8 : 0)
            .animation(.default, value: shake)

            // Password strength
            if !password.isEmpty {
                PasswordStrengthBar(password: password)
                    .padding(.horizontal, 28)
            }

            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.warning)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            AuthActionButton(title: "Create Account", isLoading: isLoading) { register() }
                .padding(.horizontal, 28)

            AuthDivider()
            GuestButton()
        }
        .padding(.top, 24)
    }

    private func register() {
        errorMsg = ""
        guard password == confirm else {
            errorMsg = "Passwords do not match."
            withAnimation { shake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
            return
        }
        isLoading = true
        authService.signUp(email: email, password: password, name: name) { result in
            isLoading = false
            switch result {
            case .success: break
            case .failure(let err):
                errorMsg = err.errorDescription ?? "Error"
                withAnimation { shake = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
            }
        }
    }
}

// MARK: - ForgotPasswordView
struct ForgotPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var dismiss
    @State private var email   = ""
    @State private var sent    = false
    @State private var loading = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.15)
                VStack(spacing: 24) {
                    Image(systemName: sent ? "checkmark.seal.fill" : "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(sent ? AppColors.success : AppColors.accent)
                        .padding(.top, 40)
                        .animation(.spring(), value: sent)

                    Text(sent ? "Email Sent!" : "Reset Password")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(sent
                         ? "Check your inbox for a password reset link."
                         : "Enter your email and we'll send you a reset link.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if !sent {
                        AuthTextField(icon: "envelope.fill", placeholder: "Email address",
                                      text: $email, keyboard: .emailAddress)
                            .padding(.horizontal, 28)

                        AuthActionButton(title: "Send Reset Link", isLoading: loading) {
                            loading = true
                            authService.resetPassword(email: email) { _ in
                                loading = false
                                withAnimation { sent = true }
                            }
                        }
                        .padding(.horizontal, 28)
                    } else {
                        YellowButton(title: "Back to Login", disabled: false) {
                            dismiss.wrappedValue.dismiss()
                        }
                        .padding(.horizontal, 28)
                    }
                    Spacer()
                }
            }
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Shared Auth Components

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.accentBlue)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboard)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(text.isEmpty ? AppColors.accentBlue.opacity(0.25) : AppColors.accentBlue.opacity(0.55), lineWidth: 1))
    }
}

struct AuthSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.accentBlue)
                .frame(width: 20)
            Group {
                if show { TextField(placeholder, text: $text) }
                else    { SecureField(placeholder, text: $text) }
            }
            .foregroundColor(.white)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            Button { show.toggle() } label: {
                Image(systemName: show ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(text.isEmpty ? AppColors.accentBlue.opacity(0.25) : AppColors.accentBlue.opacity(0.55), lineWidth: 1))
    }
}

struct AuthActionButton: View {
    let title   : String
    let isLoading: Bool
    let action  : () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().progressViewStyle(.circular).tint(AppColors.background)
                        .scaleEffect(0.85)
                }
                Text(isLoading ? "Please wait…" : title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.background)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isLoading ? AppColors.accent.opacity(0.6) : AppColors.accent)
            .cornerRadius(14)
            .shadow(color: AppColors.accent.opacity(0.3), radius: 12, y: 6)
        }
        .disabled(isLoading)
        .scaleButtonStyle()
    }
}

struct AuthDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(AppColors.accentBlue.opacity(0.2)).frame(height: 1)
            Text("or").font(.system(size: 12)).foregroundColor(AppColors.secondaryText)
            Rectangle().fill(AppColors.accentBlue.opacity(0.2)).frame(height: 1)
        }
        .padding(.horizontal, 28)
    }
}

struct GuestButton: View {
    @EnvironmentObject var authService: AuthService
    var body: some View {
        Button { authService.continueAsGuest() } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 14))
                Text("Continue as Guest")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.cardBackground)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .scaleButtonStyle()
        .padding(.horizontal, 28)
        .padding(.bottom, 8)
    }
}

// MARK: - Password Strength Bar
struct PasswordStrengthBar: View {
    let password: String

    var strength: Int {
        var s = 0
        if password.count >= 6  { s += 1 }
        if password.count >= 10 { s += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { s += 1 }
        if password.rangeOfCharacter(from: .decimalDigits)   != nil { s += 1 }
        if password.rangeOfCharacter(from: .punctuationCharacters) != nil { s += 1 }
        return s
    }

    var label: String  { ["Very Weak","Weak","Fair","Strong","Very Strong"][min(strength, 4)] }
    var color: Color {
        [Color.red, AppColors.warning, .yellow, AppColors.success, AppColors.accentBlue][min(strength, 4)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < strength ? color : Color.white.opacity(0.1))
                        .frame(height: 4)
                        .animation(.spring(), value: strength)
                }
            }
            Text(label)
                .font(.system(size: 11)).foregroundColor(color)
        }
    }
}
