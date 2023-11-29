//
//  Notification.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/20.
//

import Foundation
import UserNotifications

class NotificationHelper: NSObject {
    
    static let shared = NotificationHelper()

    // time eg: 08:32
    func appendReminder(_ time: String) {
        
        deleteNotifications(time)

        let noticeContent = UNMutableNotificationContent()
        noticeContent.title = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? ""
        noticeContent.body = "The body needs energy, don't forget to drink water!"
        noticeContent.sound = .default
        
        
        // 闹钟的date
        let day = Date().day
        let dateStr = "\(day) \(time)"
        let formatter = DateFormatter()
        formatter.dateFormat  = "yyyy-MM-dd HH:mm"
        let date = formatter.date(from: dateStr) ?? Date()
        
        // 闹钟距离现在的时间
        var timespace = date.timeIntervalSinceNow
        
        // 如果当前时间过了闹钟
        if timespace < 0 {
            timespace = 24 * 3600 + timespace
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timespace, repeats: false)
        
        let request = UNNotificationRequest(identifier: time , content: noticeContent, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                debugPrint("[UN] 通知错误。\(error?.localizedDescription ?? "")")
            }
        }
        
    }
    
    func deleteNotifications(_ time: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [time])
    }
    
    func register(completion: ((Bool)->Void)? = nil) {
        let noti = UNUserNotificationCenter.current()
        noti.requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
            if granted {
                print("开启通知")
                completion?(true)
            } else {
                print("关闭通知")
                completion?(false)
            }
        }
        
        noti.getNotificationSettings { settings in
            print(settings)
        }
        
        noti.delegate = NotificationHelper.shared
    }
}

extension NotificationHelper: UNUserNotificationCenterDelegate {
    
    /// 应用内收到
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner, .list])
        NotificationHelper.shared.appendReminder(notification.request.identifier)
        debugPrint("收到通知")
    }
    
    
    /// 点击应用外弹窗
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        debugPrint("点击通知")
    }
}
