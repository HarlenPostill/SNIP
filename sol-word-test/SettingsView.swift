import SwiftUI

struct SettingsView: View {
  @ObservedObject var store: GameStore
  @Environment(\.dismiss) private var dismiss
  @State private var denied = false
  @State private var reset = false
  @State private var showPrivacy = false
  var body: some View {
    NavigationStack {
      Form {
        Section("A little atmosphere") {
          Toggle("Snip sound", isOn: Binding(get: { store.settings.sound }, set: store.setSound))
          Toggle(
            "Haptic feedback", isOn: Binding(get: { store.settings.haptics }, set: store.setHaptics)
          )
        }
        Section {
          Toggle(
            "Daily reminder",
            isOn: Binding(
              get: { store.settings.reminders },
              set: { value in Task { if !(await store.setReminders(value)) { denied = true } } }))
          if store.settings.reminders {
            DatePicker(
              "Remind me at",
              selection: Binding(
                get: { reminderTime },
                set: { date in
                  let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                  Task { await store.setReminderTime(hour: c.hour ?? 19, minute: c.minute ?? 0) }
                }), displayedComponents: .hourAndMinute)
          }
        } header: {
          Text("A small daily pleasure")
        } footer: {
          Text(
            "An optional local reminder, at your chosen time. New editions arrive at midnight UTC.")
        }
        Section("The studio") {
          Button("Privacy policy") { showPrivacy = true }
          Link(
            "Contact support",
            destination: URL(string: "mailto:harlen.interactive@gmail.com?subject=SNIP%20support")!)
          HStack {
            Text("Version")
            Spacer()
            Text("1.0 (1)").foregroundStyle(Studio.quiet)
          }
          Text("2026 HRLN interactive").foregroundStyle(Studio.quiet)
        }
        Section {
          Button("Reset my progress", role: .destructive) { reset = true }
        } footer: {
          Text(
            "Deletes daily results and practice progress from this device. Your sound and reminder preferences stay as they are."
          )
        }
      }.scrollContentBackground(.hidden).background(Studio.paper).navigationTitle("Your studio")
        .navigationBarTitleDisplayMode(.inline).toolbar {
          ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
        .alert("Reminders are switched off", isPresented: $denied) {
          Button("Open Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
          }
          Button("Keep them off", role: .cancel) {}
        } message: {
          Text("You can allow notifications for SNIP in iPhone Settings whenever you'd like.")
        }
        .alert("Reset your cuts?", isPresented: $reset) {
          Button("Reset progress", role: .destructive) {
            store.resetProgress()
            dismiss()
          }
          Button("Cancel", role: .cancel) {}
        } message: {
          Text("Your saved results on this device will be deleted.")
        }
        .sheet(isPresented: $showPrivacy) { PrivacyView() }
    }.tint(Studio.red).preferredColorScheme(.light)
  }
  private var reminderTime: Date {
    Calendar.current.date(
      bySettingHour: store.settings.reminderHour, minute: store.settings.reminderMinute, second: 0,
      of: Date()) ?? Date()
  }
}
struct PrivacyView: View {
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Text("Your words stay\nwith you.").font(Studio.serif(35, italic: true))
          Text(
            "SNIP does not collect or transmit your gameplay, identifiers, or device information. There are no accounts, advertisements, analytics SDKs, or tracking."
          )
          Text(
            "Progress and preferences are stored locally on your device. Your device's operating system may include this data in a backup, according to your backup settings. Reset progress in Settings to remove game results, or delete the app to remove its local data."
          )
          Text(
            "Reminders are optional local notifications. Sharing opens the iOS share sheet; the result card and text go only to the destination you choose. Other apps and websites have their own privacy policies."
          )
          Text(
            "If you email support, HRLN interactive receives the information you choose to include and uses it to respond to you. Please avoid sending sensitive information."
          )
          Link(
            "harlen.interactive@gmail.com",
            destination: URL(string: "mailto:harlen.interactive@gmail.com")!)
          Text("2026 HRLN interactive · Updated 14 October 2026").font(.caption).foregroundStyle(
            Studio.quiet)
        }.font(.body).lineSpacing(4).padding(27)
      }.background(Studio.paper).navigationTitle("Privacy").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }.tint(Studio.red).preferredColorScheme(.light)
  }
}
