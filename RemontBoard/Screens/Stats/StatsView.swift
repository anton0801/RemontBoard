import SwiftUI

// MARK: - StatsView (new analytics screen)
struct StatsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)
                GlowBlob(color: AppColors.accentBlue, x: 0.85, y: 0.1, size: 280)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Overall progress ring
                        OverallProgressCard(completion: appVM.overallCompletion)
                            .scaleEffect(appeared ? 1 : 0.85)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                        // Top summary row
                        HStack(spacing: 12) {
                            MiniStatCard(label: "Rooms",     value: "\(appVM.rooms.count)",
                                         icon: "building.2.fill", color: AppColors.accentBlue)
                            MiniStatCard(label: "Tasks",
                                         value: "\(appVM.rooms.reduce(0){$0+$1.tasks.count})",
                                         icon: "checkmark.square.fill", color: AppColors.success)
                            MiniStatCard(label: "Defects",   value: "\(appVM.totalDefects)",
                                         icon: "exclamationmark.triangle.fill", color: AppColors.warning)
                        }

                        // Budget overview
                        BudgetInsightCard()
                            .environmentObject(appVM)

                        // Per-room progress bars
                        RoomProgressCard()
                            .environmentObject(appVM)

                        // Task status pie-ish
                        TaskStatusCard()
                            .environmentObject(appVM)

                        // Defect breakdown
                        DefectBreakdownCard()
                            .environmentObject(appVM)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .onAppear { withAnimation { appeared = true } }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Overall Progress Ring
struct OverallProgressCard: View {
    let completion: Double
    @State private var animPct: Double = 0

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 14)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: animPct / 100)
                    .stroke(
                        AngularGradient(colors: [AppColors.accentBlue, AppColors.accent],
                                        center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1, dampingFraction: 0.7).delay(0.2), value: animPct)
                VStack(spacing: 1) {
                    Text("\(Int(animPct))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("done")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .onAppear { animPct = completion }

            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Progress")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(progressMessage(completion))
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.secondaryText)
                    .lineSpacing(3)
            }
            Spacer()
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(AppColors.accentBlue.opacity(0.25), lineWidth: 1))
    }

    private func progressMessage(_ pct: Double) -> String {
        switch pct {
        case 0:      return "Start tracking tasks\nto see your progress"
        case ..<25:  return "Just getting started.\nYou got this! 💪"
        case ..<50:  return "Good momentum.\nKeep going!"
        case ..<75:  return "More than halfway there.\nAlmost done! 🔥"
        case ..<100: return "Final stretch!\nLooking great 🏆"
        default:     return "Renovation complete! 🎉\nAmazing work!"
        }
    }
}

struct MiniStatCard: View {
    let label: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(AppColors.cardBackground).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Budget Insight
struct BudgetInsightCard: View {
    @EnvironmentObject var appVM: AppViewModel
    var totalSpent: Double { appVM.rooms.reduce(0) { $0 + $1.totalMaterialCost + $1.totalTaskCost } }
    var planned:    Double { appVM.totalPlanned }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Budget Overview")
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("$\(Int(planned))").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text("Planned").font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                Rectangle().fill(AppColors.accentBlue.opacity(0.2)).frame(width: 1, height: 44)
                VStack(spacing: 4) {
                    Text("$\(Int(totalSpent))").font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(totalSpent > planned && planned > 0 ? AppColors.warning : AppColors.success)
                    Text("Actual").font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                Rectangle().fill(AppColors.accentBlue.opacity(0.2)).frame(width: 1, height: 44)
                VStack(spacing: 4) {
                    let diff = totalSpent - planned
                    Text(planned > 0 ? (diff >= 0 ? "+$\(Int(diff))" : "-$\(Int(abs(diff)))") : "—")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(diff > 0 ? AppColors.warning : AppColors.success)
                    Text("Delta").font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
            if planned > 0 {
                ProgressBar(value: min(totalSpent / planned, 1))
            }
        }
        .padding(18)
        .background(AppColors.cardBackground).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.accentBlue.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Room Progress Card
struct RoomProgressCard: View {
    @EnvironmentObject var appVM: AppViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Progress by Room")
            if appVM.rooms.isEmpty {
                Text("No rooms yet").font(.system(size: 13)).foregroundColor(AppColors.secondaryText).padding(.vertical, 8)
            } else {
                ForEach(appVM.rooms) { room in
                    HStack(spacing: 12) {
                        Text(room.emoji).font(.system(size: 22)).frame(width: 32)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(room.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                Spacer()
                                Text("\(Int(room.completionPercentage))%")
                                    .font(.system(size: 12, weight: .bold)).foregroundColor(AppColors.accent)
                            }
                            ProgressBar(value: room.completionPercentage / 100)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(AppColors.cardBackground).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.accentBlue.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Task Status Card
struct TaskStatusCard: View {
    @EnvironmentObject var appVM: AppViewModel

    var allTasks: [RenovationTask] { appVM.rooms.flatMap { $0.tasks } }
    var todoCount: Int       { allTasks.filter { $0.status == .todo       }.count }
    var inProgCount: Int     { allTasks.filter { $0.status == .inProgress }.count }
    var doneCount: Int       { allTasks.filter { $0.status == .done       }.count }
    var total: Int           { allTasks.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Task Distribution")
            HStack(spacing: 10) {
                TaskStatusPill(label: "To Do",       count: todoCount,   color: .gray,             total: total)
                TaskStatusPill(label: "In Progress", count: inProgCount, color: AppColors.accent,   total: total)
                TaskStatusPill(label: "Done",        count: doneCount,   color: AppColors.success,  total: total)
            }
        }
        .padding(18)
        .background(AppColors.cardBackground).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.accentBlue.opacity(0.2), lineWidth: 1))
    }
}

struct TaskStatusPill: View {
    let label: String; let count: Int; let color: Color; let total: Int
    var fraction: Double { total > 0 ? Double(count) / Double(total) : 0 }
    @State private var anim = false
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.1)).frame(height: 60)
                RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.75))
                    .frame(height: anim ? CGFloat(fraction) * 60 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: anim)
            }
            Text("\(count)").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundColor(AppColors.secondaryText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .onAppear { anim = true }
    }
}

// MARK: - Defect Breakdown
struct DefectBreakdownCard: View {
    @EnvironmentObject var appVM: AppViewModel
    var allDefects: [Defect] { appVM.rooms.flatMap { $0.defects } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionLabel(text: "Defect Breakdown")
                Spacer()
                if !allDefects.isEmpty {
                    Text("\(allDefects.filter{!$0.isResolved}.count) open")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.warning)
                }
            }
            if allDefects.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill").foregroundColor(AppColors.success)
                    Text("No defects recorded 👍").font(.system(size: 13)).foregroundColor(AppColors.secondaryText)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(DefectType.allCases, id: \.self) { type in
                    let count = allDefects.filter { $0.type == type }.count
                    if count > 0 {
                        HStack(spacing: 10) {
                            Image(systemName: type.icon).font(.system(size: 13)).foregroundColor(type.color).frame(width: 20)
                            Text(type.rawValue).font(.system(size: 13)).foregroundColor(.white)
                            Spacer()
                            Text("\(count)").font(.system(size: 13, weight: .bold)).foregroundColor(type.color)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(18)
        .background(AppColors.cardBackground).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.accentBlue.opacity(0.2), lineWidth: 1))
    }
}
