import SwiftUI

// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject var authService : AuthService
    @EnvironmentObject var appVM       : AppViewModel

    @State private var showEditName       = false
    @State private var showDeleteConfirm  = false
    @State private var showSignOutConfirm = false
    @State private var showTips           = false
    @State private var appeared           = false
    @State private var showDefects           = false

    var user: AppUser? { authService.currentUser }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)
                GlowBlob(color: AppColors.accent,    x: 0.9, y: 0.05, size: 260)
                GlowBlob(color: AppColors.accentBlue, x: 0.05, y: 0.6, size: 220)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Avatar card
                        ProfileAvatarCard(user: user, showEdit: $showEditName)
                            .scaleEffect(appeared ? 1 : 0.9)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                        // Stats bar
                        ProfileStatsBar()
                            .environmentObject(appVM)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)

                        // Guest upgrade banner
                        if user?.isGuest == true {
                            GuestUpgradeBanner()
                                .environmentObject(authService)
                        }

                        // Menu sections
                        ProfileMenuSection(title: "Apartment") {
                            ProfileMenuItem(icon: "building.2.fill",         color: AppColors.accentBlue,  label: "Total Rooms",     value: "\(appVM.rooms.count)")
                            ProfileMenuItem(icon: "checkmark.circle.fill",   color: AppColors.success,     label: "Overall Progress", value: "\(Int(appVM.overallCompletion))%")
                            Button {
                                showDefects = true
                            } label: {
                                ProfileMenuItem(icon: "exclamationmark.triangle.fill", color: AppColors.warning, label: "Open Defects",  value: "\(appVM.openDefects)")
                            }
                        }

                        ProfileMenuSection(title: "App Settings") {
                            ProfileMenuButton(icon: "lightbulb.fill", color: Color(hex: "#F5C842"),
                                              label: "Renovation Tips") { showTips = true }
                            ProfileMenuButton(icon: "arrow.clockwise.circle.fill", color: AppColors.accentBlue,
                                              label: "Reset All Data") { showDeleteConfirm = true }
                        }

                        ProfileMenuSection(title: "Account") {
                            if user?.isGuest == false {
                                ProfileMenuButton(icon: "person.crop.circle.badge.xmark", color: AppColors.warning,
                                                  label: "Sign Out") { showSignOutConfirm = true }
                                ProfileMenuButton(icon: "trash.fill", color: .red,
                                                  label: "Delete Account", destructive: true) { showDeleteConfirm = true }
                            } else {
                                ProfileMenuButton(icon: "arrow.right.circle.fill", color: AppColors.accent,
                                                  label: "Sign In / Create Account") {
                                    authService.signOut()
                                }
                            }
                        }

                        // App version
                        Text("Remont Board v1.1.0  ·  Built with ❤️")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.secondaryText.opacity(0.5))
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .onAppear { withAnimation { appeared = true } }
        }
        .navigationViewStyle(.stack)
        // Sheets & alerts
        .sheet(isPresented: $showEditName) {
            EditNameView().environmentObject(authService)
        }
        .sheet(isPresented: $showTips) {
            RenovationTipsView()
        }
        .alert(isPresented: $showSignOutConfirm) {
            Alert(title: Text("Sign Out?"),
                  message: Text("Your local data will remain on this device."),
                  primaryButton: .destructive(Text("Sign Out")) { authService.signOut() },
                  secondaryButton: .cancel())
        }
        .actionSheet(isPresented: $showDeleteConfirm) {
            ActionSheet(
                title: Text("Delete Account & Data"),
                message: Text("This permanently removes your account and all renovation data. This cannot be undone."),
                buttons: [
                    .destructive(Text("Delete Everything")) {
                        authService.deleteAccount { _ in }
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showDefects) {
            DefectsOverviewView().environmentObject(appVM)
        }
    }
}

// MARK: - AvatarCard
struct ProfileAvatarCard: View {
    let user     : AppUser?
    @Binding var showEdit: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(user?.avatarColor.opacity(0.18) ?? AppColors.accentBlue.opacity(0.15))
                    .frame(width: 90, height: 90)
                Circle()
                    .stroke(user?.avatarColor.opacity(0.5) ?? AppColors.accentBlue.opacity(0.4), lineWidth: 2)
                    .frame(width: 90, height: 90)
                Text(user?.initials ?? "?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(user?.displayName ?? "Guest")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if user?.isGuest == false {
                        Button { showEdit = true } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
                if let email = user?.email {
                    Text(email)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                }
                // Guest / verified badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(user?.isGuest == true ? AppColors.warning : AppColors.success)
                        .frame(width: 7, height: 7)
                    Text(user?.isGuest == true ? "Guest Mode" : "Verified Account")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(user?.isGuest == true ? AppColors.warning : AppColors.success)
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background((user?.isGuest == true ? AppColors.warning : AppColors.success).opacity(0.1))
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(AppColors.cardBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.accentBlue.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Stats Bar
struct ProfileStatsBar: View {
    @EnvironmentObject var appVM: AppViewModel

    var totalCost: Double { appVM.rooms.reduce(0) { $0 + $1.totalMaterialCost + $1.totalTaskCost } }

    var body: some View {
        HStack(spacing: 1) {
            ProfileStatPill(value: "\(appVM.rooms.reduce(0){$0+$1.tasks.count})",
                            label: "Tasks", icon: "checkmark.square.fill", color: AppColors.accentBlue)
            ProfileStatPill(value: "\(appVM.rooms.reduce(0){$0+$1.materials.count})",
                            label: "Materials", icon: "shippingbox.fill", color: AppColors.success)
            ProfileStatPill(value: "$\(Int(totalCost))",
                            label: "Spent", icon: "banknote.fill", color: AppColors.accent)
        }
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.accentBlue.opacity(0.2), lineWidth: 1))
    }
}

struct ProfileStatPill: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
    }
}

// MARK: - Guest Upgrade Banner
struct GuestUpgradeBanner: View {
    @EnvironmentObject var authService: AuthService
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "icloud.fill")
                .font(.system(size: 22))
                .foregroundColor(AppColors.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Save your data to cloud")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                Text("Create an account to back up your renovation plans")
                    .font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
            }
            Spacer()
            Button { authService.signOut() } label: {
                Text("Sign Up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.background)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(AppColors.accent).cornerRadius(8)
            }
        }
        .padding(16)
        .background(AppColors.accent.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.accent.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Menu helpers
struct ProfileMenuSection<Content: View>: View {
    let title  : String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.accentBlue)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.leading, 4).padding(.bottom, 8)
            VStack(spacing: 1) { content }
                .background(AppColors.cardBackground)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.accentBlue.opacity(0.18), lineWidth: 1))
        }
    }
}

struct ProfileMenuItem: View {
    let icon: String; let color: Color; let label: String; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color).frame(width: 28)
            Text(label).font(.system(size: 14)).foregroundColor(.white)
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundColor(AppColors.secondaryText)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .overlay(Rectangle().fill(AppColors.accentBlue.opacity(0.1)).frame(height: 1), alignment: .bottom)
    }
}

struct ProfileMenuButton: View {
    let icon        : String
    let color       : Color
    let label       : String
    var destructive : Bool = false
    let action      : () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color).frame(width: 28)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(destructive ? .red : .white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
            .overlay(Rectangle().fill(AppColors.accentBlue.opacity(0.1)).frame(height: 1), alignment: .bottom)
        }
        .scaleButtonStyle()
    }
}

// MARK: - Edit Name Sheet
struct EditNameView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var dismiss
    @State private var name    = ""
    @State private var loading = false
    @State private var success = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.15)
                VStack(spacing: 20) {
                    Image(systemName: success ? "checkmark.circle.fill" : "person.crop.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(success ? AppColors.success : AppColors.accent)
                        .padding(.top, 40)
                        .animation(.spring(), value: success)

                    Text(success ? "Name Updated!" : "Edit Display Name")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if !success {
                        AuthTextField(icon: "person.fill", placeholder: "Your name", text: $name, keyboard: .default)
                            .padding(.horizontal, 28)

                        AuthActionButton(title: "Save", isLoading: loading) {
                            loading = true
                            authService.updateProfile(name: name) { _ in
                                loading = false
                                withAnimation { success = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    dismiss.wrappedValue.dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                    }
                    Spacer()
                }
                .onAppear { name = authService.currentUser?.displayName ?? "" }
            }
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Renovation Tips
struct RenovationTipsView: View {
    @Environment(\.presentationMode) var dismiss
    @State private var currentTip = 0

    let tips: [RenovationTip] = [
        RenovationTip(icon: "ruler.fill", title: "Measure Twice, Buy Once",
                      body: "Always add 10–15% extra to material calculations for waste, cuts, and mistakes. It's much cheaper than making a second trip.",
                      color: "#4A90D9"),
        RenovationTip(icon: "calendar.badge.clock", title: "Plan the Sequence",
                      body: "Always work top-to-bottom: ceiling → walls → floor. Never lay flooring before the ceiling is done — you'll damage it.",
                      color: "#F5C842"),
        RenovationTip(icon: "drop.fill", title: "Check for Moisture First",
                      body: "Before any finishing work, use a moisture meter. Tiling or painting over a damp wall guarantees you'll redo it within a year.",
                      color: "#5BC8A3"),
        RenovationTip(icon: "bolt.fill", title: "Electrical Before Walls",
                      body: "Route all electrical conduits and cables before plastering or drywalling. Retrofitting is 3× more expensive and twice as disruptive.",
                      color: "#A78BFA"),
        RenovationTip(icon: "camera.fill", title: "Document Everything",
                      body: "Photograph walls before closing them up. You'll be glad you know where every cable and pipe runs five years from now.",
                      color: "#E87D5A"),
        RenovationTip(icon: "banknote.fill", title: "Budget for the Unexpected",
                      body: "Add a 20% contingency buffer to your total budget. Renovations almost always reveal hidden problems once walls are opened.",
                      color: "#FF6B9D"),
        RenovationTip(icon: "star.fill", title: "Don't Skimp on Primers",
                      body: "A good primer makes the difference between paint that lasts 2 years and paint that lasts 10. It's cheap insurance.",
                      color: "#5BC8A3"),
        RenovationTip(icon: "hammer.fill", title: "Hire Right",
                      body: "Get at least 3 quotes. The cheapest bidder is rarely the best value. Ask to see previous projects and check reviews.",
                      color: "#F5C842"),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.15)
                GlowBlob(color: Color(hex: tips[currentTip].color), x: 0.5, y: 0.3, size: 350)

                VStack(spacing: 0) {
                    TabView(selection: $currentTip) {
                        ForEach(Array(tips.enumerated()), id: \.offset) { idx, tip in
                            TipCard(tip: tip).tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentTip)

                    // Indicators
                    HStack(spacing: 6) {
                        ForEach(0..<tips.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentTip ? Color(hex: tips[currentTip].color) : Color.white.opacity(0.2))
                                .frame(width: i == currentTip ? 10 : 6, height: i == currentTip ? 10 : 6)
                                .animation(.spring(), value: currentTip)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Pro Tips 💡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }
}

struct RenovationTip {
    let icon: String; let title: String; let body: String; let color: String
}

struct TipCard: View {
    let tip: RenovationTip
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle().fill(Color(hex: tip.color).opacity(0.14)).frame(width: 110, height: 110)
                Image(systemName: tip.icon).font(.system(size: 48)).foregroundColor(Color(hex: tip.color))
            }
            .scaleEffect(appeared ? 1 : 0.6).opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

            VStack(spacing: 16) {
                Text(tip.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white).multilineTextAlignment(.center)
                Text(tip.body)
                    .font(.system(size: 16)).foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center).lineSpacing(5)
                    .padding(.horizontal, 32)
            }
            .offset(y: appeared ? 0 : 24).opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .onAppear  { appeared = true  }
        .onDisappear { appeared = false }
    }
}
