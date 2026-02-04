# genie - Personal Life-Pattern Analyzer

A minimalist iOS app built with SwiftUI and SwiftData that helps you analyze and optimize your daily routines through pattern recognition.

## 📱 Current Status: Phase 1 - Data Collection

### What's Implemented

#### 1. SwiftData Model (`RoutineLog.swift`)
- **RoutineLog Model**: Stores event type and timestamp with UUID
- **EventType Enum**: 13 daily life events with:
  - Descriptive names
  - SF Symbol icons
  - Color-coded accents for visual distinction
  
#### 2. Main Logging Interface (`LoggingView.swift`)
- **Today's Progress Card**: 
  - Shows logged events vs total events
  - Animated circular progress indicator
  - Linear progress bar with gradient
  
- **Event Logging Buttons**:
  - One-tap timestamp recording
  - Visual feedback (checkmark when logged)
  - Color-coded based on event type
  - Shows last logged time
  
- **Today's Timeline**:
  - Chronological view of logged events
  - Visual timeline with dots and connecting lines
  - Quick glance at your day's structure
  
- **Success Animation**:
  - Confirmation overlay when logging
  - Haptic feedback for better UX
  
#### 3. App Entry Point (`genieApp.swift`)
- SwiftData model container configuration
- Automatic data persistence

---

## 🚀 Setup Instructions

### Step 1: Create New Xcode Project
1. Open Xcode
2. File → New → Project
3. Choose "App" template
4. Configure:
   - **Product Name**: genie
   - **Interface**: SwiftUI
   - **Storage**: None (we'll add SwiftData manually)
   - **Language**: Swift
   - **Organization Identifier**: com.yourname.genie

### Step 2: Add the Files
1. Delete the default `ContentView.swift` file
2. Add these three files to your project:
   - `RoutineLog.swift`
   - `LoggingView.swift`
   - Replace `genieApp.swift` content

### Step 3: Update Info.plist (Optional)
For better appearance, you can set:
- Launch Screen background color
- App display name to "genie"

### Step 4: Build and Run
- Select your iPhone or simulator
- Press Cmd+R to build and run

---

## 🎨 Design Philosophy

### Minimalist Aesthetics
- **Native iOS Design**: Uses system fonts, SF Symbols, and standard components
- **Generous White Space**: Clean, uncluttered interface
- **Subtle Shadows**: Depth without distraction
- **Color Coding**: 8 distinct accent colors for event categorization

### User Experience Principles
- **One-Tap Logging**: Instant timestamp capture
- **Visual Feedback**: Animations and haptics confirm actions
- **Progress Tracking**: Clear daily completion status
- **Timeline View**: Chronological event visualization

---

## 📊 The 13 Tracked Events

| Event | Icon | Use Case |
|-------|------|----------|
| Wake Up | 🌅 | Start of your day |
| Leaving Home | 🚪 | Departure time tracking |
| Boarding Bus | 🚌 | Morning commute - bus |
| Boarding Subway | 🚇 | Morning commute - train |
| Arriving at Work | 🏢 | Work/school arrival |
| Lunch Time | 🍴 | Midday meal timing |
| Leaving Work | 💼 | End of work/school |
| Boarding Return Bus | 🚌 | Evening commute - bus |
| Boarding Return Subway | 🚇 | Evening commute - train |
| Arriving Home | 🏠 | Return home time |
| Dinner Time | 🥡 | Evening meal timing |
| Hobby/Study Time | 📚 | Personal development |
| Bed Time | 🌙 | Sleep schedule tracking |

---

## 🔮 Future Phases (Not Yet Implemented)

### Phase 2: Pattern Analysis
- Calculate average durations between events
- Identify correlations (e.g., "Leave home by 8:07 → Catch 8:15 bus")
- Week-over-week trend analysis
- Consistency scoring

### Phase 3: Routine Optimization
- Suggest optimal schedule based on historical data
- "Ideal Routine" activation feature
- Smart notifications for upcoming events
- Deviation alerts

### Additional Features to Consider
- **Weekly/Monthly Overview**: Calendar view of consistency
- **Statistics Dashboard**: Charts and insights
- **Export Functionality**: CSV export for external analysis
- **Widgets**: Home screen quick logging
- **Custom Events**: User-defined event types
- **Smart Suggestions**: "You usually log X at this time"

---

## 🛠 Technical Details

### SwiftData Schema
```swift
@Model
final class RoutineLog {
    var id: UUID
    var eventType: EventType
    var timestamp: Date
}
```

### Data Persistence
- Automatic local storage via SwiftData
- No cloud sync (private by design)
- Efficient querying with `@Query` property wrapper

### Performance Considerations
- Lazy loading for timeline
- Filtered queries for today's logs
- Minimal memory footprint

---

## 💡 Usage Tips

### First Week Strategy
1. **Be Consistent**: Log events at their actual time
2. **Don't Overthink**: Quick taps throughout the day
3. **Skip When Needed**: Not every event happens daily
4. **Observe Patterns**: Notice your natural rhythms

### After 7 Days
You'll have enough data to analyze:
- Consistent wake-up times
- Optimal departure windows
- Travel time patterns
- Evening routine structure

---

## 🐛 Known Limitations (Phase 1)

- Can only log one instance per event per day
- No editing/deleting individual logs (only bulk clear)
- No multi-day overview yet
- No export functionality

---

## 🔒 Privacy

- **100% Local**: All data stored on your device
- **No Tracking**: No analytics or telemetry
- **No Account**: No sign-up required
- **Your Data**: Complete ownership and control

---

## 📝 Code Structure

```
genie/
├── genieApp.swift          # App entry point & SwiftData setup
├── RoutineLog.swift        # Data model & EventType enum
└── LoggingView.swift       # Main UI with logging interface
```

---

## 🎯 Next Steps

To continue development:

1. **Add Week View**: Visualize 7 days of data
2. **Implement Analytics**: Duration calculations between events
3. **Create Insights View**: Pattern detection and suggestions
4. **Build Routine Optimizer**: Generate ideal schedules
5. **Add Notifications**: Remind to log events

---

## 🤝 Development Notes

### For Pattern Analysis (Phase 2)
You'll want to create:
- `AnalyticsEngine.swift` - Statistical calculations
- `PatternDetector.swift` - Correlation finder
- `AnalyticsView.swift` - Insights visualization

### For Routine Optimization (Phase 3)
You'll want to create:
- `RoutineOptimizer.swift` - Suggestion algorithm
- `IdealRoutine.swift` - Model for suggested schedule
- `RoutineView.swift` - Activation and management UI

---

## 📄 License

Personal use project - modify as needed for your requirements.

---

**Built with ❤️ using SwiftUI & SwiftData**
