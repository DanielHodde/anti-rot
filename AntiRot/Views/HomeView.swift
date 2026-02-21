import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusSection
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)

                Divider()

                overrideSection
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Anti-Rot")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.refresh() }
            .onReceive(viewModel.timer) { _ in viewModel.refresh() }
        }
    }

    private var statusSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(viewModel.isBlocked ? Color.red : Color.green)
                .frame(width: 90, height: 90)
                .overlay {
                    Image(systemName: viewModel.isBlocked ? "lock.fill" : "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(
                    color: (viewModel.isBlocked ? Color.red : Color.green).opacity(0.4),
                    radius: 24
                )

            Text(viewModel.isBlocked ? "Apps Blocked" : "Apps Allowed")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.statusSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var overrideSection: some View {
        VStack(spacing: 12) {
            Text("Daily Override")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button {
                viewModel.activateOverride()
            } label: {
                Label("I'm Eating", systemImage: "fork.knife")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canOverride)

            Text(viewModel.overrideFootnote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isBlocked = false
    @Published var statusSubtitle = ""
    @Published var canOverride = false
    @Published var overrideFootnote = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func refresh() {
        let windows = SharedStorage.loadWindows()
        let overrideState = SharedStorage.loadOverrideState()
        let service = ScreenTimeService.shared

        let blocked = service.isCurrentlyBlocked(windows: windows)
        let overrideActive = overrideState.isOverrideCurrentlyActive

        // Status badge
        if overrideActive {
            isBlocked = false
            let remaining = Int(overrideState.remainingSeconds)
            statusSubtitle = "Override active — \(remaining / 60)m \(remaining % 60)s remaining"
        } else if windows.isEmpty {
            isBlocked = true
            statusSubtitle = "No schedule set. Add allowed windows in the Schedule tab."
        } else {
            isBlocked = blocked
            statusSubtitle = blocked ? "Outside your allowed windows" : "Within an allowed window"
        }

        // Override button
        if overrideActive {
            canOverride = false
            let remaining = Int(overrideState.remainingSeconds)
            overrideFootnote = "\(remaining / 60)m \(remaining % 60)s remaining"
        } else if overrideState.isActiveToday {
            canOverride = false
            overrideFootnote = "Already used today. Resets at midnight."
        } else {
            canOverride = true
            overrideFootnote = "Grants 45 minutes of access. Once per day."
        }
    }

    func activateOverride() {
        ScreenTimeService.shared.activateOverride()
        refresh()
    }
}
