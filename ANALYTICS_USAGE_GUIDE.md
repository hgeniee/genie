# Analytics Manager - Usage Guide

## Quick Start

The `AnalyticsManager` is already integrated into `InsightsView`. Here's how to use it in other contexts:

### Basic Setup

```swift
import SwiftUI
import SwiftData

// Initialize with logs from SwiftData
@Query private var logs: [RoutineLog]
@State private var analyticsManager = AnalyticsManager()

// Update when logs change
.onAppear {
    analyticsManager.updateLogs(logs)
}
.onChange(of: logs) { _, newLogs in
    analyticsManager.updateLogs(newLogs)
}
```

## Common Use Cases

### 1. Get Overall Consistency

```swift
let score = analyticsManager.getOverallConsistencyScore(days: 7)
print("Your routine is \(Int(score * 100))% consistent")

// Output: "Your routine is 85% consistent"
```

### 2. Analyze a Specific Event

```swift
if let wakeUpInsight = analyticsManager.getEventInsight(for: .wakeUp, days: 5) {
    print("You typically wake up at: \(wakeUpInsight.averageTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
    print("Consistency: \(Int(wakeUpInsight.consistency * 100))%")
    print("Earliest: \(wakeUpInsight.earliestTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
    print("Latest: \(wakeUpInsight.latestTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
}

// Output:
// You typically wake up at: 7:15 AM
// Consistency: 92%
// Earliest: 6:45 AM
// Latest: 7:30 AM
```

### 3. Commute Duration Analysis

```swift
if let commute = analyticsManager.getDurationInsight(
    from: .leavingHome, 
    to: .arrivingAtWork, 
    days: 5
) {
    print("Average commute: \(commute.averageDuration.hoursMinutesFormatted)")
    print("Fastest: \(commute.minDuration.minutesFormatted)")
    print("Slowest: \(commute.maxDuration.minutesFormatted)")
}

// Output:
// Average commute: 42m
// Fastest: 35 min
// Slowest: 58 min
```

### 4. Get All Commute Insights

```swift
let commuteInsights = analyticsManager.getCommuteInsights(days: 7)

for insight in commuteInsights {
    print("\(insight.fromEvent.rawValue) → \(insight.toEvent.rawValue): \(insight.averageDuration.hoursMinutesFormatted)")
}

// Output:
// Leaving Home → Boarding Bus: 8m
// Boarding Bus → Arriving at Work: 25m
// Leaving Work → Arriving Home: 35m
```

### 5. Get Routine Suggestions

```swift
let suggestions = analyticsManager.getRoutineSuggestions(days: 7)

for suggestion in suggestions {
    print("📌 \(suggestion.eventType.rawValue)")
    print("   Suggested: \(suggestion.suggestedTime.formatted(date: .omitted, time: .shortened))")
    print("   Confidence: \(Int(suggestion.confidence * 100))%")
    print("   Reason: \(suggestion.reasoning)")
    print()
}

// Output:
// 📌 Wake Up
//    Suggested: 7:00 AM
//    Confidence: 88%
//    Reason: Based on your routine, waking up at 7:00 keeps you on schedule.
//
// 📌 Leaving Home
//    Suggested: 8:05 AM
//    Confidence: 85%
//    Reason: Your commute typically takes 35 minutes. Leaving at your usual time ensures you arrive on schedule.
```

### 6. Daily Summaries

```swift
let summaries = analyticsManager.getDailySummaries(days: 7)

for summary in summaries {
    let percentage = Int(summary.completionRate * 100)
    print("\(summary.date.formatted(date: .abbreviated, time: .omitted)): \(summary.logs.count) events logged (\(percentage)%)")
}

// Output:
// Feb 4, 2026: 11 events logged (85%)
// Feb 3, 2026: 13 events logged (100%)
// Feb 2, 2026: 9 events logged (69%)
// Feb 1, 2026: 12 events logged (92%)
```

### 7. All Event Insights

```swift
let allInsights = analyticsManager.getAllEventInsights(days: 7)

for insight in allInsights {
    print("\(insight.eventType.rawValue): \(Int(insight.consistency * 100))% consistent over \(insight.occurrenceCount) days")
}

// Output:
// Wake Up: 92% consistent over 7 days
// Leaving Home: 85% consistent over 7 days
// Boarding Bus: 78% consistent over 6 days
// Arriving at Work: 88% consistent over 7 days
```

## Understanding the Data Models

### EventInsight
```swift
struct EventInsight {
    let eventType: EventType          // Which event
    let averageTime: Date?            // Typical time (hour:minute)
    let earliestTime: Date?           // Earliest logged time
    let latestTime: Date?             // Latest logged time
    let consistency: Double           // 0.0 to 1.0 (0% to 100%)
    let occurrenceCount: Int          // How many days logged
}
```

### DurationInsight
```swift
struct DurationInsight {
    let fromEvent: EventType          // Starting event
    let toEvent: EventType            // Ending event
    let averageDuration: TimeInterval // Avg seconds between events
    let minDuration: TimeInterval     // Fastest duration
    let maxDuration: TimeInterval     // Slowest duration
    let samples: Int                  // How many days analyzed
}
```

### DailySummary
```swift
struct DailySummary {
    let date: Date                    // Day being summarized
    let logs: [RoutineLog]            // All logs for that day
    let completionRate: Double        // Percentage of events logged (0.0-1.0)
}
```

### RoutineSuggestion
```swift
struct RoutineSuggestion {
    let eventType: EventType          // Event to schedule
    let suggestedTime: Date           // Recommended time
    let confidence: Double            // How confident (0.0-1.0)
    let reasoning: String             // Why this suggestion
}
```

## Helper Extensions

### TimeInterval Formatting

```swift
let duration: TimeInterval = 2580 // 43 minutes in seconds

// Format as minutes
print(duration.minutesFormatted)
// Output: "43 min"

// Format as hours and minutes
print(duration.hoursMinutesFormatted)
// Output: "43m"

let longDuration: TimeInterval = 5400 // 1.5 hours
print(longDuration.hoursMinutesFormatted)
// Output: "1h 30m"
```

## Tips for Best Results

### 1. Minimum Data Requirements
- **Consistency Score**: At least 3 days of data
- **Duration Analysis**: At least 2 samples needed
- **Suggestions**: Requires consistency > 50%

### 2. Improving Accuracy
- Log events consistently for 7+ days
- Try to log at similar times daily
- Don't skip days

### 3. Handling Missing Data
The analytics engine gracefully handles:
- ✅ Missing days (doesn't count in averages)
- ✅ Partial days (analyzes what's available)
- ✅ Empty datasets (returns nil/empty arrays)

### 4. Performance Considerations
- Default analysis period: **5 days** (good balance)
- Maximum recommended: **30 days** (still fast)
- Extended analysis: **90+ days** (may be slow on older devices)

## Custom Analytics Examples

### Example 1: Sleep Duration Analysis

```swift
if let sleepInsight = analyticsManager.getSleepInsights(days: 7) {
    let hours = sleepInsight.averageDuration / 3600
    print("You typically sleep \(String(format: "%.1f", hours)) hours per night")
    
    if hours < 7 {
        print("⚠️ Consider sleeping more for better health")
    } else {
        print("✅ Great sleep habits!")
    }
}
```

### Example 2: Punctuality Score

```swift
// Check if user arrives at work consistently
if let arrivalInsight = analyticsManager.getEventInsight(for: .arrivingAtWork, days: 7) {
    let punctuality = arrivalInsight.consistency
    
    switch punctuality {
    case 0.9...: print("🌟 Always on time!")
    case 0.7..<0.9: print("👍 Usually on time")
    case 0.5..<0.7: print("⏰ Sometimes late")
    default: print("🚨 Frequently late")
    }
}
```

### Example 3: Commute Optimization

```swift
// Find the most variable commute segment
let segments = analyticsManager.getCommuteInsights(days: 14)
let mostVariable = segments.max { a, b in
    (a.maxDuration - a.minDuration) < (b.maxDuration - b.minDuration)
}

if let segment = mostVariable {
    let variance = Int((segment.maxDuration - segment.minDuration) / 60)
    print("⚠️ \(segment.fromEvent.rawValue) to \(segment.toEvent.rawValue)")
    print("   Varies by up to \(variance) minutes")
    print("   💡 Consider leaving earlier to account for variability")
}
```

## Integration with SwiftUI

### Custom Insight Card

```swift
struct CustomInsightCard: View {
    let analyticsManager: AnalyticsManager
    let eventType: EventType
    
    var body: some View {
        if let insight = analyticsManager.getEventInsight(for: eventType, days: 5) {
            VStack(alignment: .leading) {
                Text(eventType.rawValue)
                    .font(.headline)
                
                if let avgTime = insight.averageTime {
                    Text("Usually at \(avgTime.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline)
                }
                
                ProgressView(value: insight.consistency) {
                    Text("Consistency: \(Int(insight.consistency * 100))%")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}
```

## Debugging Tips

```swift
// Print all available data for debugging
func debugAnalytics() {
    print("=== Analytics Debug ===")
    print("Total logs: \(logs.count)")
    print("Overall consistency: \(Int(analyticsManager.getOverallConsistencyScore(days: 7) * 100))%")
    print("\nEvent Insights:")
    for insight in analyticsManager.getAllEventInsights(days: 7) {
        print("  \(insight.eventType.rawValue): \(insight.occurrenceCount) days")
    }
    print("\nCommute Insights:")
    for insight in analyticsManager.getCommuteInsights(days: 7) {
        print("  \(insight.fromEvent.rawValue) → \(insight.toEvent.rawValue): \(insight.samples) samples")
    }
}
```

## Summary

The `AnalyticsManager` provides:
- ✅ **Simple API** for complex calculations
- ✅ **Flexible time ranges** (3-30+ days)
- ✅ **Robust error handling** (nil for insufficient data)
- ✅ **Performant** (in-memory calculations)
- ✅ **SwiftUI-friendly** (Observable pattern)

Use it to build intelligent features that help users optimize their daily routines!
