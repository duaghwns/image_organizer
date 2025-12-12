import Foundation
import AppKit

class FileOrganizer {

    // MARK: - File Extensions

    private static let rawExtensions = ["CR2", "CR3", "nef", "ARW", "orf", "rw2", "dng", "pef"]
    private static let jpgExtensions = ["jpg", "jpeg", "heic", "heif", "hiff"]

    // MARK: - File Organization

    /// 폴더 내 파일을 설정에 따라 정리
    static func organizeFiles(
        inputDir: URL,
        settings: UserSettings,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 보안 범위 접근 시작
            let didStartAccessing = inputDir.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    inputDir.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let fileManager = FileManager.default
                let files = try fileManager.contentsOfDirectory(
                    at: inputDir,
                    includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey],
                    options: [.skipsHiddenFiles]
                )

                var processedCount = 0
                var sequenceNum = 1

                // 파일 정렬 (파일명 기준)
                let sortedFiles = files.sorted { $0.lastPathComponent < $1.lastPathComponent }

                // 셀렉한 파일 찾기: JPG 파일명 목록 수집 (organizationMode == 1일 때만)
                var jpgFileNames = Set<String>()
                if settings.organizationMode == 1 {
                    for fileURL in sortedFiles {
                        let ext = fileURL.pathExtension.lowercased()
                        if jpgExtensions.contains(ext) {
                            let nameWithoutExt = fileURL.deletingPathExtension().lastPathComponent
                            jpgFileNames.insert(nameWithoutExt)
                        }
                    }
                }

                for fileURL in sortedFiles {
                    // 각 파일에 대해 보안 범위 접근 시작
                    let fileDidStartAccessing = fileURL.startAccessingSecurityScopedResource()
                    defer {
                        if fileDidStartAccessing {
                            fileURL.stopAccessingSecurityScopedResource()
                        }
                    }

                    // 디렉토리는 스킵
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                        guard resourceValues.isRegularFile == true else { continue }
                    } catch {
                        // 파일 접근 권한 오류 처리
                        print("파일 접근 권한 오류: \(fileURL.lastPathComponent) - \(error.localizedDescription)")

                        // 메인 스레드에서 알림 표시
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "파일 접근 권한이 필요합니다"
                            alert.informativeText = "'\(fileURL.lastPathComponent)' 파일에 접근할 수 없습니다.\n\n시스템 환경설정 > 보안 및 개인 정보 보호 > 파일 및 폴더에서 앱에 대한 권한을 확인해주세요."
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "확인")
                            alert.addButton(withTitle: "시스템 환경설정 열기")

                            let response = alert.runModal()
                            if response == .alertSecondButtonReturn {
                                // 시스템 환경설정 열기
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                        continue
                    }

                    let filename = fileURL.lastPathComponent
                    let ext = fileURL.pathExtension.lowercased()

                    // 정리 대상 파일인지 확인
                    let isRaw = rawExtensions.contains(ext)
                    let isJpg = jpgExtensions.contains(ext)

                    // 기본 필터: 이미지 파일만 처리
                    if !(isRaw || isJpg) { continue }

                    // 파일 크기 확인 (20MB = 20 * 1024 * 1024 bytes)
                    var fileSize: Int64 = 0
                    do {
                        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                        fileSize = attributes[.size] as? Int64 ?? 0
                    } catch {
                        print("Error getting file size for \(filename): \(error)")
                    }

                    let isSmallFile = fileSize <= 20 * 1024 * 1024

                    // 파일 생성 날짜 가져오기
                    guard let creationDate = getCreationDate(for: fileURL) else {
                        print("Skipping \(filename): Could not determine date.")
                        continue
                    }

                    // 대상 폴더 경로 설정
                    let nameWithoutExt = fileURL.deletingPathExtension().lastPathComponent
                    let isSelectedRaw = (settings.organizationMode == 1) && isRaw && jpgFileNames.contains(nameWithoutExt)

                    let targetFolder = determineTargetFolder(
                        inputDir: inputDir,
                        creationDate: creationDate,
                        fileExtension: ext,
                        isRaw: isRaw,
                        isJpg: isJpg,
                        isSmallFile: isSmallFile,
                        isSelectedRaw: isSelectedRaw,
                        settings: settings
                    )

                    // 대상 폴더 생성
                    try fileManager.createDirectory(at: targetFolder, withIntermediateDirectories: true)

                    // 새 파일명 결정 (organizationMode == 0일 때만 파일명 변경)
                    let newFilename = determineNewFilename(
                        originalFilename: filename,
                        fileExtension: ext,
                        creationDate: creationDate,
                        sequenceNum: &sequenceNum,
                        isSelectedRaw: isSelectedRaw,
                        isSmallFile: isSmallFile && settings.organizationMode == 2,
                        settings: settings
                    )

                    // 파일 이동 및 충돌 처리
                    let destURL = try moveFile(
                        from: fileURL,
                        to: targetFolder,
                        newFilename: newFilename
                    )

                    print("Moved: \(filename) -> \(destURL.path)")
                    processedCount += 1
                }

                DispatchQueue.main.async {
                    completion(.success(processedCount))
                }

            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// 파일 생성 날짜 가져오기
    private static func getCreationDate(for url: URL) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.creationDate] as? Date
        } catch {
            print("Error getting creation date for \(url.path): \(error)")
            return nil
        }
    }

    /// 대상 폴더 경로 결정
    private static func determineTargetFolder(
        inputDir: URL,
        creationDate: Date,
        fileExtension: String,
        isRaw: Bool,
        isJpg: Bool,
        isSmallFile: Bool,
        isSelectedRaw: Bool,
        settings: UserSettings
    ) -> URL {
        var targetFolder = inputDir

        // organizationMode에 따른 분기 처리
        switch settings.organizationMode {
        case 0: // 확장자별 폴더로 정리
            // 날짜 기반 상위 폴더
            var dateFolderComponent: String?
            switch settings.dateFormat {
            case 1: // YYYYMM
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMM"
                dateFolderComponent = formatter.string(from: creationDate)

            case 2: // YYYY/MM
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy"
                let year = formatter.string(from: creationDate)
                formatter.dateFormat = "MM"
                let month = formatter.string(from: creationDate)
                targetFolder = targetFolder.appendingPathComponent(year)
                dateFolderComponent = month

            case 3: // YYYY/MM/DD
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy"
                let year = formatter.string(from: creationDate)
                formatter.dateFormat = "MM"
                let month = formatter.string(from: creationDate)
                formatter.dateFormat = "dd"
                let day = formatter.string(from: creationDate)
                targetFolder = targetFolder.appendingPathComponent(year).appendingPathComponent(month)
                dateFolderComponent = day

            case 4: // YYYY-MM-DD
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                dateFolderComponent = formatter.string(from: creationDate)

            default:
                break
            }

            if let dateFolder = dateFolderComponent {
                targetFolder = targetFolder.appendingPathComponent(dateFolder)
            }

            // 확장자별 폴더
            let categoryFolder = fileExtension.uppercased()
            targetFolder = targetFolder.appendingPathComponent(categoryFolder)

        case 1: // 셀렉한 파일 찾기
            if isSelectedRaw {
                targetFolder = targetFolder.appendingPathComponent("Selected_RAW")
            }

        case 2: // 20MB 이하 파일만 모아보기
            if isSmallFile {
                targetFolder = targetFolder.appendingPathComponent("Under_20MB")
            }

        default:
            break
        }

        return targetFolder
    }

    /// 새 파일명 결정
    private static func determineNewFilename(
        originalFilename: String,
        fileExtension: String,
        creationDate: Date,
        sequenceNum: inout Int,
        isSelectedRaw: Bool,
        isSmallFile: Bool,
        settings: UserSettings
    ) -> String {
        let ext = ".\(fileExtension)"

        // organizationMode가 1(셀렉한 파일 찾기) 또는 2(20MB 이하)일 때는 원본 파일명 유지
        if settings.organizationMode == 1 || settings.organizationMode == 2 {
            return originalFilename
        }

        // organizationMode == 0 (확장자별 폴더로 정리)일 때만 파일명 변경 옵션 적용
        switch settings.mode {
        case 2: // 번호로 파일명 부여
            let baseName = settings.baseName.isEmpty ? "이미지" : settings.baseName
            let filename = "\(baseName)_\(sequenceNum)\(ext)"
            sequenceNum += 1
            return filename

        case 3: // 날짜로 파일명 부여
            let baseName = settings.baseName.isEmpty ? "이미지" : settings.baseName
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            let dateStr = formatter.string(from: creationDate)
            let filename = "\(baseName)_\(dateStr)_\(sequenceNum)\(ext)"
            sequenceNum += 1
            return filename

        default: // 1: 기존 파일명 유지
            return originalFilename
        }
    }

    /// 파일 이동 및 충돌 처리
    private static func moveFile(
        from sourceURL: URL,
        to targetFolder: URL,
        newFilename: String
    ) throws -> URL {
        let fileManager = FileManager.default
        var destURL = targetFolder.appendingPathComponent(newFilename)

        // 파일이 이미 존재하는 경우 충돌 회피: _1, _2 등 추가
        if fileManager.fileExists(atPath: destURL.path) {
            let nameWithoutExt = (newFilename as NSString).deletingPathExtension
            let ext = (newFilename as NSString).pathExtension
            var counter = 1

            while fileManager.fileExists(atPath: destURL.path) {
                let newName = "\(nameWithoutExt)_\(counter).\(ext)"
                destURL = targetFolder.appendingPathComponent(newName)
                counter += 1
            }
            print("Renamed to \(destURL.lastPathComponent) to avoid collision.")
        }

        // 파일 이동
        try fileManager.moveItem(at: sourceURL, to: destURL)
        return destURL
    }
}
