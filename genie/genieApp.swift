//
//  genieApp.swift
//  genie
//
//  Created by 이현진 on 2/4/26.
//

import SwiftUI
import SwiftData

@main
struct genieApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var backgroundTaskManager = BackgroundTaskManager.shared
    
    init() {
        // Initialize managers early
        _ = NotificationManager.shared
        
        // Register background tasks (MUST be done in init)
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Check notification status on app launch
                    notificationManager.checkAuthorizationStatus()
                    
                    // Schedule daily maintenance
                    Task {
                        await backgroundTaskManager.scheduleDailyMaintenance()
                    }
                }
        }
        .modelContainer(for: [RoutineLog.self, RoutineSuccess.self])
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            LoggingView()
                .tabItem {
                    Label("Log", systemImage: "pencil.circle.fill")
                }
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
