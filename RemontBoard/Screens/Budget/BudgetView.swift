import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showEditCategory: BudgetCategory?
    @State private var animateChart = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)

                ScrollView {
                    VStack(spacing: 20) {
                        BudgetSummaryCard(planned: appVM.totalPlanned, actual: appVM.totalActual)
                            .padding(.horizontal)

                        BudgetChartView(categories: appVM.budgetCategories, animate: animateChart)
                            .padding(.horizontal)

                        VStack(spacing: 10) {
                            ForEach(appVM.budgetCategories) { cat in
                                BudgetCategoryRow(category: cat)
                                    .onTapGesture { showEditCategory = cat }
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Room Breakdown").padding(.horizontal)
                            ForEach(appVM.rooms) { room in
                                RoomBudgetRow(room: room).padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 8).padding(.bottom, 100)
                }
            }
            .navigationTitle("Budget")
            .preferredColorScheme(.dark)
            .onAppear {
                withAnimation(.spring(response: 0.8).delay(0.2)) { animateChart = true }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(item: $showEditCategory) { cat in
            EditBudgetCategoryView(category: cat).environmentObject(appVM)
        }
    }
}

// MARK: - BudgetSummaryCard
struct BudgetSummaryCard: View {
    let planned: Double; let actual: Double
    var delta: Double { actual - planned }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Planned").font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                    Text("$\(Int(planned))").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Actual").font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                    Text("$\(Int(actual))").font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(delta > 0 ? AppColors.warning : AppColors.success)
                }
            }

            if abs(delta) > 0 {
                HStack {
                    Image(systemName: delta > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(delta > 0 ? AppColors.warning : AppColors.success)
                    Text(delta > 0
                         ? "Over budget by $\(Int(abs(delta)))"
                         : "Under budget by $\(Int(abs(delta)))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(delta > 0 ? AppColors.warning : AppColors.success)
                }
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background((delta > 0 ? AppColors.warning : AppColors.success).opacity(0.1))
                .cornerRadius(8)
            }

            if planned > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget Used: \(Int(min(actual / planned * 100, 999)))%")
                        .font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(delta > 0
                                    ? LinearGradient(colors: [AppColors.warning, .red], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [AppColors.accentBlue, AppColors.success], startPoint: .leading, endPoint: .trailing))
                                .frame(width: min(geo.size.width * CGFloat(actual / planned), geo.size.width), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(AppColors.accentBlue.opacity(0.28), lineWidth: 1))
    }
}

// MARK: - BudgetChartView
struct BudgetChartView: View {
    let categories: [BudgetCategory]
    let animate   : Bool

    var total: Double { categories.reduce(0) { $0 + max($1.actual, $1.planned) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Distribution")
                .font(.system(size: 13, weight: .bold)).foregroundColor(AppColors.secondaryText)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(categories) { cat in
                    let value    = max(cat.actual, cat.planned)
                    let fraction = total > 0 ? value / total : 0
                    VStack(spacing: 6) {
                        Text(cat.name).font(.system(size: 9)).foregroundColor(AppColors.secondaryText).lineLimit(1)
                        GeometryReader { geo in
                            VStack(spacing: 0) {
                                Spacer()
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: cat.color), Color(hex: cat.color).opacity(0.55)],
                                        startPoint: .top, endPoint: .bottom))
                                    .frame(height: animate ? CGFloat(fraction) * geo.size.height : 2)
                                    .animation(
                                        .spring(response: 0.7, dampingFraction: 0.7)
                                        .delay(Double(categories.firstIndex(where: {$0.id == cat.id}) ?? 0) * 0.1),
                                        value: animate)
                            }
                        }
                        .frame(height: 110)
                        Text("$\(Int(value))").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground).cornerRadius(14)
    }
}

// MARK: - BudgetCategoryRow
struct BudgetCategoryRow: View {
    let category: BudgetCategory
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: category.icon).foregroundColor(Color(hex: category.color)).frame(width: 24)
                Text(category.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Plan: $\(Int(category.planned))").font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
                    Text("Actual: $\(Int(category.actual))").font(.system(size: 11, weight: .bold))
                        .foregroundColor(category.isOverBudget ? AppColors.warning : AppColors.success)
                }
                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
            }
            if category.planned > 0 {
                ProgressBar(value: min(category.actual / category.planned, 1))
            }
        }
        .padding(12)
        .background(AppColors.cardBackground).cornerRadius(12)
    }
}

// MARK: - RoomBudgetRow
struct RoomBudgetRow: View {
    let room: Room
    var body: some View {
        HStack {
            Text(room.emoji).font(.title3)
            Text(room.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Label("$\(Int(room.totalMaterialCost))", systemImage: "shippingbox.fill")
                    .font(.system(size: 10)).foregroundColor(AppColors.accentBlue)
                Label("$\(Int(room.totalTaskCost))", systemImage: "person.fill")
                    .font(.system(size: 10)).foregroundColor(AppColors.success)
            }
            Text("$\(Int(room.totalMaterialCost + room.totalTaskCost))")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.accent).frame(width: 72, alignment: .trailing)
        }
        .padding(12)
        .background(AppColors.cardBackground).cornerRadius(12)
    }
}

// MARK: - EditBudgetCategoryView
struct EditBudgetCategoryView: View {
    let category: BudgetCategory
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var planned : String
    @State private var actual  : String

    init(category: BudgetCategory) {
        self.category = category
        _planned = State(initialValue: category.planned > 0 ? "\(Int(category.planned))" : "")
        _actual  = State(initialValue: category.actual  > 0 ? "\(Int(category.actual))"  : "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)
                VStack(spacing: 16) {
                    FormField(label: "Planned Amount ($)", placeholder: "0", text: $planned)
                    FormField(label: "Actual Amount ($)",  placeholder: "0", text: $actual)
                    YellowButton(title: "Save", disabled: false) { save() }.padding(.horizontal)
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle(category.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        var u = category
        u.planned = Double(planned) ?? 0
        u.actual  = Double(actual)  ?? 0
        appVM.updateBudgetCategory(u)
        dismiss.wrappedValue.dismiss()
    }
}
