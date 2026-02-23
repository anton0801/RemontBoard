import SwiftUI

struct MaterialCalculatorView: View {
    let room: Room
    @Environment(\.presentationMode) var dismiss

    @State private var area            : String
    @State private var selectedFloor   : FloorType
    @State private var selectedWall    : WallType
    @State private var wasteFactor     = 0.10
    @State private var selectedTier    : MaterialTier = .mid
    @State private var results         : [CalcResult] = []
    @State private var calculated      = false

    // Price per m² by [tier]
    let floorPrices: [FloorType: [MaterialTier: Double]] = [
        .laminate: [.budget: 8,  .mid: 18,  .premium: 35],
        .tile:     [.budget: 12, .mid: 25,  .premium: 60],
        .parquet:  [.budget: 20, .mid: 45,  .premium: 120],
        .linoleum: [.budget: 5,  .mid: 12,  .premium: 25],
        .carpet:   [.budget: 6,  .mid: 15,  .premium: 40]
    ]
    let wallPrices: [WallType: [MaterialTier: Double]] = [
        .paint:     [.budget: 3,  .mid: 7,  .premium: 18],
        .wallpaper: [.budget: 4,  .mid: 10, .premium: 28],
        .tile:      [.budget: 15, .mid: 30, .premium: 70],
        .plaster:   [.budget: 8,  .mid: 18, .premium: 45]
    ]

    init(room: Room) {
        self.room = room
        _area         = State(initialValue: room.area > 0 ? String(format: "%.1f", room.area) : "")
        _selectedFloor = State(initialValue: room.floorType)
        _selectedWall  = State(initialValue: room.wallType)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)

                ScrollView {
                    VStack(spacing: 20) {
                        FormField(label: "Room Area (m²)", placeholder: "e.g. 20", text: $area)

                        // Floor picker
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel(text: "Floor Type").padding(.leading, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(FloorType.allCases, id: \.self) { f in
                                        SegmentButton(title: f.rawValue, isSelected: selectedFloor == f) { selectedFloor = f }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // Wall picker
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel(text: "Wall Coverage").padding(.leading, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(WallType.allCases, id: \.self) { w in
                                        SegmentButton(title: w.rawValue, isSelected: selectedWall == w) { selectedWall = w }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // Waste slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SectionLabel(text: "Waste Allowance").padding(.leading, 16)
                                Spacer()
                                Text("\(Int(wasteFactor * 100))%")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppColors.accent)
                                    .padding(.trailing, 16)
                            }
                            Slider(value: $wasteFactor, in: 0.05...0.30, step: 0.05)
                                .accentColor(AppColors.accent)
                                .padding(.horizontal)
                        }

                        // Tier
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Highlight Tier").padding(.leading, 16)
                            HStack(spacing: 10) {
                                ForEach(MaterialTier.allCases, id: \.self) { t in
                                    Button { selectedTier = t } label: {
                                        Text(t.rawValue)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(selectedTier == t ? .white : t.color)
                                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                                            .background(selectedTier == t ? t.color : t.color.opacity(0.14))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Button { calculate() } label: {
                            HStack {
                                Image(systemName: "function")
                                Text("Calculate").font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(AppColors.accent).cornerRadius(14)
                        }
                        .scaleButtonStyle()
                        .padding(.horizontal)

                        if calculated {
                            VStack(spacing: 12) {
                                ForEach(results) { result in
                                    CalcResultCard(result: result, highlightTier: selectedTier)
                                }
                                TierComparisonCard(results: results)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.top, 16).padding(.bottom, 60)
                }
            }
            .navigationTitle("Material Calculator").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }

    private func calculate() {
        guard let a = Double(area), a > 0 else { return }
        let floorArea = a * (1 + wasteFactor)
        let wallArea  = a * 2.5 * (1 + wasteFactor)   // rough wall estimate
        var res: [CalcResult] = []

        if let prices = floorPrices[selectedFloor] {
            res.append(CalcResult(type: "Floor (\(selectedFloor.rawValue))",
                                   quantity: floorArea, unit: "m²",
                                   icon: "square.fill", prices: prices))
        }
        if let prices = wallPrices[selectedWall] {
            res.append(CalcResult(type: "Walls (\(selectedWall.rawValue))",
                                   quantity: wallArea, unit: "m²",
                                   icon: "rectangle.portrait.fill", prices: prices))
        }
        res.append(CalcResult(type: "Primer",
                               quantity: (a + a * 2.5) * (1 + wasteFactor), unit: "m²",
                               icon: "paintbrush.fill",
                               prices: [.budget: 0.5, .mid: 1.2, .premium: 2.5]))

        withAnimation(.spring()) { results = res; calculated = true }
    }
}

// MARK: - Supporting types
struct CalcResult: Identifiable {
    let id       = UUID()
    let type     : String
    let quantity : Double
    let unit     : String
    let icon     : String
    let prices   : [MaterialTier: Double]
}

struct CalcResultCard: View {
    let result       : CalcResult
    let highlightTier: MaterialTier

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: result.icon).foregroundColor(AppColors.accentBlue)
                Text(result.type).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                Spacer()
                Text("\(String(format: "%.1f", result.quantity)) \(result.unit)")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(AppColors.accent)
            }
            HStack(spacing: 8) {
                ForEach(MaterialTier.allCases, id: \.self) { tier in
                    let cost = (result.prices[tier] ?? 0) * result.quantity
                    VStack(spacing: 4) {
                        Text(tier.rawValue).font(.system(size: 9, weight: .bold)).foregroundColor(tier.color)
                        Text("$\(Int(cost))").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(tier == highlightTier ? tier.color.opacity(0.18) : Color.white.opacity(0.04))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(tier == highlightTier ? tier.color : Color.clear, lineWidth: 1.5))
                }
            }
        }
        .padding(14).background(AppColors.cardBackground).cornerRadius(14)
        .padding(.horizontal)
    }
}

struct TierComparisonCard: View {
    let results: [CalcResult]
    func total(for tier: MaterialTier) -> Double {
        results.reduce(0) { $0 + (($1.prices[tier] ?? 0) * $1.quantity) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Cost Comparison")
                .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            HStack(spacing: 8) {
                ForEach(MaterialTier.allCases, id: \.self) { tier in
                    VStack(spacing: 6) {
                        Text(tier.rawValue).font(.system(size: 10, weight: .bold)).foregroundColor(tier.color)
                        Text("$\(Int(total(for: tier)))")
                            .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(tier.color.opacity(0.10)).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(tier.color.opacity(0.4), lineWidth: 1))
                }
            }
        }
        .padding(16).background(AppColors.cardBackground).cornerRadius(14)
        .padding(.horizontal)
    }
}
