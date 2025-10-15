//
//  AppDelegate.swift
//  thammytrangvan
//
//  Created by NgHung on 7/28/18.
//  Copyright © 2018 EZS. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
   
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
       
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        requestNotificationAuthorization()

//        UNUserNotificationCenter.current().delegate = self
//        DispatchQueue.main.asyncAfter(deadline: .now() ) {
//            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
//                        print("Quyền thông báo được cấp: \(granted)")
//                        print("Register")
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                            UIApplication.shared.registerForRemoteNotifications()
//                            UIApplication.shared.applicationIconBadgeNumber = 0
//                        }
//                    }
//        }
       
       
        
//        self.configureNotification()
    
        // "Khó cấu hình nên fixed cứng" - 60(s) * 15
       // UIApplication.shared.setMinimumBackgroundFetchInterval(60 * 15)
        
        return true
    }
    
    func requestNotificationAuthorization() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    print("❌ Error: \(error)")
                }
                print("🔔 Notification permission: \(granted)")
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }

    
    
    func getTaskWithIdentifier() ->  String {
        let bundleID = Bundle.main.bundleIdentifier
        return (bundleID ?? "") +  "-Scheduler"
    }
    
    @available(iOS 13.0, *)
    private func handleTaskScheduler(_ task: BGTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        let lastOperation = queue.operations.last
        lastOperation?.completionBlock = {
            task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
        }
        SERVER_NOTI().runBackgroundFetch()
        scheduleRepeat()
    }
    @available(iOS 13.0, *)
    private func scheduleRepeat() {
        do {
            let request = BGAppRefreshTaskRequest(identifier: getTaskWithIdentifier())
            request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print(error)
        }
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("APNs device token: \(deviceTokenString)")
        Messaging.messaging().apnsToken = deviceToken
        ConnectToFCM()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Nhận được thông báo: \(userInfo)")
        completionHandler(.newData)
    }
  
    
    func ConnectToFCM() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Lỗi lấy FCM token: \(error)")
            } else if let token = token {
                print("✅ FCM Token: \(token)")
                UserDefaults.standard.set(token, forKey: "FirebaseNotiToken")
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
//        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
//        UIApplication.shared.applicationIconBadgeNumber = 0
        ConnectToFCM()
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        ConnectToFCM()
    }
    //Handling the actions in your actionable notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                didReceive response: UNNotificationResponse,
                withCompletionHandler completionHandler:
                   @escaping () -> Void) {
       // Get the meeting ID from the original notification.'
       
        UserDefaults.standard.set(response.notification.request.content.userInfo, forKey: "NotifedData")
        UIApplication.shared.applicationIconBadgeNumber -= 1

        //
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NotificationClick") , object: nil, userInfo: response.notification.request.content.userInfo)
        
        
        // Always call the completion handler when done.
        completionHandler()
        
    }
    //Processing notifications in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        UIApplication.shared.applicationIconBadgeNumber += 1
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ""), object: nil)
        
        UserDefaults.standard.set(notification.request.content.userInfo, forKey: "NotifedData")
        
       
        completionHandler([.alert,.sound])
    }
    
    func configureNotification() {
        if #available(iOS 10.0, *) {
            
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            center.delegate = self
            
            let deafultCategory = UNNotificationCategory(identifier: "App21CustomPush", actions: [], intentIdentifiers: [], options: [])
            center.setNotificationCategories(Set([deafultCategory]))
        } else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
 
 
    //MARK: - background
   
        
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler:
                     @escaping (UIBackgroundFetchResult) -> Void) {
       // Check for new data.
        //SERVER_NOTI().runBackground(config: <#T##SERVER_NOTI_Config#>, callback: <#T##(Error?) -> ()#>)
        
       SERVER_NOTI().runBackgroundFetch()
       completionHandler(.noData)
    }
    
}

