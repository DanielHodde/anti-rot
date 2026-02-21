import SwiftUI
import FamilyControls

@main
struct AntiRotApp: App {
    @StateObject private var authModel = AuthorizationModel()

    var body: some Scene {
        WindowGroup {
            Group {
                switch authModel.status {
                case .notDetermined:
                    AuthorizationView(model: authModel)
                case .approved:
                    ContentView()
                case .denied:
                    AuthorizationDeniedView()
                @unknown default:
                    AuthorizationView(model: authModel)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

@MainActor
class AuthorizationModel: ObservableObject {
    @Published var status: AuthorizationStatus = .notDetermined

    init() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            status = AuthorizationCenter.shared.authorizationStatus
        } catch {
            status = .denied
        }
    }
}
