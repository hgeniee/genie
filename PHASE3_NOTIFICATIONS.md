# Phase 3 - Smart Notifications & Actionable Alerts

## ✅ Completed Implementation

### Overview
Phase 3 transforms genie into a proactive assistant that reminds you of important events based on your routine patterns. Users can log events directly from notifications without opening the app.

---

## 🔔 Core Components

### 1. NotificationManager.swift

**Purpose:** Central hub for all notification logic

**Key Features:**
- ✅ Permission handling (request, check status)
- ✅ Smart scheduling based on routine analysis
- ✅ Actionable notification categories
- ✅ Background SwiftData updates
- ✅ Notification cleanup & management

**Architecture:**
```swift
@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate
```

---

## 📋 Notification Categories

### Category 1: Routine Reminder
**Used for:** Scheduled daily reminders based on routine patterns

**Actions:**
1. **"I'm on it! ✓"** (Foreground)
   - Opens app
   - User can confirm or adjust
   
2. **"Remind me in 5 min"** (Background)
   - Reschedules notification
   - No app interaction needed
   
3. **"Dismiss"** (Destructive)
   - Removes notification
   - No logging

**Example:**
```
⏰ Time for Leaving Home
Time to leave! Including 10 min buffer for a stress-free commute.
[I'm on it! ✓] [Remind me in 5 min] [Dismiss]
```

### Category 2: Early Warning
**Used for:** Time-sensitive alerts

**Actions:**
1. **"I'm on it! ✓"** (Foreground)
2. **"Dismiss"**

### Category 3: Outlier Alert
**Used for:** Pattern deviation notifications

**Actions:**
1. **"Dismiss"** only

**Example:**
```
⚠️ Unusual Pattern Detected
You usually leave home around 8:00 AM, but today you're ±45 minutes off pattern.
[Dismiss]
```

---

## 🎯 Smart Scheduling Logic

### How It Works

1. **Analyze Routine** (uses `AnalyticsManager`)
   ```swift
   let suggestions = analyticsManager.getRoutineSuggestions(days: 7)
   ```

2. **Filter High-Confidence Suggestions**
   - Only schedules notifications for suggestions with >60% confidence
   - Ensures reliable patterns before reminding

3. **Calculate Notification Time**
   - Schedules 5 minutes before suggested event time
   - Gives user time to prepare

4. **Generate Dynamic Messages**
   - Tailored to event type
   - Includes reasoning from analytics
   - Incorporates buffer time when relevant

5. **Set Repeating Trigger**
   - Daily notifications at calculated times
   - Uses `UNCalendarNotificationTrigger`

### Example Flow

```
Your Routine:
- Usually leave home at 8:05 AM
- Consistency: 85%

Notification Scheduled:
- Time: 8:00 AM (5 min before)
- Daily: Yes
- Message: "Time to leave! Including 10 min buffer for a stress-free commute."
```

---

## 🔄 Background SwiftData Updates

### The Challenge
When user taps "I'm on it! ✓", the app may not be running. We need to:
1. Create a `RoutineLog` entry
2. Save to SwiftData
3. Confirm success to user

### The Solution

```swift
private func logEventFromNotification(eventType: EventType) async {
    do {
        // Create background context
        let container = try ModelContainer(for: RoutineLog.self)
        let context = ModelContext(container)
        
        // Create new log
        let newLog = RoutineLog(eventType: eventType, timestamp: Date())
        context.insert(newLog)
        
        // Save
        try context.save()
        
        // Show success notification
        await showSuccessNotification(for: eventType)
        
    } catch {
        print("Failed to log event from notification: \(error)")
    }
}
```

**Key Points:**
- ✅ Creates separate `ModelContainer` for background context
- ✅ Uses `ModelContext` for thread-safe operations
- ✅ Shows confirmation notification after successful save
- ✅ Works even when app is completely closed

### Success Confirmation

After logging from notification, user sees:
```
✅ Logged!
Leaving Home recorded at 8:05 AM
```

---

## ⚙️ Settings Integration

### UI Components

**1. Smart Reminders Toggle**
```
🔔 Smart Reminders
Get notified based on your routine patterns
[Toggle]
```

**2. Active Notifications Display**
Shows count of scheduled notifications:
```
Active Notifications
✓ 3 scheduled [Refresh]
[Clear Old Notifications]
```

**3. Permission Denied State**
```
⚠️ Notification Permission Denied
Please enable notifications in Settings → genie → Notifications
[Open Settings]
```

### Permission Flow

**First Enable:**
1. User toggles "Smart Reminders" ON
2. System shows permission alert:
   ```
   Enable Notifications?
   Allow genie to send you smart reminders based on your routine patterns.
   [Enable] [Not Now]
   ```
3. If granted → Schedule notifications
4. If denied → Show helpful error message

**Re-Enable After Denial:**
- Shows "Open Settings" button
- Directs to iOS Settings app
- User can change permission there

---

## 🧹 Notification Cleanup

### Automatic Cleanup

**When notifications are disabled:**
```swift
await notificationManager.clearAllNotifications()
```
- Removes all pending notifications
- Prevents notification spam
- Clean state for re-enabling

**When schedule is updated:**
1. Clear all existing notifications
2. Recalculate from current routine data
3. Schedule new notifications

### Manual Cleanup

**Clear Delivered Notifications:**
```swift
await notificationManager.clearDeliveredNotifications()
```
- Removes notifications from notification center
- Keeps scheduled (future) notifications intact

### Smart Cleanup Strategy
- Old notifications auto-expire after 24 hours (iOS default)
- When routine changes → reschedule automatically
- No duplicate notifications (uses consistent identifiers)

---

## 📱 User Experience Flow

### First Time Setup

1. **Open Settings Tab**
2. **Toggle "Smart Reminders" ON**
3. **Permission Alert Appears**
   - "Enable" → Notifications active
   - "Not Now" → Can enable later
4. **Notifications Schedule Automatically**
   - Based on 7-day routine analysis
   - Only high-confidence suggestions

### Daily Usage

**Scenario 1: Normal Day**
```
8:00 AM → Notification: "Time to leave!"
User taps: "I'm on it! ✓"
Result: Event logged, notification dismissed
```

**Scenario 2: Running Late**
```
8:00 AM → Notification: "Time to leave!"
User taps: "Remind me in 5 min"
8:05 AM → Notification: "Reminder: Time for Leaving Home"
```

**Scenario 3: Unusual Pattern**
```
5:30 AM → User manually logs "Wake Up" (2 hours early)
5:31 AM → Outlier notification:
"⚠️ Unusual Pattern Detected
You usually wake up around 7:15 AM, but today you're ±105 minutes off pattern."
```

---

## 🔧 Technical Implementation Details

### 1. Notification Identifiers

**Format:** `{category}_{eventType}_{optional_timestamp}`

Examples:
- `routine_LeavingHome` (repeating)
- `alert_WakeUp_1706990400` (one-time)
- `outlier_a1b2c3d4` (immediate)

**Benefits:**
- Easy to find and cancel specific notifications
- Prevents duplicates
- Enables targeted cleanup

### 2. UserInfo Dictionary

Stores metadata for action handling:

```swift
content.userInfo = [
    "eventType": suggestion.eventType.rawValue,
    "suggestedTime": suggestedTime.timeIntervalSince1970
]
```

**Accessed in action handler:**
```swift
let eventTypeString = userInfo["eventType"] as? String
let eventType = EventType(rawValue: eventTypeString)
```

### 3. Thread Safety

**Main Actor:**
```swift
@MainActor
class NotificationManager: NSObject, ObservableObject
```
- UI updates happen on main thread
- State changes are synchronized

**Background Operations:**
```swift
nonisolated func userNotificationCenter(...) {
    Task { @MainActor in
        await handleNotificationAction(...)
    }
}
```
- Notification callbacks happen on background thread
- Wrap UI updates in `@MainActor` context

### 4. ModelContainer Lifecycle

**App Launch:**
```swift
.modelContainer(for: RoutineLog.self)
```
- Creates shared container for app

**Notification Action:**
```swift
let container = try ModelContainer(for: RoutineLog.self)
```
- Creates separate container for background
- Safe concurrent access

---

## 🎨 Message Templates

### Event-Specific Messages

**Wake Up:**
```
"Time to start your day! Based on your routine, waking up at 7:00 keeps you on schedule."
```

**Leaving Home (with buffer):**
```
"Time to leave! Including 10 min buffer for a stress-free commute."
```

**Leaving Home (without buffer):**
```
"Time to leave! Your commute typically takes 35 minutes. Leaving at your usual time ensures you arrive on schedule."
```

**Bed Time:**
```
"Consider winding down. You typically sleep at 11:00. Maintaining this schedule supports healthy sleep habits."
```

**Generic:**
```
{reasoning from RoutineSuggestion}
```

---

## 🚀 API Reference

### NotificationManager Methods

#### Permission Management
```swift
func requestAuthorization() async throws -> Bool
func checkAuthorizationStatus()
```

#### Scheduling
```swift
func scheduleSmartNotifications(
    suggestions: [RoutineSuggestion],
    bufferMinutes: Int = 10
) async

func scheduleOneTimeAlert(
    eventType: EventType,
    at date: Date,
    message: String
) async

func sendOutlierAlert(
    eventType: EventType,
    deviation: Int,
    averageTime: Date
) async
```

#### Cleanup
```swift
func clearAllNotifications() async
func clearNotification(withIdentifier identifier: String)
func clearDeliveredNotifications()
```

#### Queries
```swift
func getPendingNotifications() async -> [UNNotificationRequest]
func getDeliveredNotifications() async -> [UNNotification]
```

#### Helper
```swift
func updateNotificationsIfEnabled(
    analyticsManager: AnalyticsManager,
    bufferMinutes: Int
) async
```

---

## 🧪 Testing Guide

### Test Scenarios

**1. First Launch Permission**
```
Steps:
1. Fresh install
2. Settings → Toggle Smart Reminders
3. Verify permission alert appears
4. Tap "Enable"
5. Verify notifications schedule

Expected: 1-3 notifications scheduled for high-confidence events
```

**2. Actionable Notification**
```
Steps:
1. Wait for scheduled notification
2. Tap "I'm on it! ✓"
3. Check Log tab

Expected: Event appears in timeline
```

**3. Snooze Feature**
```
Steps:
1. Receive notification
2. Tap "Remind me in 5 min"
3. Wait 5 minutes

Expected: Notification reappears
```

**4. Background Logging**
```
Steps:
1. Force quit app
2. Tap notification action "I'm on it! ✓"
3. Open app
4. Check Log tab

Expected: Event was logged while app was closed
```

**5. Outlier Detection**
```
Steps:
1. Build consistent 7-day pattern for Wake Up
2. Log Wake Up 2+ hours off pattern
3. Check for outlier notification

Expected: "Unusual Pattern Detected" notification
```

**6. Notification Refresh**
```
Steps:
1. Log events for new days
2. Settings → Tap "Refresh"
3. Check pending count

Expected: Notifications update based on new data
```

---

## ⚠️ Important Notes

### iOS Limitations

**Notification Actions:**
- Maximum 4 actions per category
- Action titles: ~20 characters max
- Can't use custom UI in actions

**Delivery:**
- System may throttle notifications
- Silent hours respected (iOS 15+)
- Focus modes may suppress

**Background Execution:**
- Limited time for action handling
- Must complete quickly (~30 seconds)
- Heavy operations may timeout

### Best Practices

**Scheduling:**
- Don't schedule >64 notifications (iOS limit)
- Use repeating triggers when possible
- Always provide unique identifiers

**Messages:**
- Keep concise (<100 characters ideal)
- Include actionable information
- Avoid jargon or emoji overuse

**Permissions:**
- Never assume granted
- Always check status before scheduling
- Provide clear value proposition

---

## 🎉 Phase 3 Summary

### What's New

✅ **Smart Notifications** - Based on routine patterns  
✅ **Actionable Alerts** - Log from notification  
✅ **Background Logging** - Works when app is closed  
✅ **Permission Handling** - Clean request flow  
✅ **Notification Management** - Schedule, clear, refresh  
✅ **Outlier Alerts** - Unusual pattern detection  
✅ **Settings Integration** - Full control panel  

### User Benefits

🎯 **Never Miss Important Events** - Timely reminders  
⚡ **Quick Logging** - No need to open app  
🧠 **Smart Timing** - 5 min before optimal time  
🛡️ **Buffer Time** - Built into suggestions  
📊 **Pattern Awareness** - Outlier notifications  
🔧 **Full Control** - Enable/disable anytime  

### Technical Achievements

🏗️ **Clean Architecture** - Separated concerns  
🔄 **Background Persistence** - SwiftData from notifications  
🎭 **Multiple Categories** - Different notification types  
🧵 **Thread-Safe** - Proper actor isolation  
🧹 **Smart Cleanup** - No notification clutter  
📱 **Native Integration** - iOS best practices  

---

**Phase 3 Complete! 🚀**

Your app is now a fully-featured intelligent routine assistant with proactive notifications!
