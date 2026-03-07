import SwiftUI

struct ApartmentView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var showAddRoom   = false
    @State private var selectedRoom  : Room?
    @State private var animateCards  = false
    @State private var showSearch    = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.22)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Stats header
                        HStack(spacing: 12) {
                            StatChip(icon: "building.2.fill",
                                     value: "\(appVM.rooms.count)",
                                     label: "Rooms",
                                     color: AppColors.accentBlue)
                            StatChip(icon: "checkmark.circle.fill",
                                     value: "\(Int(appVM.overallCompletion))%",
                                     label: "Done",
                                     color: AppColors.success)
                            StatChip(icon: "exclamationmark.triangle.fill",
                                     value: "\(appVM.openDefects)",
                                     label: "Issues",
                                     color: AppColors.warning)
                        }
                        .padding(.horizontal)

                        // Room grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(appVM.rooms.enumerated()), id: \.element.id) { idx, room in
                                RoomCard(room: room)
                                    .scaleEffect(animateCards ? 1 : 0.8)
                                    .opacity(animateCards ? 1 : 0)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(idx) * 0.07),
                                        value: animateCards
                                    )
                                    .onTapGesture { selectedRoom = room }
                            }

                            AddRoomCard()
                                .onTapGesture { showAddRoom = true }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("My Apartment")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSearch = true } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.accent)
                            .font(.system(size: 18))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddRoom = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.accent)
                            .font(.system(size: 22))
                    }
                }
            }
            .onAppear { withAnimation { animateCards = true } }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .accentColor(AppColors.accent)
        .sheet(isPresented: $showAddRoom) {
            AddRoomView().environmentObject(appVM)
        }
        .sheet(item: $selectedRoom) { room in
            RoomDetailView(room: room).environmentObject(appVM)
        }
        .sheet(isPresented: $showSearch) {
            GlobalSearchView().environmentObject(appVM)
        }
    }
}

// MARK: - RoomCard
struct RoomCard: View {
    let room: Room

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(room.emoji).font(.system(size: 32))
                Spacer()
                RenovationTypeBadge(type: room.renovationType)
            }

            Text(room.name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(String(format: "%.1f", room.area)) m²")
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.secondaryText)
                    Spacer()
                    Text("\(Int(room.completionPercentage))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.accent)
                }
                ProgressBar(value: room.completionPercentage / 100)
            }

            HStack(spacing: 8) {
                Label("\(room.tasks.count)", systemImage: "checkmark.square")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.secondaryText)
                Label("\(room.materials.count)", systemImage: "shippingbox")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.secondaryText)
                if !room.defects.isEmpty {
                    Label("\(room.defects.count)", systemImage: "exclamationmark.triangle")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.warning)
                }
            }
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(AppColors.accentBlue.opacity(0.28), lineWidth: 1))
        .shadow(color: AppColors.accentBlue.opacity(0.08), radius: 8, y: 4)
    }
}

// MARK: - AddRoomCard
struct AddRoomCard: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(AppColors.accent.opacity(0.5),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                    .frame(width: 52, height: 52)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppColors.accent)
            }
            Text("Add Room")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.accent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(AppColors.accent.opacity(0.04))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(AppColors.accent.opacity(0.28),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])))
    }
}

// MARK: - AddRoomView
struct AddRoomView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var name             = ""
    @State private var emoji            = "🏠"
    @State private var area             = ""
    @State private var renovationType  : RenovationType = .cosmetic

    let emojiOptions = ["🏠","🍳","🛋️","🛏️","🚿","🌿","🖥️","📚","👗","🎮","🏋️","🍽️"]

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)

                ScrollView {
                    VStack(spacing: 20) {
                        // Emoji
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Room Icon").padding(.leading, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(emojiOptions, id: \.self) { e in
                                        Text(e)
                                            .font(.system(size: 28))
                                            .padding(10)
                                            .background(emoji == e
                                                ? AppColors.accent.opacity(0.2)
                                                : AppColors.cardBackground)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .stroke(emoji == e ? AppColors.accent : Color.clear, lineWidth: 2))
                                            .onTapGesture { emoji = e }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        FormField(label: "Room Name", placeholder: "e.g. Living Room", text: $name)
                        FormField(label: "Area (m²)",  placeholder: "e.g. 20",         text: $area)

                        // Renovation type
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Renovation Type").padding(.leading, 16)
                            HStack(spacing: 10) {
                                ForEach(RenovationType.allCases, id: \.self) { type in
                                    Button { withAnimation { renovationType = type } } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: type.icon).font(.system(size: 20))
                                            Text(type.rawValue).font(.system(size: 11, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .foregroundColor(renovationType == type ? AppColors.background : .white)
                                        .background(renovationType == type ? AppColors.accent : AppColors.cardBackground)
                                        .cornerRadius(12)
                                    }
                                    .scaleButtonStyle()
                                }
                            }
                            .padding(.horizontal)
                        }

                        YellowButton(title: "Create Room", disabled: name.isEmpty) { save() }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let room = Room(name: name, emoji: emoji,
                        area: Double(area) ?? 0,
                        renovationType: renovationType)
        appVM.addRoom(room)
        dismiss.wrappedValue.dismiss()
    }
}
