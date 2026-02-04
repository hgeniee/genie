# Genie - Your Intelligent Routine Assistant

An iOS app that learns your daily patterns and helps optimize your schedule.

## 📱 Features

### Phase 1: Routine Logging ✅
- **Quick Tap Logging**: Log daily events with a single tap
- **Manual Entry Mode**: Add logs with custom dates and times
- **Today's Progress**: Visual progress tracking with completion percentage
- **Timeline View**: Chronological view of your daily activities
- **Beautiful UI**: Clean, modern design with smooth animations

### Phase 2: Analytics & Insights ✅
- **Consistency Scoring**: Measure how regular your routine is (0-100%)
- **Event Pattern Analysis**: See average times for each activity
- **Commute Intelligence**: Track travel times between locations
- **Smart Suggestions**: AI-powered schedule recommendations
- **Multi-Day Analysis**: Analyze patterns over 3-30 days
- **Daily Activity Charts**: Visual completion tracking

## 🚀 Getting Started

1. **Open the project in Xcode**
   ```bash
   open genie.xcodeproj
   ```

2. **Build and Run** (Cmd+R)

3. **Start Logging**: Use the "Log" tab to record your daily events

4. **View Insights**: After 2-3 days, check the "Insights" tab for analytics

## 📊 Tracked Events

- 🌅 Wake Up
- 🚪 Leaving Home  
- 🚇 Boarding Subway
- 🚌 Boarding Bus
- 🏢 Arriving at Work
- 🍴 Lunch Time
- 💼 Leaving Work
- 🚌 Boarding Return Bus
- 🚇 Boarding Return Subway
- 🏡 Arriving Home
- 🥡 Dinner Time
- 📚 Hobby/Study Time
- 🌙 Bed Time

## 📁 Project Structure

```
genie/
├── RoutineLog.swift         # Data model
├── LoggingView.swift        # Phase 1: Logging UI
├── AnalyticsManager.swift   # Phase 2: Analytics engine
├── InsightsView.swift       # Phase 2: Insights UI
└── genieApp.swift           # App entry with TabView
```

## 🛠 Technology

- SwiftUI
- SwiftData
- iOS 17.0+

## 📚 Documentation

- `PHASE2_SUMMARY.md` - Complete Phase 2 feature documentation
- `ANALYTICS_USAGE_GUIDE.md` - Developer guide for using analytics

---

**Built with ❤️ for better daily routines**
