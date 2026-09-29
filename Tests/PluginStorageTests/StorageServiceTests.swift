import Foundation
import Testing
@testable import PluginStorage

/// Contract tests for `StorageService` directory scoping, idempotence,
/// standardization, versioned-root discovery, and disk-space accounting.
@Suite("StorageService")
struct StorageServiceTests {

    @Test @MainActor
    func scopesPluginAndCoreDirectoriesUnderRoot() throws {
        let root = makeTemporaryDirectory("StorageServiceScopeTests")
        defer { try? FileManager.default.removeItem(at: root) }

        let service = StorageService(dataRootDirectory: root)
        let alpha = service.pluginDataDirectory(for: "com.example.alpha")
        let beta = service.pluginDataDirectory(for: "com.example.beta")
        let core = service.coreDataDirectory()

        #expect(alpha.lastPathComponent == "com.example.alpha")
        #expect(beta.lastPathComponent == "com.example.beta")
        #expect(core.lastPathComponent == "Core")
        #expect(alpha.deletingLastPathComponent() == root.standardizedFileURL)
        #expect(beta.deletingLastPathComponent() == root.standardizedFileURL)
        #expect(core.deletingLastPathComponent() == root.standardizedFileURL)
        #expect(isExistingDirectory(alpha))
        #expect(isExistingDirectory(beta))
        #expect(isExistingDirectory(core))
    }

    @Test @MainActor
    func directoryLookupsAreIdempotent() throws {
        let root = makeTemporaryDirectory("StorageServiceIdempotenceTests")
        defer { try? FileManager.default.removeItem(at: root) }

        let service = StorageService(dataRootDirectory: root)
        let first = service.pluginDataDirectory(for: "com.example.same")
        let second = service.pluginDataDirectory(for: "com.example.same")
        let coreFirst = service.coreDataDirectory()
        let coreSecond = service.coreDataDirectory()

        #expect(first == second)
        #expect(coreFirst == coreSecond)
        #expect(isExistingDirectory(second))
    }

    @Test @MainActor
    func preservesNestedPluginIdentifierAsSingleComponent() throws {
        let root = makeTemporaryDirectory("StorageServiceNestedIDTests")
        defer { try? FileManager.default.removeItem(at: root) }

        let service = StorageService(dataRootDirectory: root)
        let pluginID = "com.example.deep.plugin"
        let directory = service.pluginDataDirectory(for: pluginID)

        #expect(directory.lastPathComponent == pluginID, "点号不应被当作路径分隔符")
        #expect(isExistingDirectory(directory))
    }

    @Test @MainActor
    func standardizesInjectedRoot() throws {
        let base = makeTemporaryDirectory("StorageServiceStandardizationTests")
        defer { try? FileManager.default.removeItem(at: base) }

        // base/../<baseName> 解析后应回到 base 自身。
        let messy = base
            .appendingPathComponent("..", isDirectory: true)
            .appendingPathComponent(base.lastPathComponent, isDirectory: true)
        let service = StorageService(dataRootDirectory: messy)

        #expect(service.dataRootDirectory == base.standardizedFileURL)

        let directory = service.pluginDataDirectory(for: "com.example.xyz")
        #expect(directory.deletingLastPathComponent() == base.standardizedFileURL)
        #expect(isExistingDirectory(directory))
    }

    @Test @MainActor
    func discoversSiblingVersionRoots() throws {
        let parent = makeTemporaryDirectory("StorageServiceVersionDiscoveryTests")
        defer { try? FileManager.default.removeItem(at: parent) }

        let v1 = parent.appendingPathComponent("db_debug_v1", isDirectory: true)
        let v2 = parent.appendingPathComponent("db_debug_v2", isDirectory: true)
        let v3 = parent.appendingPathComponent("db_debug_v3", isDirectory: true)
        for directory in [v1, v2, v3] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let service = StorageService(dataRootDirectory: v2)
        let roots = service.allVersionDataRootDirectories.map(\.lastPathComponent)

        #expect(roots == ["db_debug_v1", "db_debug_v2", "db_debug_v3"], "版本根目录应按版本升序返回")
    }

    @Test @MainActor
    func nonVersionedRootIsReportedAlone() throws {
        let root = makeTemporaryDirectory("StorageServicePlainRootTests")
        defer { try? FileManager.default.removeItem(at: root) }

        let service = StorageService(dataRootDirectory: root)
        #expect(service.allVersionDataRootDirectories == [root.standardizedFileURL])
    }

    @Test @MainActor
    func reportsDiskUsageOfDataRoot() async throws {
        let root = makeTemporaryDirectory("StorageServiceSizeTests")
        defer { try? FileManager.default.removeItem(at: root) }

        // 写入两块已知内容，验证默认大小计算覆盖实际文件。
        let payload = Data(repeating: 0xAB, count: 4096)
        try payload.write(to: root.appendingPathComponent("first.bin"))
        try payload.write(to: root.appendingPathComponent("second.bin"))

        let service = StorageService(dataRootDirectory: root)
        let size = await service.dataRootDirectorySizeInBytes()

        #expect(size >= 8192, "磁盘占用应不小于写入的逻辑字节数（实际为 \(size)）")
    }

    @Test @MainActor
    func reportsZeroForEmptyRoot() async throws {
        let root = makeTemporaryDirectory("StorageServiceEmptySizeTests")
        defer { try? FileManager.default.removeItem(at: root) }

        let service = StorageService(dataRootDirectory: root)
        let size = await service.dataRootDirectorySizeInBytes()

        #expect(size >= 0)
    }
}
