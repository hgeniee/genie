//
//  SettingsView.swift
//  genie
//
//  App settings including buffer time and preferences
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoutineLog.timestamp, order: .reverse) private var logs: [RoutineLog]
    
    @AppStorage("bufferTimeMinutes") private var bufferTimeMinutes: Int = 10
    @AppStorage("highlightOutliers") private var highlightOutliers: Bool = true
    @AppStorage("outlierThresholdMinutes") private var outlierThresholdMinutes: Int = 30
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var analyticsManager = AnalyticsManager()
    @State private var showingPermissionAlert = false
    @State private var pendingNotificationCount: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                // Buffer Time Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundStyle(.blue)
                            Text("Buffer Time")
                                .fontWeight(.semibold)
                        }
                        
                        Text("Extra time added to commute estimates for safety")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Stepper(value: $bufferTimeMinutes, in: 0...60, step: 5) {
                        HStack {
                            Text("Buffer Duration")
                            Spacer()
                            Text("\(bufferTimeMinutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if bufferTimeMinutes > 0 {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("Suggestions will include +\(bufferTimeMinutes) min buffer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Commute Planning")
                }
                
                // Outlier Detection Section
                Section {
                    Toggle(isOn: $highlightOutliers) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Highlight Outliers")
                                    .fontWeight(.semibold)
                            }
                            Text("Show when events differ from your usual pattern")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if highlightOutliers {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Outlier Threshold")
                                .font(.subheadline)
                            
                            Picker("Threshold", selection: $outlierThresholdMinutes) {
                                Text("15 minutes").tag(15)
                                Text("30 minutes").tag(30)
                                Text("45 minutes").tag(45)
                                Text("60 minutes").tag(60)
                            }
                            .pickerStyle(.segmented)
                            
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Events ±\(outlierThresholdMinutes) min from average will be highlighted")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Pattern Analysis")
                } footer: {
                    Text("Outliers help you identify unusual events in your routine, like waking up much earlier or later than normal.")
                }
                
                // Notifications Section
                Section {
                    Toggle(isOn: Binding(
                        get: { notificationManager.isEnabled && notificationsEnabled },
                        set: { newValue in
                            Task {
                                await handleNotificationToggle(enabled: newValue)
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(.purple)
                                Text("Smart Reminders")
                                    .fontWeight(.semibold)
                            }
                            Text("Get notified based on your routine patterns")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if notificationManager.isEnabled && notificationsEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Notifications")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "clock.badge.checkmark")
                                    .foregroundStyle(.green)
                                Text("\(pendingNotificationCount) scheduled")
                                    .font(.subheadline)
                                Spacer()
                                Button("Refresh") {
                                    Task {
                                        await updateNotificationSchedule()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            Button(action: {
                                Task {
                                    await notificationManager.clearDeliveredNotifications()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear Old Notifications")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Text("Reminders are scheduled 5 minutes before suggested times from your routine analysis.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if notificationManager.authorizationStatus == .denied {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Notification Permission Denied")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Text("Please enable notifications in Settings → genie → Notifications")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Smart reminders are based on your routine patterns and help you stay on schedule.")
                }
                
                // About Section
                Section {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.yellow)
                        Text("Version")
                        Spacer()
                        Text("2.0 (Phase 2)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.green)
                        Text("Features")
                        Spacer()
                        Text("Logging + Analytics")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                analyticsManager.updateLogs(logs)
                await updatePendingNotificationCount()
            }
            .onChange(of: logs) { _, newLogs in
                analyticsManager.updateLogs(newLogs)
            }
            .alert("Enable Notifications?", isPresented: $showingPermissionAlert) {
                Button("Enable") {
                    Task {
                        await requestNotificationPermission()
                    }
                }
                Button("Not Now", role: .cancel) {
                    notificationsEnabled = false
                }
            } message: {
                Text("Allow genie to send you smart reminders based on your routine patterns.")
            }
        }
    }
    
    // MARK: - Notification Helpers
    
    private func handleNotificationToggle(enabled: Bool) async {
        if enabled {
            // Check if we have permission
            if notificationManager.authorizationStatus == .notDetermined {
                showingPermissionAlert = true
                return
            } else if notificationManager.authorizationStatus == .authorized {
                notificationsEnabled = true
                await updateNotificationSchedule()
            } else {
                // Permission denied
                notificationsEnabled = false
            }
        } else {
            // Disable notifications
            notificationsEnabled = false
            await notificationManager.clearAllNotifications()
            await updatePendingNotificationCount()
        }
    }
    
    private func requestNotificationPermission() async {
        do {
            let granted = try await notificationManager.requestAuthorization()
            if granted {
                notificationsEnabled = true
                await updateNotificationSchedule()
            } else {
                notificationsEnabled = false
            }
        } catch {
            print("Failed to request notification permission: \(error)")
            notificationsEnabled = false
        }
    }
    
    private func updateNotificationSchedule() async {
        await notificationManager.updateNotificationsIfEnabled(
            analyticsManager: analyticsManager,
            bufferMinutes: bufferTimeMinutes
        )
        await updatePendingNotificationCount()
    }
    
    private func updatePendingNotificationCount() async {
        let pending = await notificationManager.getPendingNotifications()
        await MainActor.run {
            pendingNotificationCount = pending.count
        }
    }
}

// MARK: - Settings Helper

struct AppSettings {
    static var bufferTimeMinutes: Int {
        UserDefaults.standard.integer(forKey: "bufferTimeMinutes") == 0 ? 10 : UserDefaults.standard.integer(forKey: "bufferTimeMinutes")
    }
    
    static var highlightOutliers: Bool {
        UserDefaults.standard.object(forKey: "highlightOutliers") as? Bool ?? true
    }
    
    static var outlierThresholdMinutes: Int {
        let value = UserDefaults.standard.integer(forKey: "outlierThresholdMinutes")
        return value == 0 ? 30 : value
    }
}

#Preview {
    SettingsView()
}
