import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            AppSelectionView()
                .tabItem { Label("Apps", systemImage: "square.grid.2x2.fill") }

            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "clock.fill") }
        }
        .tint(.white)
    }
}
