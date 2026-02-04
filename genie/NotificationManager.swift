//
//  NotificationManager.swift
//  genie
//
//  Smart notification system with actionable alerts
//

import Foundation
import UserNotifications
import SwiftData

// MARK: - Notification Categories & Actions

enum NotificationCategory: String {
    case routineReminder = "ROUTINE_REMINDER"
    case earlyWarning = "EARLY_WARNING"
    case outlierAlert = "OUTLIER_ALERT"
    case feedbackRequest = "FEEDBACK_REQUEST"
}

enum NotificationAction: String {
    case logNow = "LOG_NOW"
    case snooze = "SNOOZE_5"
    case dismiss = "DISMISS"
    case caughtIt = "CAUGHT_IT"
    case missedIt = "MISSED_IT"
}

// MARK: - Notification Manager

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled: Bool = false
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Handling
    
    func checkAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            authorizationStatus = settings.authorizationStatus
            isEnabled = settings.authorizationStatus == .authorized
        }
    }
    
    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        await MainActor.run {
            authorizationStatus = granted ? .authorized : .denied
            isEnabled = granted
        }
        
        if granted {
            registerNotificationCategories()
        }
        
        return granted
    }
    
    // MARK: - Register Actionable Categories
    
    private func registerNotificationCategories() {
        // Action: Log Event Now
        let logNowAction = UNNotificationAction(
            identifier: NotificationAction.logNow.rawValue,
            title: "I'm on it! ✓",
            options: [.foreground]
        )
        
        // Action: Snooze
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: "Remind me in 5 min",
            options: []
        )
        
        // Action: Dismiss
        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismiss.rawValue,
            title: "Dismiss",
            options: [.destructive]
        )
        
        // Category: Routine Reminder (with all actions)
        let routineCategory = UNNotificationCategory(
            identifier: NotificationCategory.routineReminder.rawValue,
            actions: [logNowAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Category: Early Warning (with log action only)
        let earlyWarningCategory = UNNotificationCategory(
            identifier: NotificationCategory.earlyWarning.rawValue,
            actions: [logNowAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Category: Outlier Alert (dismiss only)
        let outlierCategory = UNNotificationCategory(
            identifier: NotificationCategory.outlierAlert.rawValue,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Action: Caught It (Feedback)
        let caughtItAction = UNNotificationAction(
            identifier: NotificationAction.caughtIt.rawValue,
            title: "Caught it! ✅",
            options: []
        )
        
        // Action: Missed It (Feedback)
        let missedItAction = UNNotificationAction(
            identifier: NotificationAction.missedIt.rawValue,
            title: "Missed it... ❌",
            options: []
        )
        
        // Category: Feedback Request (for boarding events)
        let feedbackCategory = UNNotificationCategory(
            identifier: NotificationCategory.feedbackRequest.rawValue,
            actions: [caughtItAction, missedItAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([
            routineCategory,
            earlyWarningCategory,
            outlierCategory,
            feedbackCategory
        ])
    }
    
    // MARK: - Smart Scheduling Based on Routine
    
    func scheduleSmartNotifications(
        suggestions: [RoutineSuggestion],
        bufferMinutes: Int = 10
    ) async {
        // Clear existing notifications first
        await clearAllNotifications()
        
        guard isEnabled else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        for suggestion in suggestions {
            guard suggestion.confidence > 0.6 else { continue } // Only high confidence
            
            // Schedule notification 5 minutes before suggested time
            guard let suggestedTime = suggestion.suggestedTime,
                  let notificationTime = calendar.date(
                    byAdding: .minute,
                    value: -5,
                    to: suggestedTime
                  ) else { continue }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "⏰ Time for \(suggestion.eventType.rawValue)"
            content.body = generateNotificationBody(
                for: suggestion.eventType,
                reasoning: suggestion.reasoning,
                bufferMinutes: bufferMinutes
            )
            content.sound = .default
            
            // Use feedback category for boarding events
            if isBoardingEvent(suggestion.eventType) {
                content.categoryIdentifier = NotificationCategory.feedbackRequest.rawValue
            } else {
                content.categoryIdentifier = NotificationCategory.routineReminder.rawValue
            }
            
            // Store event type in userInfo for action handling
            content.userInfo = [
                "eventType": suggestion.eventType.rawValue,
                "suggestedTime": suggestedTime.timeIntervalSince1970
            ]
            
            // Create daily repeating trigger
            let components = calendar.dateComponents(
                [.hour, .minute],
                from: notificationTime
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )
            
            // Create request
            let identifier = "routine_\(suggestion.eventType.rawValue)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            // Schedule notification
            try? await center.add(request)
        }
    }
    
    private func generateNotificationBody(
        for eventType: EventType,
        reasoning: String,
        bufferMinutes: Int
    ) -> String {
        switch eventType {
        case .wakeUp:
            return "Time to start your day! \(reasoning)"
        
        case .leavingHome:
            if bufferMinutes > 0 {
                return "Time to leave! Including \(bufferMinutes) min buffer for a stress-free commute."
            } else {
                return "Time to leave! \(reasoning)"
            }
        
        case .bedTime:
            return "Consider winding down. \(reasoning)"
        
        default:
            return reasoning
        }
    }
    
    // MARK: - Schedule One-Time Alert
    
    func scheduleOneTimeAlert(
        eventType: EventType,
        at date: Date,
        message: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = eventType.rawValue
        content.body = message
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.earlyWarning.rawValue
        content.userInfo = ["eventType": eventType.rawValue]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "alert_\(eventType.rawValue)_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try? await center.add(request)
    }
    
    // MARK: - Outlier Alert
    
    func sendOutlierAlert(
        eventType: EventType,
        deviation: Int,
        averageTime: Date
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Unusual Pattern Detected"
        
        let timeString = averageTime.formatted(date: .omitted, time: .shortened)
        content.body = "You usually \(eventType.rawValue.lowercased()) around \(timeString), but today you're ±\(deviation) minutes off pattern."
        
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.outlierAlert.rawValue
        
        let request = UNNotificationRequest(
            identifier: "outlier_\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        try? await center.add(request)
    }
    
    // MARK: - Notification Management
    
    func clearAllNotifications() async {
        center.removeAllPendingNotificationRequests()
    }
    
    func clearNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }
    
    func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification action tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        Task { @MainActor in
            await handleNotificationAction(
                actionIdentifier: response.actionIdentifier,
                userInfo: userInfo
            )
            completionHandler()
        }
    }
    
    // Handle notification action
    private func handleNotificationAction(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let eventTypeString = userInfo["eventType"] as? String,
              let eventType = EventType(rawValue: eventTypeString) else {
            return
        }
        
        switch actionIdentifier {
        case NotificationAction.logNow.rawValue:
            // Log the event in SwiftData
            await logEventFromNotification(eventType: eventType)
            
        case NotificationAction.snooze.rawValue:
            // Reschedule notification in 5 minutes
            await scheduleOneTimeAlert(
                eventType: eventType,
                at: Date().addingTimeInterval(300), // 5 minutes
                message: "Reminder: Time for \(eventType.rawValue)"
            )
            
        case NotificationAction.dismiss.rawValue:
            // Just dismiss, no action needed
            break
        
        case NotificationAction.caughtIt.rawValue:
            // Record success feedback
            await recordFeedback(eventType: eventType, wasSuccessful: true)
            
        case NotificationAction.missedIt.rawValue:
            // Record failure feedback
            await recordFeedback(eventType: eventType, wasSuccessful: false)
            
        default:
            // Default tap (not on action button) - could open app
            break
        }
    }
    
    // MARK: - Feedback Helpers
    
    private func isBoardingEvent(_ eventType: EventType) -> Bool {
        switch eventType {
        case .boardingBus, .boardingSubway, .boardingReturnBus, .boardingReturnSubway:
            return true
        default:
            return false
        }
    }
    
    private func recordFeedback(eventType: EventType, wasSuccessful: Bool) async {
        // ⚡ POWER OPTIMIZATION: Quick feedback recording
        let startTime = Date()
        
        do {
            // Create background context (lightweight)
            let container = try ModelContainer(for: RoutineSuccess.self)
            let context = ModelContext(container)
            
            // Create feedback entry (minimal allocation)
            let feedback = RoutineSuccess(
                eventType: eventType,
                timestamp: Date(),
                wasSuccessful: wasSuccessful
            )
            context.insert(feedback)
            
            // Save (fast write)
            try context.save()
            
            // Show feedback confirmation (async, non-blocking)
            await showFeedbackConfirmation(wasSuccessful: wasSuccessful, eventType: eventType)
            
            let duration = Date().timeIntervalSince(startTime)
            print("⚡ Feedback saved in \(String(format: "%.3f", duration))s")
            
        } catch {
            print("Failed to record feedback: \(error)")
        }
        
        // ✅ Function exits quickly, minimal battery impact
    }
    
    private func showFeedbackConfirmation(wasSuccessful: Bool, eventType: EventType) async {
        let content = UNMutableNotificationContent()
        
        if wasSuccessful {
            content.title = "✅ Feedback Recorded"
            content.body = "Great! Your timing for \(eventType.rawValue) is working well."
        } else {
            content.title = "📝 Feedback Recorded"
            content.body = "Got it. We'll suggest leaving 5 minutes earlier tomorrow to help you catch it!"
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "feedback_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try? await center.add(request)
    }
    
    // MARK: - Background SwiftData Update (Power Optimized)
    
    private func logEventFromNotification(eventType: EventType) async {
        // ⚡ POWER OPTIMIZATION: Quick operation, minimal CPU time
        let startTime = Date()
        
        do {
            // Create background context (lightweight)
            let container = try ModelContainer(for: RoutineLog.self)
            let context = ModelContext(container)
            
            // Create new log (minimal allocation)
            let newLog = RoutineLog(eventType: eventType, timestamp: Date())
            context.insert(newLog)
            
            // Save (fast write)
            try context.save()
            
            // Show success notification (async, non-blocking)
            await showSuccessNotification(for: eventType)
            
            let duration = Date().timeIntervalSince(startTime)
            print("⚡ Log saved in \(String(format: "%.3f", duration))s")
            
        } catch {
            print("Failed to log event from notification: \(error)")
        }
        
        // ✅ Function exits quickly, app suspends immediately
    }
    
    private func showSuccessNotification(for eventType: EventType) async {
        let content = UNMutableNotificationContent()
        content.title = "✅ Logged!"
        content.body = "\(eventType.rawValue) recorded at \(Date().formatted(date: .omitted, time: .shortened))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "success_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )
        
        try? await center.add(request)
    }
}

// MARK: - Notification Scheduling Helper

extension NotificationManager {
    func updateNotificationsIfEnabled(
        analyticsManager: AnalyticsManager,
        bufferMinutes: Int
    ) async {
        guard isEnabled else { return }
        
        let suggestions = analyticsManager.getRoutineSuggestions(days: 7)
        await scheduleSmartNotifications(
            suggestions: suggestions,
            bufferMinutes: bufferMinutes
        )
    }
}
