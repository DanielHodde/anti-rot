import ManagedSettings

// When the user taps "Open Anti-Rot" on the shield, this handler is called.
// Closing the shield lets the user navigate to Anti-Rot where they can use
// their once-per-day override if it hasn't been used today.

class ShieldActionHandlerExtension: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: Application,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomain,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategory,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }
}
