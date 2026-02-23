import SwiftUI

// MARK: - TasksTab
struct TasksTab: View {
    let room     : Room
    @Binding var showAdd: Bool
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                Button { showAdd = true } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Task").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(AppColors.accent).cornerRadius(12)
                }
                .scaleButtonStyle()

                if room.tasks.isEmpty {
                    EmptyStateView(icon: "checkmark.square",
                                   message: "No tasks yet.\nTap + to add your first task.")
                } else {
                    ForEach([TaskStatus.inProgress, .todo, .done], id: \.self) { status in
                        let filtered = room.tasks.filter { $0.status == status }
                        if !filtered.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: status.icon).foregroundColor(status.color)
                                    Text(status.rawValue)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(status.color)
                                }
                                ForEach(filtered) { task in
                                    TaskCard(task: task, roomId: room.id)
                                        .environmentObject(appVM)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
}

// MARK: - TaskCard
struct TaskCard: View {
    let task  : RenovationTask
    let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @State private var showEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button { toggleStatus() } label: {
                    Image(systemName: task.status.icon)
                        .font(.system(size: 20))
                        .foregroundColor(task.status.color)
                }
                .scaleButtonStyle()

                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .strikethrough(task.status == .done)
                Spacer()
                if task.laborCost > 0 {
                    Text("$\(Int(task.laborCost))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.success)
                }
            }

            if !task.comment.isEmpty {
                Text(task.comment)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                if let deadline = task.deadline {
                    Label(deadline.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(deadline < Date() && task.status != .done
                            ? AppColors.warning : AppColors.secondaryText)
                }
                if !task.assignee.isEmpty {
                    Label(task.assignee, systemImage: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.secondaryText)
                }
                Spacer()
                Button("Edit") { showEdit = true }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.accentBlue)
            }
        }
        .padding(12)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(task.status.color.opacity(0.2), lineWidth: 1))
        .sheet(isPresented: $showEdit) {
            EditTaskView(task: task, roomId: roomId).environmentObject(appVM)
        }
    }

    private func toggleStatus() {
        var updated = task
        switch task.status {
        case .todo:       updated.status = .inProgress
        case .inProgress: updated.status = .done
        case .done:       updated.status = .todo
        }
        withAnimation(.spring()) { appVM.updateTask(updated, in: roomId) }
    }
}

// MARK: - AddTaskView
struct AddTaskView: View {
    let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var title      = ""
    @State private var comment    = ""
    @State private var assignee   = ""
    @State private var laborCost  = ""
    @State private var hasDeadline = false
    @State private var deadline   = Date()
    @State private var status     : TaskStatus = .todo

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)
                ScrollView {
                    VStack(spacing: 16) {
                        FormField(label: "Task Title",     placeholder: "e.g. Install laminate floor", text: $title)
                        FormField(label: "Comment",        placeholder: "Notes...",                     text: $comment)
                        FormField(label: "Assignee",       placeholder: "e.g. John",                   text: $assignee)
                        FormField(label: "Labor Cost ($)", placeholder: "0",                            text: $laborCost)

                        // Status
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Status").padding(.leading, 16)
                            HStack(spacing: 8) {
                                ForEach([TaskStatus.todo, .inProgress, .done], id: \.self) { s in
                                    Button { status = s } label: {
                                        Text(s.rawValue)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(status == s ? AppColors.background : s.color)
                                            .padding(.horizontal, 10).padding(.vertical, 7)
                                            .background(status == s ? s.color : s.color.opacity(0.15))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Deadline
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionLabel(text: "Deadline").padding(.leading, 16)
                                Spacer()
                                Toggle("", isOn: $hasDeadline).tint(AppColors.accent).padding(.trailing, 16)
                            }
                            if hasDeadline {
                                DatePicker("", selection: $deadline, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .colorScheme(.dark)
                                    .accentColor(AppColors.accent)
                                    .padding(.horizontal)
                            }
                        }

                        YellowButton(title: "Add Task", disabled: title.isEmpty) { save() }
                            .padding(.horizontal).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Task").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let task = RenovationTask(title: title, status: status,
                                   deadline: hasDeadline ? deadline : nil,
                                   laborCost: Double(laborCost) ?? 0,
                                   comment: comment, assignee: assignee)
        appVM.addTask(task, to: roomId)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - EditTaskView
struct EditTaskView: View {
    let task  : RenovationTask
    let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var title      : String
    @State private var comment    : String
    @State private var assignee   : String
    @State private var laborCost  : String
    @State private var hasDeadline: Bool
    @State private var deadline   : Date
    @State private var status     : TaskStatus

    init(task: RenovationTask, roomId: UUID) {
        self.task = task; self.roomId = roomId
        _title      = State(initialValue: task.title)
        _comment    = State(initialValue: task.comment)
        _assignee   = State(initialValue: task.assignee)
        _laborCost  = State(initialValue: task.laborCost > 0 ? "\(Int(task.laborCost))" : "")
        _hasDeadline = State(initialValue: task.deadline != nil)
        _deadline   = State(initialValue: task.deadline ?? Date())
        _status     = State(initialValue: task.status)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)
                ScrollView {
                    VStack(spacing: 16) {
                        FormField(label: "Title",          placeholder: "Task title", text: $title)
                        FormField(label: "Comment",        placeholder: "Notes",      text: $comment)
                        FormField(label: "Assignee",       placeholder: "Name",       text: $assignee)
                        FormField(label: "Labor Cost ($)", placeholder: "0",          text: $laborCost)

                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Status").padding(.leading, 16)
                            HStack(spacing: 8) {
                                ForEach([TaskStatus.todo, .inProgress, .done], id: \.self) { s in
                                    Button { status = s } label: {
                                        Text(s.rawValue)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(status == s ? AppColors.background : s.color)
                                            .padding(.horizontal, 10).padding(.vertical, 7)
                                            .background(status == s ? s.color : s.color.opacity(0.15))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionLabel(text: "Deadline").padding(.leading, 16)
                                Spacer()
                                Toggle("", isOn: $hasDeadline).tint(AppColors.accent).padding(.trailing, 16)
                            }
                            if hasDeadline {
                                DatePicker("", selection: $deadline, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .colorScheme(.dark)
                                    .accentColor(AppColors.accent)
                                    .padding(.horizontal)
                            }
                        }

                        HStack(spacing: 12) {
                            YellowButton(title: "Save Changes", disabled: title.isEmpty) { save() }
                            Button { delete() } label: {
                                Image(systemName: "trash").foregroundColor(AppColors.warning)
                                    .padding(16)
                                    .background(AppColors.warning.opacity(0.14))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Task").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        var u = task
        u.title = title; u.comment = comment; u.assignee = assignee
        u.laborCost = Double(laborCost) ?? 0
        u.deadline = hasDeadline ? deadline : nil
        u.status = status
        appVM.updateTask(u, in: roomId)
        dismiss.wrappedValue.dismiss()
    }
    private func delete() {
        appVM.deleteTask(task, from: roomId)
        dismiss.wrappedValue.dismiss()
    }
}
