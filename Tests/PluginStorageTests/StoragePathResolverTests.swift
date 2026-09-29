import Foundation
import Testing
@testable import PluginStorage

/// Deterministic coverage of `StoragePathResolver` using fixture bundles,
/// instead of relying on the test runner's main bundle.
///
/// `swift test` builds the Debug configuration, so the resolver emits the
/// `db_debug_v<N>` naming below.
@Suite("StoragePathResolver")
struct StoragePathResolverTests {

    @Test
    func usesBundleIdentifierAndMajorVersion() throws {
        let fixture = try makeFixtureBundle(identifier: "com.example.fixture-app", version: "2.7.1")
        defer { try? FileManager.default.removeItem(at: fixture.directory) }

        let root = try StoragePathResolver.defaultDataRootDirectory(
            bundle: fixture.bundle,
            fallbackBundleID: "com.example.fallback",
            fallbackMajorVersion: 9
        )
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(root.path.contains("/com.example.fixture-app/"))
        #expect(root.lastPathComponent.hasPrefix("db_debug_v"), "Debug 构建应使用 db_debug_v 前缀")
        #expect(root.lastPathComponent.hasSuffix("_v2"), "主版本应从 CFBundleShortVersionString 解析")
        #expect(isExistingDirectory(root), "解析器应创建数据根目录")
    }

    @Test
    func handlesMultiDigitMajorVersion() throws {
        let fixture = try makeFixtureBundle(identifier: "com.example.multi", version: "10.3.0")
        defer { try? FileManager.default.removeItem(at: fixture.directory) }

        let root = try StoragePathResolver.defaultDataRootDirectory(
            bundle: fixture.bundle,
            fallbackBundleID: "com.example.fallback",
            fallbackMajorVersion: 1
        )
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(root.lastPathComponent.hasSuffix("_v10"))
    }

    @Test
    func fallsBackToBundleIDWhenBundleHasNoIdentifier() throws {
        let fixture = try makeFixtureBundle(identifier: nil, version: "1.0")
        defer { try? FileManager.default.removeItem(at: fixture.directory) }

        let root = try StoragePathResolver.defaultDataRootDirectory(
            bundle: fixture.bundle,
            fallbackBundleID: "com.example.fallback",
            fallbackMajorVersion: 3
        )
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(root.path.contains("/com.example.fallback/"))
    }

    @Test
    func fallsBackToMajorVersionWhenBundleHasNoVersion() throws {
        let fixture = try makeFixtureBundle(identifier: "com.example.noversion", version: nil)
        defer { try? FileManager.default.removeItem(at: fixture.directory) }

        let root = try StoragePathResolver.defaultDataRootDirectory(
            bundle: fixture.bundle,
            fallbackBundleID: "com.example.fallback",
            fallbackMajorVersion: 7
        )
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(root.lastPathComponent.hasSuffix("_v7"), "缺少版本时应使用 fallbackMajorVersion")
    }

    @Test
    func ignoresNonNumericVersion() throws {
        let fixture = try makeFixtureBundle(identifier: "com.example.badversion", version: "beta")
        defer { try? FileManager.default.removeItem(at: fixture.directory) }

        let root = try StoragePathResolver.defaultDataRootDirectory(
            bundle: fixture.bundle,
            fallbackBundleID: "com.example.fallback",
            fallbackMajorVersion: 5
        )
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(root.lastPathComponent.hasSuffix("_v5"), "非数字版本应回退到 fallbackMajorVersion")
    }

    // MARK: - Helpers

    private struct FixtureBundle {
        let bundle: Bundle
        let directory: URL
    }

    /// Builds a minimal on-disk bundle (`Contents/Info.plist`) with the given
    /// identifier and short version string.
    private func makeFixtureBundle(
        identifier: String?,
        version: String?
    ) throws -> FixtureBundle {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StoragePathResolverFixture-\(UUID().uuidString)", isDirectory: true)
        let contents = directory.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)

        var infoPlist: [String: Any] = ["CFBundlePackageType": "BNDL"]
        if let identifier {
            infoPlist["CFBundleIdentifier"] = identifier
        }
        if let version {
            infoPlist["CFBundleShortVersionString"] = version
        }
        let data = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))

        let bundle = try #require(Bundle(path: directory.path))
        return FixtureBundle(bundle: bundle, directory: directory)
    }
}
