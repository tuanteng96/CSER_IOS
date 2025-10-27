//
//  AppDelegate.swift
//  thammytrangvan
//
//  Created by NgHung on 7/28/18.
//  Copyright © 2018 EZS. All rights reserved.
//

//import UIKit
//import FirebaseCore
//import FirebaseMessaging
//import UserNotifications
//import BackgroundTasks
//
//@UIApplicationMain
//class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
//    
//    var window: UIWindow?
//    
//   
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        
//        // Override point for customization after application launch.
//       
//        FirebaseApp.configure()
//        Messaging.messaging().delegate = self
//        UNUserNotificationCenter.current().delegate = self
//
//        requestNotificationAuthorization()
//
////        UNUserNotificationCenter.current().delegate = self
////        DispatchQueue.main.asyncAfter(deadline: .now() ) {
////            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
////                        print("Quyền thông báo được cấp: \(granted)")
////                        print("Register")
////                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
////                            UIApplication.shared.registerForRemoteNotifications()
////                            UIApplication.shared.applicationIconBadgeNumber = 0
////                        }
////                    }
////        }
//       
//       
//        
////        self.configureNotification()
//    
//        // "Khó cấu hình nên fixed cứng" - 60(s) * 15
//       // UIApplication.shared.setMinimumBackgroundFetchInterval(60 * 15)
//        
//        return true
//    }
//    
//    func requestNotificationAuthorization() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//                print("🔔 Notification permission: \(granted)")
//                if granted {
//                    DispatchQueue.main.async {
//                        UIApplication.shared.registerForRemoteNotifications()
//                    }
//                } else {
//                    print("⚠️ Người dùng từ chối quyền thông báo.")
//                }
//            }
//        }
//
//    
//    
//    func getTaskWithIdentifier() ->  String {
//        let bundleID = Bundle.main.bundleIdentifier
//        return (bundleID ?? "") +  "-Scheduler"
//    }
//    
//    @available(iOS 13.0, *)
//    private func handleTaskScheduler(_ task: BGTask) {
//        let queue = OperationQueue()
//        queue.maxConcurrentOperationCount = 1
//        
//        task.expirationHandler = {
//            queue.cancelAllOperations()
//        }
//
//        let lastOperation = queue.operations.last
//        lastOperation?.completionBlock = {
//            task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
//        }
//        SERVER_NOTI().runBackgroundFetch()
//        scheduleRepeat()
//    }
//    @available(iOS 13.0, *)
//    private func scheduleRepeat() {
//        do {
//            let request = BGAppRefreshTaskRequest(identifier: getTaskWithIdentifier())
//            request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
//            try BGTaskScheduler.shared.submit(request)
//        } catch {
//            print(error)
//        }
//    }
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
//        print("📱 APNs Device Token: \(deviceTokenString)")
//
//        // Gán APNs token cho Firebase
//        Messaging.messaging().apnsToken = deviceToken
//
//        // ✅ Lúc này mới được lấy FCM token
//        Messaging.messaging().token { token, error in
//            if let error = error {
//                print("❌ Lỗi lấy FCM token: \(error.localizedDescription)")
//            } else if let token = token {
//                print("✅ FCM Token: \(token)")
//                UserDefaults.standard.set(token, forKey: "FirebaseNotiToken")
//            }
//        }
//    }
//
//    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        print("Nhận được thông báo: \(userInfo)")
//        completionHandler(.newData)
//    }
//  
//    
//    func ConnectToFCM() {
//        Messaging.messaging().token { token, error in
//            if let error = error {
//                print("❌ Lỗi lấy FCM token: \(error.localizedDescription)")
//            } else if let token = token {
//                print("✅ FCM Token: \(token)")
//                UserDefaults.standard.set(token, forKey: "FirebaseNotiToken")
//            }
//        }
//    }
//    
//    func applicationWillResignActive(_ application: UIApplication) {
//    }
//    
//    func applicationDidEnterBackground(_ application: UIApplication) {
//    }
//    
//    func applicationWillEnterForeground(_ application: UIApplication) {
////        UIApplication.shared.applicationIconBadgeNumber = 0
//    }
//    
//    func applicationDidBecomeActive(_ application: UIApplication) {
////        UIApplication.shared.applicationIconBadgeNumber = 0
//        ConnectToFCM()
//        
//    }
//    
//    func applicationWillTerminate(_ application: UIApplication) {
//    }
//    
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        //ConnectToFCM()
//        
//        guard let fcmToken = fcmToken else {
//            print("⚠️ FCM token is nil")
//            return
//        }
//        print("🔁 Firebase refreshed token: \(fcmToken)")
//        UserDefaults.standard.set(fcmToken, forKey: "FirebaseNotiToken")
//
//    }
//    //Handling the actions in your actionable notifications
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                didReceive response: UNNotificationResponse,
//                withCompletionHandler completionHandler:
//                   @escaping () -> Void) {
//       // Get the meeting ID from the original notification.'
//       
//        UserDefaults.standard.set(response.notification.request.content.userInfo, forKey: "NotifedData")
//        UIApplication.shared.applicationIconBadgeNumber -= 1
//
//        //
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NotificationClick") , object: nil, userInfo: response.notification.request.content.userInfo)
//        
//        
//        // Always call the completion handler when done.
//        completionHandler()
//        
//    }
//    //Processing notifications in the foreground
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        
//        UIApplication.shared.applicationIconBadgeNumber += 1
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ""), object: nil)
//        
//        UserDefaults.standard.set(notification.request.content.userInfo, forKey: "NotifedData")
//        
//       
//        completionHandler([.alert,.sound])
//    }
//    
//    func configureNotification() {
//        if #available(iOS 10.0, *) {
//            
//            let center = UNUserNotificationCenter.current()
//            center.requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
//            center.delegate = self
//            
//            let deafultCategory = UNNotificationCategory(identifier: "App21CustomPush", actions: [], intentIdentifiers: [], options: [])
//            center.setNotificationCategories(Set([deafultCategory]))
//        } else {
//            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
//        }
//        UIApplication.shared.registerForRemoteNotifications()
//    }
// 
// 
//    //MARK: - background
//   
//        
//    func application(_ application: UIApplication,
//                     performFetchWithCompletionHandler completionHandler:
//                     @escaping (UIBackgroundFetchResult) -> Void) {
//       // Check for new data.
//        //SERVER_NOTI().runBackground(config: T##SERVER_NOTI_Config, callback: <#T##(Error?) -> ()#>)
//
//       SERVER_NOTI().runBackgroundFetch()
//       completionHandler(.noData)
//    }
//    
//}


import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    // MARK: - didFinishLaunching
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 1️⃣ Cấu hình Firebase
        FirebaseApp.configure()

        // 2️⃣ Thiết lập delegate
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // 3️⃣ Xin quyền thông báo
        requestNotificationAuthorization()
        registerNotificationCategory()

        // 4️⃣ Cấu hình background task
        setupBackgroundTask()

        return true
    }

    // MARK: - Notification Permission
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Lỗi xin quyền thông báo: \(error.localizedDescription)")
            } else {
                print("🔔 Quyền thông báo: \(granted)")
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }

    func registerNotificationCategory() {
        let category = UNNotificationCategory(
            identifier: "App21CustomPush",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Background Tasks
    func setupBackgroundTask() {
        if #available(iOS 13.0, *) {
            do {
                try BGTaskScheduler.shared.register(
                    forTaskWithIdentifier: getTaskWithIdentifier(),
                    using: nil
                ) { task in
                    self.handleTaskScheduler(task)
                }
            } catch {
                print("⚠️ Lỗi đăng ký background task: \(error)")
            }
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(900)
        }
    }

    func getTaskWithIdentifier() -> String {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.app"
        return bundleID + "-Scheduler"
    }

    @available(iOS 13.0, *)
    private func handleTaskScheduler(_ task: BGTask) {
        SERVER_NOTI().runBackgroundFetch()
        scheduleRepeat()
        task.setTaskCompleted(success: true)
    }

    @available(iOS 13.0, *)
    private func scheduleRepeat() {
        let request = BGAppRefreshTaskRequest(identifier: getTaskWithIdentifier())
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("⚠️ Lỗi submit background task: \(error)")
        }
    }

    // MARK: - Firebase Messaging + APNs
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 APNs Device Token: \(deviceTokenString)")

        // Gán APNs token cho Firebase
        Messaging.messaging().apnsToken = deviceToken

        // Gọi sau khi APNs token đã set
        ConnectToFCM()
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Lỗi đăng ký APNs: \(error.localizedDescription)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("⚠️ FCM token is nil")
            return
        }
        print("🔁 Firebase refreshed token: \(fcmToken)")
        UserDefaults.standard.set(fcmToken, forKey: "FirebaseNotiToken")
    }

    // MARK: - Nhận thông báo
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📩 Nhận được thông báo: \(userInfo)")
        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        UIApplication.shared.applicationIconBadgeNumber += 1
        UserDefaults.standard.set(notification.request.content.userInfo, forKey: "NotifedData")
        NotificationCenter.default.post(name: NSNotification.Name("NotificationReceived"),
                                        object: nil,
                                        userInfo: notification.request.content.userInfo)
        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        UserDefaults.standard.set(response.notification.request.content.userInfo, forKey: "NotifedData")
        UIApplication.shared.applicationIconBadgeNumber = max(UIApplication.shared.applicationIconBadgeNumber - 1, 0)
        NotificationCenter.default.post(name: NSNotification.Name("NotificationClick"),
                                        object: nil,
                                        userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }

    // MARK: - Kết nối FCM sau khi có APNs
    func ConnectToFCM() {
        guard let _ = Messaging.messaging().apnsToken else {
            print("⚠️ APNs token chưa sẵn sàng, hoãn lấy FCM token.")
            return
        }

        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Lỗi lấy FCM token: \(error.localizedDescription)")
            } else if let token = token {
                print("✅ FCM Token hợp lệ (đã liên kết APNs): \(token)")
                UserDefaults.standard.set(token, forKey: "FirebaseNotiToken")
            }
        }
    }

    // MARK: - Background Fetch (pre-iOS13)
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler:
                     @escaping (UIBackgroundFetchResult) -> Void) {
        SERVER_NOTI().runBackgroundFetch()
        completionHandler(.newData)
    }
}
