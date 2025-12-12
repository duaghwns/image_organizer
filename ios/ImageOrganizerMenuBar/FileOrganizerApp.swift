import Cocoa
import SwiftUI
import Combine
import UserNotifications
import UniformTypeIdentifiers

// AppDelegate는 UserSettings가 정의되어 있다고 가정합니다.
// class UserSettings: ObservableObject { ... }

@main
struct FileOrganizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("File Organizer", systemImage: "camera.fill") {
            MenuBarView(appDelegate: appDelegate)
        }
        .menuBarExtraStyle(.menu)
    }
}
// ----------------------------------------------------------------------
// 🖥️ AppDelegate - 파일 정리 로직 및 드롭존 관리 수정 반영
// ----------------------------------------------------------------------

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var settingsWindow: NSWindow?

    // ✅ UserSettings는 외부에서 정의되었다고 가정합니다.
    @Published var settings = UserSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermission()

        // 프로그램 실행 시 설정창 자동으로 열기
        DispatchQueue.main.async {
            self.openSettings()
        }
    }
    
    // --- 파일 정리 로직 (Swift 네이티브) ---
    func processFolder(url: URL) {
        print("Processing folder: \(url.path)")
        print("Settings: organizationMode=\(settings.organizationMode), mode=\(settings.mode), dateFormat=\(settings.dateFormat)")

        FileOrganizer.organizeFiles(inputDir: url, settings: settings) { result in
            switch result {
            case .success(let count):
                print("Successfully organized \(count) files")
                self.showNotification(
                    title: "파일 정리 완료",
                    body: "폴더 \(url.lastPathComponent)에서 \(count)개 파일이 정리되었습니다."
                )
            case .failure(let error):
                print("Error organizing files: \(error)")
                self.showAlert(message: "파일 정리 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }

    func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView(settings: settings, appDelegate: self)
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 750),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.contentView = NSHostingView(rootView: contentView)
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.title = "정리할 폴더 선택"

        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                processFolder(url: url)
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "알림"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}




// ⚠️ UserSettings 클래스는 외부에서 정의되어야 합니다. (예시)
class UserSettings: ObservableObject {
    @Published var mode: Int = 1 // 1: 기존, 2: 번호, 3: 날짜
    @Published var baseName: String = ""
    @Published var organizationMode: Int = 0 // 0: 확장자별 폴더로 정리, 1: 셀렉한 파일 찾기, 2: 20MB 이하 파일만 모아보기
    @Published var dateFormat: Int = 0 // 0: 사용안함, 1: YYYYMM, 2: YYYY/MM, 3: YYYY/MM/DD, 4: YYYY-MM-DD
}
