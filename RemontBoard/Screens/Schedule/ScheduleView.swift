import SwiftUI

struct RemontNotificationView: View {
    @ObservedObject var store: Store
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("push_back_main")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer(); titleText
                            .multilineTextAlignment(.center); subtitleText
                            .multilineTextAlignment(.center); actionButtons
                    }.padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) { Spacer(); titleText; subtitleText }
                        Spacer()
                        VStack { Spacer(); actionButtons }
                        Spacer()
                    }.padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white.opacity(0.7))
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { store.dispatch(.permissionRequested) } label: {
                Image("push_btn").resizable().frame(width: 300, height: 65)
            }
            Button { store.dispatch(.permissionDeferred) } label: {
                Text("Skip").font(.headline).foregroundColor(.gray)
            }
        }.padding(.horizontal, 12)
    }
}


struct ScheduleView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var selectedDate   = Date()
    @State private var displayedMonth = Date()
    @State private var showAddEvent   = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)

                VStack(spacing: 0) {
                    CalendarView(selectedDate: $selectedDate,
                                 displayedMonth: $displayedMonth,
                                 events: appVM.scheduleEvents)
                        .padding(.horizontal).padding(.top, 8)

                    Divider().background(AppColors.accentBlue.opacity(0.3)).padding(.vertical, 10)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(selectedDate.formatted(date: .complete, time: .omitted))
                                .font(.system(size: 13, weight: .bold)).foregroundColor(AppColors.accent)
                            Spacer()
                            Button { showAddEvent = true } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22)).foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(.horizontal)

                        let events = appVM.eventsForDate(selectedDate)
                        if events.isEmpty {
                            Text("No events scheduled. Tap + to add.")
                                .font(.system(size: 13)).foregroundColor(AppColors.secondaryText)
                                .padding(.horizontal)
                        } else {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(events) { evt in
                                        ScheduleEventRow(event: evt).environmentObject(appVM)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle("Schedule")
            .preferredColorScheme(.dark)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddEvent) {
            AddScheduleEventView(defaultDate: selectedDate).environmentObject(appVM)
        }
    }
}

// MARK: - CalendarView
struct CalendarView: View {
    @Binding var selectedDate   : Date
    @Binding var displayedMonth : Date
    let events                  : [ScheduleEvent]

    let calendar = Calendar.current
    let columns  = Array(repeating: GridItem(.flexible()), count: 7)
    let weekdays = ["Su","Mo","Tu","We","Th","Fr","Sa"]

    var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year,.month], from: displayedMonth))
        else { return [] }
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: firstDay) { days.append(d) }
        }
        return days
    }

    func hasEvent(on date: Date) -> Bool {
        events.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left").foregroundColor(AppColors.accent)
                }
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                Spacer()
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right").foregroundColor(AppColors.accent)
                }
            }

            HStack {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.secondaryText).frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                        let isToday    = calendar.isDateInToday(day)
                        let hasEvt     = hasEvent(on: day)

                        Button { selectedDate = day } label: {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? AppColors.accent
                                          : isToday ? AppColors.accentBlue.opacity(0.28)
                                          : Color.clear)
                                    .frame(width: 32, height: 32)
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 13, weight: isSelected || isToday ? .bold : .regular))
                                    .foregroundColor(isSelected ? AppColors.background : .white)
                                if hasEvt && !isSelected {
                                    Circle().fill(AppColors.accent).frame(width: 4, height: 4).offset(y: 12)
                                }
                            }
                        }
                        .frame(height: 36)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(14)
        .background(AppColors.cardBackground).cornerRadius(16)
    }

    private func changeMonth(_ val: Int) {
        withAnimation {
            displayedMonth = calendar.date(byAdding: .month, value: val, to: displayedMonth) ?? displayedMonth
        }
    }
}

// MARK: - ScheduleEventRow
struct ScheduleEventRow: View {
    let event: ScheduleEvent
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: event.color)).frame(width: 4, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    .strikethrough(event.isCompleted)
                HStack(spacing: 10) {
                    Label(event.date.formatted(date: .omitted, time: .shortened),
                          systemImage: "clock")
                        .font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
                    if !event.assignee.isEmpty {
                        Label(event.assignee, systemImage: "person.fill")
                            .font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            Spacer()
            Button { toggle() } label: {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(event.isCompleted ? AppColors.success : AppColors.secondaryText)
                    .font(.system(size: 22))
            }
            .scaleButtonStyle()
        }
        .padding(12)
        .background(AppColors.cardBackground).cornerRadius(12)
    }

    private func toggle() {
        var u = event; u.isCompleted.toggle()
        withAnimation { appVM.updateScheduleEvent(u) }
    }
}

// MARK: - AddScheduleEventView
struct AddScheduleEventView: View {
    let defaultDate: Date
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var title         = ""
    @State private var date          : Date
    @State private var assignee      = ""
    @State private var selectedColor = "#F5C842"

    let colors = ["#F5C842","#4A90D9","#5BC8A3","#E87D5A","#A78BFA","#FF6B6B"]

    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        _date = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)
                ScrollView {
                    VStack(spacing: 16) {
                        FormField(label: "Event Title", placeholder: "e.g. Tile installation", text: $title)
                        FormField(label: "Assignee",    placeholder: "Who is responsible?",     text: $assignee)

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel(text: "Date & Time").padding(.leading, 16)
                            DatePicker("", selection: $date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark).accentColor(AppColors.accent)
                                .padding(.horizontal)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Color").padding(.leading, 16)
                            HStack(spacing: 12) {
                                ForEach(colors, id: \.self) { c in
                                    Circle()
                                        .fill(Color(hex: c)).frame(width: 32, height: 32)
                                        .overlay(Circle().stroke(.white, lineWidth: selectedColor == c ? 3 : 0))
                                        .scaleEffect(selectedColor == c ? 1.12 : 1)
                                        .animation(.spring(), value: selectedColor)
                                        .onTapGesture { withAnimation { selectedColor = c } }
                                }
                            }
                            .padding(.horizontal)
                        }

                        YellowButton(title: "Add Event", disabled: title.isEmpty) { save() }
                            .padding(.horizontal).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Event").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let evt = ScheduleEvent(title: title, date: date, assignee: assignee, color: selectedColor)
        appVM.addScheduleEvent(evt)
        dismiss.wrappedValue.dismiss()
    }
}
