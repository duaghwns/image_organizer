import SwiftUI
import UniformTypeIdentifiers
// ----------------------------------------------------------------------
// ⚙️ MenuBarView (MenuBarExtra의 내부 뷰)
// ----------------------------------------------------------------------
// (이 파일은 제공되지 않았으나, 메뉴바 기능을 위해 필요하므로 일반적인 형태를 가정합니다.)
struct MenuBarView: View {
    var appDelegate: AppDelegate?

    var body: some View {
        VStack(alignment: .leading) {
            Text("File Organizer")
                .font(.headline)
            
            Divider()
            
            Button("📂 폴더 선택 후 정리...") {
                appDelegate?.selectFolder()
            }
            
            Divider()
            
            Button("⚙️ 설정") {
                appDelegate?.openSettings()
            }
            
            Button("앱 종료") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
