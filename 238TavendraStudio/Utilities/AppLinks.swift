import UIKit

enum AppLink: String {
    case privacyPolicy = "https://tavendra238studio.site/privacy/313"
    case termsOfService = "https://tavendra238studio.site/terms/313"

    var url: URL? {
        URL(string: rawValue)
    }

    func open() {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}
