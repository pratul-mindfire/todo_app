import Foundation
import UserNotifications

// MARK: - Notification Service

final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    // MARK: Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Schedule

    /// Schedules a local notification at the task's due date.
    /// Does nothing if the task has no due date, is already completed, or the date is in the past.
    func scheduleNotification(for task: Task) {
        guard
            let dueDate = task.dueDate,
            !task.isCompleted,
            dueDate > Date()
        else { return }

        let content       = UNMutableNotificationContent()
        content.title     = "📋 Task Reminder"
        content.body      = task.title
        content.sound     = .default
        content.badge     = 1

        if let desc = task.description, !desc.isEmpty {
            content.subtitle = desc
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Cancel

    func cancelNotification(for task: Task) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
