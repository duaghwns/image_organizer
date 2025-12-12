import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settings: UserSettings
    var appDelegate: AppDelegate?

    @State private var isTargeted: Bool = false // 설정 뷰 드롭 영역 상태

    var body: some View {
        Form {

            // 🖼️ 파일명 선택 섹션
            Section(header: Text("파일명 설정")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .textCase(nil)) {
                Picker("", selection: $settings.mode) {
                    Text("기존 파일명 유지").tag(1)
                    Text("번호로 부여").tag(2)
                    Text("날짜로 부여").tag(3)
                }
                .pickerStyle(.segmented)
                .disabled(settings.organizationMode != 0)

                VStack(alignment: .leading, spacing: 5) {
                    TextField("", text: $settings.baseName, prompt: Text("예: MyImage"))
                        .disabled(settings.mode == 1 || settings.organizationMode != 0)

                    if settings.mode == 2 {
                        Text("예시: \(settings.baseName.isEmpty ? "MyImage" : settings.baseName)_1.jpg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if settings.mode == 3 {
                        Text("예시: \(settings.baseName.isEmpty ? "MyImage" : settings.baseName)_20250625_1.jpg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Color.clear.frame(height: 15)
                    }
                }
                .frame(height: 60)
                .opacity(settings.organizationMode != 0 ? 0.5 : 1.0)
            }

            // 🗂️ 정리 방식 선택 섹션 (라디오 버튼)
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { settings.organizationMode = 0 }) {
                        HStack {
                            Image(systemName: settings.organizationMode == 0 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(settings.organizationMode == 0 ? .accentColor : .secondary)
                            VStack(alignment: .leading) {
                                Text("확장자별 폴더로 정리")
                                Text(".JPG, .CR3 등 확장자별로 폴더에 정리합니다.").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { settings.organizationMode = 1 }) {
                        HStack {
                            Image(systemName: settings.organizationMode == 1 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(settings.organizationMode == 1 ? .accentColor : .secondary)
                            VStack(alignment: .leading) {
                                Text("셀렉한 파일 찾기")
                                Text("JPG 파일명과 같은 RAW 파일을 별도 폴더에 정리합니다.").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { settings.organizationMode = 2 }) {
                        HStack {
                            Image(systemName: settings.organizationMode == 2 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(settings.organizationMode == 2 ? .accentColor : .secondary)
                            VStack(alignment: .leading) {
                                Text("20MB 이하 파일만 모아보기")
                                Text("20MB 이하의 파일들을 별도 폴더에 정리합니다.").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("정리 방식 선택")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .textCase(nil)
            }

            // 📅 날짜 폴더 포맷 섹션
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { settings.dateFormat = 0 }) {
                        HStack {
                            Image(systemName: settings.dateFormat == 0 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(settings.dateFormat == 0 ? .accentColor : .secondary)
                            Text("사용 안 함")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(settings.organizationMode != 0)

                    Button(action: { settings.dateFormat = 1 }) {
                        HStack {
                            Image(systemName: settings.dateFormat == 1 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(settings.dateFormat == 1 ? .accentColor : .secondary)
                            VStack(alignment: .leading) {
                                Text("YYYYMM")
                                Text("예: 202506").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(settings.organizationMode != 0)

                    Button(action: { settings.dateFormat = 2 }) {
                        HStack {
                            Image(systemName: settings.dateFormat == 2 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(settings.dateFormat == 2 ? .accentColor : .secondary)
                            VStack(alignment: .leading) {
                                Text("YYYY/MM")
                                Text("예: 2025/06").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(settings.organizationMode != 0)

                    Button(action: { settings.dateFormat = 3 }) {
                        HStack {
                            Image(systemName: settings.dateFormat == 3 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(settings.dateFormat == 3 ? .accentColor : .secondary)
                            VStack(alignment: .leading) {
                                Text("YYYY/MM/DD")
                                Text("예: 2025/06/25").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(settings.organizationMode != 0)

                    Button(action: { settings.dateFormat = 4 }) {
                        HStack {
                            Image(systemName: settings.dateFormat == 4 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(settings.dateFormat == 4 ? .accentColor : .secondary)
                            VStack(alignment: .leading) {
                                Text("YYYY-MM-DD")
                                Text("예: 2025-06-25").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(settings.organizationMode != 0)
                }
                .opacity(settings.organizationMode != 0 ? 0.5 : 1.0)
            } header: {
                Text("날짜 폴더 포맷 선택")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .textCase(nil)
            }

            // 📥 설정 창 내 드롭 영역 (디자인 개선)
            Section {
                VStack(spacing: 8) {
                    Image(systemName: isTargeted ? "arrow.down.doc.fill" : "arrow.down.doc")
                        .font(.system(size: 40))
                        .foregroundColor(isTargeted ? .white : .accentColor)

                    Text("📂 폴더를 드롭하여 정리 시작")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isTargeted ? .white : .primary)

                    Text("드래그하여 놓으면 설정에 따라 즉시 정리됩니다.")
                        .font(.caption)
                        .foregroundColor(isTargeted ? .white.opacity(0.8) : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isTargeted ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                        .shadow(radius: isTargeted ? 8 : 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isTargeted ? Color.white.opacity(0.8) : Color.gray.opacity(0.5),
                                style: StrokeStyle(lineWidth: isTargeted ? 3 : 1, dash: isTargeted ? [] : [5]))
                )
                // 드래그 앤 드롭 구현
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) }) {
                        _ = provider.loadObject(ofClass: URL.self) { url, error in
                            if let url = url, url.hasDirectoryPath {
                                DispatchQueue.main.async {
                                    appDelegate?.processFolder(url: url)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    appDelegate?.showAlert(message: "폴더만 드롭할 수 있습니다.")
                                }
                            }
                        }
                        return true
                    }
                    return false
                }
            }

            // 📂 폴더 선택 버튼 섹션
            Section {
                HStack {
                    Spacer()
                    Button {
                        appDelegate?.selectFolder()
                    } label: {
                        Text("📂 파일 선택 창 열기")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)

        }
        .frame(minWidth: 400, idealWidth: 450, idealHeight: 650)
        .padding()
        .navigationTitle("File Organizer")

        // 💡 하단 정보 및 링크
        VStack(spacing: 5) {
            Divider()

            Link("Instagram: @duaghwns", destination: URL(string: "https://www.instagram.com/duaghwns/")!)
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}
