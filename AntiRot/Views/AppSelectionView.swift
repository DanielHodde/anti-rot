import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("\(selection.applicationTokens.count) apps selected")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("These apps will be blocked outside your allowed schedule.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button("Choose Apps to Block") {
                    isPickerPresented = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }
            .navigationTitle("Apps")
            .navigationBarTitleDisplayMode(.large)
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .onChange(of: selection) { _, newValue in
                SharedStorage.saveSelection(newValue)
                ScreenTimeService.shared.reapplyShieldsIfCurrentlyBlocked()
            }
            .onAppear {
                if let saved = SharedStorage.loadSelection() {
                    selection = saved
                }
            }
        }
    }
}
