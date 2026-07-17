import UIKit
import AuthenticationServices

// flutter_web_auth_2 (used transitively by twitter_oauth2_pkce for Twitter login) resolves
// its ASWebAuthenticationSession presentation anchor via:
//   UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
// then falls back to the app's plain rootViewController, requiring it to conform to
// ASWebAuthenticationPresentationContextProviding. In this app, the window's rootViewController
// is React Native's own root controller, not a FlutterViewController — since only
// FlutterViewController conforms (inside flutter_web_auth_2 itself), that fallback cast fails
// and the plugin rejects with acquireRootViewControllerFailed, silently doing nothing.
//
// Conforming UIViewController itself closes that gap for every other controller (RN's root VC
// included). FlutterViewController's own extension is more specific and still wins via normal
// dynamic dispatch, so this doesn't change Flutter's own presentation.
@available(iOS 13.0, *)
extension UIViewController: ASWebAuthenticationPresentationContextProviding {
  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
      .first ?? ASPresentationAnchor()
  }
}
