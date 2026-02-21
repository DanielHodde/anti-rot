import ManagedSettings
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application)
        -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration()
    }

    // MARK: - Private

    private func makeConfiguration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundEffect: UIBlurEffect(style: .systemUltraThinMaterialDark),
            title: ShieldConfiguration.Label(
                text: "Anti-Rot",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked right now.",
                color: UIColor(white: 1, alpha: 0.7)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Anti-Rot",
                color: .black
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }
}
