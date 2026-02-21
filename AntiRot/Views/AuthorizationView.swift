import SwiftUI
import UIKit

struct AuthorizationView: View {
    @ObservedObject var model: AuthorizationModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            VStack(spacing: 12) {
                Text("Anti-Rot")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Anti-Rot needs Screen Time permission to limit your apps.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button("Get Started") {
                Task { await model.requestAuthorization() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer().frame(height: 20)
        }
        .padding()
    }
}

struct AuthorizationDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "xmark.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)

            Text("Permission Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("Anti-Rot needs Screen Time permission to work.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 4) {
                Text("Settings → Screen Time → Enable Screen Time")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}
