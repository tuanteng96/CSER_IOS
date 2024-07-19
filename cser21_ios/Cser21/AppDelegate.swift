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
import FirebaseInstanceID
import UserNotifications
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
   
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.configureNotification()
        setupPushNotificationsHandling(application)
       
        
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (isGranted, err) in
//            if err != nil {
//               // Something bad happend
//            } else {
//                UNUserNotificationCenter.current().delegate = self
//                Messaging.messaging().delegate = self
//                
//                DispatchQueue.main.async {
//                    UIApplication.shared.registerForRemoteNotifications()
//                }
//            }
//        }
//        
//        FirebaseApp.configure()
        
        // "Khó cấu hình nên fixed cứng" - 60(s) * 15
        UIApplication.shared.setMinimumBackgroundFetchInterval(60 * 15)
        
//        if #available(iOS 13.0, *) {
//            BGTaskScheduler.shared.register(
//                forTaskWithIdentifier: getTaskWithIdentifier(),
//                using: DispatchQueue.global()
//            ) { task in
//                self.handleTaskScheduler(task)
//            }
//        } else {
//            // Fallback on earlier versions
//        }
        //UINavigationBar.appearance().barStyle = .blackOpaque
        
        
        return true
    }
    
    private func setupPushNotificationsHandling(_ application: UIApplication) {
        FirebaseApp.configure()

        application.registerForRemoteNotifications()

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (isGranted, err) in
            if err != nil {
               // Something bad happend
            } else {
                UNUserNotificationCenter.current().delegate = self
                Messaging.messaging().delegate = self
                
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
        subscribeToNotificationsTopic(topic: "all")
    }
    func subscribeToNotificationsTopic(topic: String) {
        // Retry until the notifications subscription is successful
        DispatchQueue.global().async {
            var subscribed = false
            while !subscribed {
                let semaphore = DispatchSemaphore(value: 0)
                
                InstanceID.instanceID().instanceID { (result, error) in
                    if let result = result {
                        // Device token can be used to send notifications exclusively to this device
                        print("Device token \(result.token)")
                        
                        // Subscribe
                        Messaging.messaging().subscribe(toTopic: topic)
                        
                        // Notify semaphore
                        subscribed = true
                        semaphore.signal()
                    }
                }
                
                // Set a 3 seconds timeout
                let dispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(3)
                _ = semaphore.wait(timeout: dispatchTime)
            }
        }
    }
    
    func ConnectToFCM() {
        Messaging.messaging().shouldEstablishDirectChannel = true
        
        InstanceID.instanceID().instanceID { (result, error) in
        if let error = error {
        print("Error fetching remote instange ID: \(error)")
        } else if let result = result {
            print("Remote instance ID token: \(result.token)")
            //hung 19/03/2022
            let defaults = UserDefaults.standard
            defaults.set(result.token, forKey: "FirebaseNotiToken")
         }
        }
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = false
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

