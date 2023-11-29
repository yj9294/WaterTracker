//
//  WaterTrackerApp.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/15.
//

import SwiftUI
import FBSDKCoreKit
import GoogleMobileAds
import ComposableArchitecture
import AppTrackingTransparency

@main
struct WaterTrackerApp: App {
    
    @UIApplicationDelegateAdaptor(Appdelegate.self) var appdelegate
    
    var body: some Scene {
        WindowGroup {
            WaterTrackerView(store: Store.init(initialState: WaterTracker.State(), reducer: {
                WaterTracker()
            }))
        }
    }
    
    class Appdelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            NotificationHelper.shared.register()
            GADUtil.share.requestConfig()
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "8dcd760fb10a755bc2d2e470c07a9e34"]
            if let array = UserDefaults.standard.getObject([String].self, forKey: "reminder.list") {
                array.forEach { item in
                    NotificationHelper.shared.appendReminder(item)
                }
            } else {
                let array = ["08:00", "10:00", "12:00", "14:00", "16:00", "18:00"]
                array.forEach {
                    NotificationHelper.shared.appendReminder($0)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: .`init`, object: nil)
            }
            
            ApplicationDelegate.shared.application(
                        application,
                        didFinishLaunchingWithOptions: launchOptions
                    )
            return true
        }
        
        func applicationWillEnterForeground(_ application: UIApplication) {
            ATTrackingManager.requestTrackingAuthorization { _ in
            }
        }
        
        func application(
                _ app: UIApplication,
                open url: URL,
                options: [UIApplication.OpenURLOptionsKey : Any] = [:]
            ) -> Bool {
                ApplicationDelegate.shared.application(
                    app,
                    open: url,
                    sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                    annotation: options[UIApplication.OpenURLOptionsKey.annotation]
                )
            }
    }
}

extension Notification.Name {
    static let `init` = Notification.Name.init(".init")
}
