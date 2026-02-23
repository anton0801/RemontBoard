import SwiftUI

struct RoomDetailView: View {
    let room: Room
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var showAddTask     = false
    @State private var showAddMaterial = false
    @State private var showAddDefect   = false
    @State private var showImagePicker = false
    @State private var showEditRoom    = false
    @State private var activeTab       = 0

    var currentRoom: Room {
        appVM.rooms.first { $0.id == room.id } ?? room
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)

                VStack(spacing: 0) {
                    RoomHeaderCard(room: currentRoom)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    RoomTabBar(selectedTab: $activeTab)
                        .padding(.top, 14)

                    TabView(selection: $activeTab) {
                        RoomOverviewTab(room: currentRoom)
                            .environmentObject(appVM)
                            .tag(0)
                        TasksTab(room: currentRoom, showAdd: $showAddTask)
                            .environmentObject(appVM)
                            .tag(1)
                        MaterialsTab(room: currentRoom, showAdd: $showAddMaterial)
                            .environmentObject(appVM)
                            .tag(2)
                        DefectsTab(room: currentRoom, showAdd: $showAddDefect)
                            .environmentObject(appVM)
                            .tag(3)
                        PhotosTab(room: currentRoom, showPicker: $showImagePicker)
                            .environmentObject(appVM)
                            .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.22), value: activeTab)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("\(currentRoom.emoji)  \(currentRoom.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(AppColors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showEditRoom = true } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddTask)     { AddTaskView(roomId: room.id).environmentObject(appVM) }
        .sheet(isPresented: $showAddMaterial) { AddMaterialView(roomId: room.id).environmentObject(appVM) }
        .sheet(isPresented: $showAddDefect)   { AddDefectView(roomId: room.id).environmentObject(appVM) }
        .sheet(isPresented: $showEditRoom)    { EditRoomView(room: currentRoom).environmentObject(appVM) }
        .sheet(isPresented: $showImagePicker) { ImagePickerView(roomId: room.id).environmentObject(appVM) }
    }
}

// MARK: - Header Card
struct RoomHeaderCard: View {
    let room: Room
    var body: some View {
        HStack(spacing: 16) {
            Text(room.emoji).font(.system(size: 44))

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", room.area)) m²")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                    RenovationTypeBadge(type: room.renovationType)
                }
                HStack(spacing: 8) {
                    ProgressBar(value: room.completionPercentage / 100)
                    Text("\(Int(room.completionPercentage))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.accent)
                        .frame(width: 36)
                }
                Label("$\(Int(room.totalMaterialCost + room.totalTaskCost))",
                      systemImage: "banknote")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.success)
            }
            Spacer()
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(AppColors.accentBlue.opacity(0.28), lineWidth: 1))
    }
}

// MARK: - Tab Bar
struct RoomTabBar: View {
    @Binding var selectedTab: Int
    let tabs  = ["Overview","Tasks","Materials","Defects","Photos"]
    let icons = ["square.grid.2x2","checkmark.square","shippingbox","exclamationmark.triangle","photo"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { i in
                    Button { withAnimation(.spring()) { selectedTab = i } } label: {
                        VStack(spacing: 4) {
                            Image(systemName: icons[i]).font(.system(size: 14))
                            Text(tabs[i]).font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == i ? AppColors.background : Color.white.opacity(0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTab == i ? AppColors.accent : Color.clear)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding(.horizontal, 14)
        }
    }
}

// MARK: - Overview Tab
struct RoomOverviewTab: View {
    let room: Room
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                InfoGrid(room: room)
                HStack(spacing: 12) {
                    MiniStat(label: "Tasks",   value: "\(room.tasks.count)",
                             icon: "checkmark.square.fill", color: AppColors.accentBlue)
                    MiniStat(label: "Done",    value: "\(room.tasks.filter{$0.status == .done}.count)",
                             icon: "checkmark.circle.fill",  color: AppColors.success)
                    MiniStat(label: "Defects", value: "\(room.defects.count)",
                             icon: "exclamationmark.triangle.fill", color: AppColors.warning)
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
}

struct InfoGrid: View {
    let room: Room
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Room Specifications").padding(.bottom, 10)
            VStack(spacing: 1) {
                InfoRow(label: "Floor",     value: room.floorType.rawValue,      icon: "square.fill")
                InfoRow(label: "Walls",     value: room.wallType.rawValue,       icon: "rectangle.portrait.fill")
                InfoRow(label: "Ceiling",   value: room.ceilingType.rawValue,    icon: "rectangle.fill")
                InfoRow(label: "Electrical",value: room.hasElectricalWork ? "Yes" : "No", icon: "bolt.fill")
                InfoRow(label: "Area",      value: "\(String(format: "%.1f", room.area)) m²", icon: "ruler.fill")
            }
            .cornerRadius(12)
            if !room.notes.isEmpty {
                Text(room.notes)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.secondaryText)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .padding(.top, 8)
            }
        }
    }
}

struct InfoRow: View {
    let label: String; let value: String; let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 12))
                .foregroundColor(AppColors.accentBlue).frame(width: 20)
            Text(label).font(.system(size: 13)).foregroundColor(AppColors.secondaryText)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(AppColors.cardBackground)
    }
}

struct MiniStat: View {
    let label: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(AppColors.cardBackground).cornerRadius(12)
    }
}
