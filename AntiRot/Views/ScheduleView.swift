import SwiftUI

struct ScheduleView: View {
    @State private var windows: [TimeWindow] = []
    @State private var isAddingWindow = false

    var body: some View {
        NavigationStack {
            Group {
                if windows.isEmpty {
                    emptyState
                } else {
                    windowList
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        isAddingWindow = true
                    }
                }
            }
            .sheet(isPresented: $isAddingWindow) {
                AddWindowView { newWindow in
                    windows.append(newWindow)
                    saveAndApply()
                }
            }
            .onAppear {
                windows = SharedStorage.loadWindows()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Allowed Windows")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Add time windows when your apps are allowed. They are blocked at all other times.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Window") {
                isAddingWindow = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var windowList: some View {
        List {
            ForEach(windows) { window in
                VStack(alignment: .leading, spacing: 4) {
                    Text(window.label)
                        .fontWeight(.medium)
                    Text("\(window.startTimeString) – \(window.endTimeString)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                windows.remove(atOffsets: indexSet)
                saveAndApply()
            }
        }
    }

    private func saveAndApply() {
        SharedStorage.saveWindows(windows)
        ScreenTimeService.shared.applySchedules()
    }
}

struct AddWindowView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (TimeWindow) -> Void

    @State private var label = ""
    @State private var startDate = Calendar.current.date(
        bySettingHour: 12, minute: 0, second: 0, of: .now
    )!
    @State private var endDate = Calendar.current.date(
        bySettingHour: 13, minute: 0, second: 0, of: .now
    )!

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    TextField("e.g. Lunch, Dinner", text: $label)
                }
                Section("Time") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Add Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWindow() }
                        .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveWindow() {
        let cal = Calendar.current
        let startComps = cal.dateComponents([.hour, .minute], from: startDate)
        let endComps = cal.dateComponents([.hour, .minute], from: endDate)
        let window = TimeWindow(
            label: label.trimmingCharacters(in: .whitespaces),
            startHour: startComps.hour ?? 0,
            startMinute: startComps.minute ?? 0,
            endHour: endComps.hour ?? 0,
            endMinute: endComps.minute ?? 0
        )
        onSave(window)
        dismiss()
    }
}
