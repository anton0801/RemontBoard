import SwiftUI

// MARK: - MaterialsTab
struct MaterialsTab: View {
    let room     : Room
    @Binding var showAdd: Bool
    @EnvironmentObject var appVM: AppViewModel
    @State private var showCalculator = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Button { showAdd = true } label: {
                        Label("Add Material", systemImage: "plus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(AppColors.accent).cornerRadius(12)
                    }
                    .scaleButtonStyle()

                    Button { showCalculator = true } label: {
                        Label("Calculator", systemImage: "function")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.accentBlue)
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(AppColors.accentBlue.opacity(0.14))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.accentBlue.opacity(0.4), lineWidth: 1))
                    }
                    .scaleButtonStyle()
                }

                if room.materials.isEmpty {
                    EmptyStateView(icon: "shippingbox",
                                   message: "No materials added.\nTap + to track materials.")
                } else {
                    TotalCostCard(materials: room.materials)

                    ForEach(MaterialCategory.allCases, id: \.self) { cat in
                        let items = room.materials.filter { $0.category == cat }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(cat.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(.leading, 4)
                                ForEach(items) { m in
                                    MaterialCard(material: m, roomId: room.id)
                                        .environmentObject(appVM)
                                }
                            }
                        }
                    }
                }
            }
            .padding().padding(.bottom, 80)
        }
        .sheet(isPresented: $showCalculator) {
            MaterialCalculatorView(room: room)
        }
    }
}

// MARK: - TotalCostCard
struct TotalCostCard: View {
    let materials: [Material]
    var totalCost: Double { materials.reduce(0) { $0 + $1.totalCost } }
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Material Cost")
                    .font(.system(size: 12)).foregroundColor(AppColors.secondaryText)
                Text("$\(String(format: "%.2f", totalCost))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.success)
            }
            Spacer()
            Image(systemName: "banknote.fill")
                .font(.system(size: 28)).foregroundColor(AppColors.success.opacity(0.45))
        }
        .padding(16)
        .background(AppColors.cardBackground).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(AppColors.success.opacity(0.28), lineWidth: 1))
    }
}

// MARK: - MaterialCard
struct MaterialCard: View {
    let material: Material; let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(material.name)
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    TierBadge(tier: material.tier)
                }
                Text("\(String(format: "%.1f", material.quantity)) \(material.unit) × $\(String(format: "%.2f", material.pricePerUnit))")
                    .font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                Text(material.category.rawValue)
                    .font(.system(size: 9)).foregroundColor(AppColors.accentBlue)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", material.totalCost))")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(AppColors.success)
                Button("Edit") { showEdit = true }
                    .font(.system(size: 10)).foregroundColor(AppColors.accentBlue)
            }
        }
        .padding(12)
        .background(AppColors.cardBackground).cornerRadius(12)
        .sheet(isPresented: $showEdit) {
            EditMaterialView(material: material, roomId: roomId).environmentObject(appVM)
        }
    }
}

// MARK: - AddMaterialView
struct AddMaterialView: View {
    let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var name     = ""
    @State private var category : MaterialCategory = .walls
    @State private var quantity = "1"
    @State private var unit     = "m²"
    @State private var price    = ""
    @State private var tier     : MaterialTier = .mid
    @State private var supplier = ""

    let units = ["m²","m","pcs","kg","L","box","roll","bag","sheet"]

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)
                ScrollView {
                    VStack(spacing: 16) {
                        FormField(label: "Material Name", placeholder: "e.g. Ceramic tiles", text: $name)
                        PickerField(label: "Category", selection: $category, options: MaterialCategory.allCases)

                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 6) {
                                SectionLabel(text: "Quantity")
                                TextField("1", text: $quantity)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 12)
                                    .background(AppColors.cardBackground).cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppColors.accentBlue.opacity(0.35), lineWidth: 1))
                            }
                            .padding(.leading, 16).padding(.trailing, 6)

                            VStack(alignment: .leading, spacing: 6) {
                                SectionLabel(text: "Unit")
                                Picker("", selection: $unit) {
                                    ForEach(units, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(AppColors.cardBackground).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppColors.accentBlue.opacity(0.35), lineWidth: 1))
                            }
                            .padding(.trailing, 16)
                        }

                        FormField(label: "Price per Unit ($)", placeholder: "0.00", text: $price)
                        FormField(label: "Supplier", placeholder: "Optional", text: $supplier)

                        // Tier
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Quality Tier").padding(.leading, 16)
                            HStack(spacing: 10) {
                                ForEach(MaterialTier.allCases, id: \.self) { t in
                                    Button { tier = t } label: {
                                        Text(t.rawValue)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(tier == t ? .white : t.color)
                                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                                            .background(tier == t ? t.color : t.color.opacity(0.14))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        if let q = Double(quantity), let p = Double(price), q > 0, p > 0 {
                            HStack {
                                Text("Total Cost:").font(.system(size: 13))
                                    .foregroundColor(AppColors.secondaryText)
                                Spacer()
                                Text("$\(String(format: "%.2f", q * p))")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppColors.success)
                            }
                            .padding()
                            .background(AppColors.cardBackground).cornerRadius(12)
                            .padding(.horizontal)
                        }

                        YellowButton(title: "Add Material", disabled: name.isEmpty) { save() }
                            .padding(.horizontal).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Material").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let m = Material(name: name, category: category,
                          quantity: Double(quantity) ?? 1, unit: unit,
                          pricePerUnit: Double(price) ?? 0, tier: tier, supplier: supplier)
        appVM.addMaterial(m, to: roomId)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - EditMaterialView
struct EditMaterialView: View {
    let material: Material; let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var name     : String
    @State private var quantity : String
    @State private var price    : String
    @State private var tier     : MaterialTier
    @State private var category : MaterialCategory
    @State private var unit     : String

    init(material: Material, roomId: UUID) {
        self.material = material; self.roomId = roomId
        _name     = State(initialValue: material.name)
        _quantity = State(initialValue: String(format: "%.1f", material.quantity))
        _price    = State(initialValue: String(format: "%.2f", material.pricePerUnit))
        _tier     = State(initialValue: material.tier)
        _category = State(initialValue: material.category)
        _unit     = State(initialValue: material.unit)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormField(label: "Name",           placeholder: "Material name", text: $name)
                        FormField(label: "Quantity",       placeholder: "1",             text: $quantity)
                        FormField(label: "Price/Unit ($)", placeholder: "0",             text: $price)
                        PickerField(label: "Category", selection: $category, options: MaterialCategory.allCases)

                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Quality Tier").padding(.leading, 16)
                            HStack(spacing: 10) {
                                ForEach(MaterialTier.allCases, id: \.self) { t in
                                    Button { tier = t } label: {
                                        Text(t.rawValue)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(tier == t ? .white : t.color)
                                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                                            .background(tier == t ? t.color : t.color.opacity(0.14))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        HStack(spacing: 12) {
                            YellowButton(title: "Save", disabled: name.isEmpty) { save() }
                            Button { delete() } label: {
                                Image(systemName: "trash").foregroundColor(AppColors.warning)
                                    .padding(16).background(AppColors.warning.opacity(0.14)).cornerRadius(12)
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Material").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        var m = material
        m.name = name; m.quantity = Double(quantity) ?? 1
        m.pricePerUnit = Double(price) ?? 0; m.tier = tier; m.category = category
        appVM.updateMaterial(m, in: roomId)
        dismiss.wrappedValue.dismiss()
    }
    private func delete() {
        appVM.deleteMaterial(material, from: roomId)
        dismiss.wrappedValue.dismiss()
    }
}
