import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // La clave sale de Info.plist (GMSApiKey), que a su vez la toma de la
    // variable MAPS_API_KEY del xcconfig. Asi no viaja en el repositorio.
    if let clave = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !clave.isEmpty {
      GMSServices.provideAPIKey(clave)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// import UIKit
// import Flutter
// import FacebookCore 

// @main
// @objc class AppDelegate: FlutterAppDelegate {

//     override func application(
//         _ application: UIApplication,
//         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {

//         // Registrar plugins de Flutter
//         GeneratedPluginRegistrant.register(with: self)

//         // Inicializar el SDK de Facebook
//         // ApplicationDelegate.shared.application(
//         //     application,
//         //     didFinishLaunchingWithOptions: launchOptions
//         // )

//         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }

//     // Manejar URLs abiertas por Facebook (iOS < 13)
//     override func application(
//         _ app: UIApplication,
//         open url: URL,
//         options: [UIApplication.OpenURLOptionsKey : Any] = [:]
//     ) -> Bool {
//         return ApplicationDelegate.shared.application(
//             app,
//             open: url,
//             sourceApplication: options[.sourceApplication] as? String,
//             annotation: options[.annotation]
//         )
//     }
// }