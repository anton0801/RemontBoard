import SwiftUI


struct UnavailableView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("error_internet_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                Image("error_internet")
                    .resizable()
                    .frame(width: 200, height: 180)
            }
        }
        .ignoresSafeArea()
    }
}


// MARK: - SearchResult
enum SearchResult: Identifiable {
    case room    (Room)
    case task    (RenovationTask, room: Room)
    case material(Material,        room: Room)
    case defect  (Defect,          room: Room)

    var id: String {
        switch self {
        case .room(let r):        return "room_\(r.id)"
        case .task(let t, _):    return "task_\(t.id)"
        case .material(let m, _): return "mat_\(m.id)"
        case .defect(let d, _):  return "def_\(d.id)"
        }
    }

    var title: String {
        switch self {
        case .room(let r):        return "\(r.emoji) \(r.name)"
        case .task(let t, _):    return t.title
        case .material(let m, _): return m.name
        case .defect(let d, _):  return d.type.rawValue
        }
    }

    var subtitle: String {
        switch self {
        case .room(let r):        return "\(r.renovationType.rawValue) · \(Int(r.area)) m²"
        case .task(let t, let r): return "\(r.emoji) \(r.name) · \(t.status.rawValue)"
        case .material(let m, let r): return "\(r.emoji) \(r.name) · \(m.category.rawValue)"
        case .defect(let d, let r): return "\(r.emoji) \(r.name) · \(d.isResolved ? "Fixed" : "Open")"
        }
    }

    var icon: String {
        switch self {
        case .room:     return "building.2.fill"
        case .task:     return "checkmark.square.fill"
        case .material: return "shippingbox.fill"
        case .defect:   return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .room:     return AppColors.accentBlue
        case .task:     return AppColors.success
        case .material: return AppColors.accent
        case .defect:   return AppColors.warning
        }
    }

    var typeLabel: String {
        switch self {
        case .room:     return "ROOM"
        case .task:     return "TASK"
        case .material: return "MATERIAL"
        case .defect:   return "DEFECT"
        }
    }
}

// MARK: - GlobalSearchView
struct GlobalSearchView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var query       = ""
    @State private var filter      : SearchFilter = .all
    @FocusState private var focused: Bool

    enum SearchFilter: String, CaseIterable {
        case all       = "All"
        case rooms     = "Rooms"
        case tasks     = "Tasks"
        case materials = "Materials"
        case defects   = "Defects"
    }

    var results: [SearchResult] {
        guard query.count >= 1 else { return [] }
        let q = query.lowercased()
        var all: [SearchResult] = []

        for room in appVM.rooms {
            if room.name.lowercased().contains(q)         { all.append(.room(room)) }
            for t in room.tasks    where filter == .all || filter == .tasks {
                if t.title.lowercased().contains(q) || t.assignee.lowercased().contains(q) {
                    all.append(.task(t, room: room))
                }
            }
            for m in room.materials where filter == .all || filter == .materials {
                if m.name.lowercased().contains(q) || m.category.rawValue.lowercased().contains(q) {
                    all.append(.material(m, room: room))
                }
            }
            for d in room.defects  where filter == .all || filter == .defects {
                if d.type.rawValue.lowercased().contains(q) || d.description.lowercased().contains(q) {
                    all.append(.defect(d, room: room))
                }
            }
        }

        switch filter {
        case .all:       return all
        case .rooms:     return all.filter { if case .room   = $0 { return true }; return false }
        case .tasks:     return all.filter { if case .task   = $0 { return true }; return false }
        case .materials: return all.filter { if case .material = $0 { return true }; return false }
        case .defects:   return all.filter { if case .defect = $0 { return true }; return false }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.15)

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(query.isEmpty ? AppColors.secondaryText : AppColors.accent)
                        TextField("Search rooms, tasks, materials…", text: $query)
                            .foregroundColor(.white)
                            .focused($focused)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        if !query.isEmpty {
                            Button { withAnimation { query = "" } } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(AppColors.cardBackground)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(query.isEmpty ? AppColors.accentBlue.opacity(0.25) : AppColors.accent.opacity(0.5), lineWidth: 1))
                    .padding(.horizontal).padding(.top, 8)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SearchFilter.allCases, id: \.self) { f in
                                Button { withAnimation(.spring()) { filter = f } } label: {
                                    Text(f.rawValue)
                                        .font(.system(size: 12, weight: filter == f ? .bold : .regular))
                                        .foregroundColor(filter == f ? AppColors.background : .white.opacity(0.6))
                                        .padding(.horizontal, 14).padding(.vertical, 7)
                                        .background(filter == f ? AppColors.accent : AppColors.cardBackground)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 10)
                    }

                    // Results
                    if query.isEmpty {
                        SearchEmptyPrompt()
                    } else if results.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "magnifyingglass").font(.system(size: 36))
                                .foregroundColor(AppColors.secondaryText)
                            Text("No results for \"\(query)\"")
                                .font(.system(size: 15)).foregroundColor(AppColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppColors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                ForEach(results) { result in
                                    SearchResultRow(result: result)
                                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal).padding(.bottom, 40)
                            .animation(.spring(response: 0.4), value: results.count)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
                }
            }
            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true } }
        }
        .preferredColorScheme(.dark)
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(result.color.opacity(0.14)).frame(width: 38, height: 38)
                Image(systemName: result.icon).font(.system(size: 15)).foregroundColor(result.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(result.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(result.subtitle).font(.system(size: 11)).foregroundColor(AppColors.secondaryText).lineLimit(1)
            }
            Spacer()
            Text(result.typeLabel)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(result.color)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(result.color.opacity(0.12))
                .cornerRadius(4)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(result.color.opacity(0.18), lineWidth: 1))
    }
}

struct SearchEmptyPrompt: View {
    let hints = [
        ("building.2.fill",  AppColors.accentBlue, "Search rooms by name"),
        ("checkmark.square", AppColors.success,     "Find tasks & assignees"),
        ("shippingbox",      AppColors.accent,       "Look up materials"),
        ("exclamationmark.triangle", AppColors.warning, "Search defects"),
    ]
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 48)).foregroundColor(AppColors.accentBlue.opacity(0.4))
            Text("Search everything")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            VStack(spacing: 10) {
                ForEach(hints, id: \.0) { icon, color, label in
                    HStack(spacing: 10) {
                        Image(systemName: icon).font(.system(size: 14)).foregroundColor(color).frame(width: 20)
                        Text(label).font(.system(size: 13)).foregroundColor(AppColors.secondaryText)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 48)
            Spacer()
        }
    }
}
