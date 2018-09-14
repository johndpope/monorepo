import Reachability
import UIKit

typealias LaunchOptions = [UIApplicationLaunchOptionsKey: Any]?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var navController: UINavigationController?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: LaunchOptions) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    showIntro()
    window!.makeKeyAndVisible()

    return true
  }
  
  func showIntro() {
    let introController = IntroViewController()
    window!.rootViewController = introController
  }
  
  func showPermissions() {
    let permissionsController = PermissionsViewController()
    window!.rootViewController = permissionsController
  }
  
  func showNotifications() {
    let notificationsController = NotificationViewController()
    window!.rootViewController = notificationsController
  }
  
  func showHomeScreen() {
    let mapController = MapViewController()
    window!.rootViewController = mapController
  }


}
