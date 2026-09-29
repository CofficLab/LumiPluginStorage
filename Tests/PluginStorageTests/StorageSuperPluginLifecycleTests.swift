import Foundation
import KernelCore
import ProviderStorage
import Testing
@testable import PluginStorage

/// Lifecycle contract tests for `StorageSuperPlugin`: metadata invariants,
/// idempotent boot, root standardization, and the default-root path.
@Suite("StorageSuperPlugin lifecycle")
struct StorageSuperPluginLifecycleTests {

    @Test @MainActor
    func exposesStableMetadataInvariants() throws {
        let plugin = try StorageSuperPlugin(dataRootDirectory: makeTemporaryDirectory("StoragePluginMetadataTests"))

        #expect(plugin.id == "com.coffic.lumi.plugin.storage")
        #expect(plugin.metadata.id == plugin.id)
        #expect(plugin.order == 1, "存储插件应先于其他插件启动")
        #expect(plugin.metadata.category == .system)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.metadata.policy == .alwaysOn)
    }

    @Test @MainActor
    func bootIsIdempotentAndKeepsFirstService() throws {
        let root = makeTemporaryDirectory("StoragePluginDoubleBootTests")
        defer { try? FileManager.default.removeItem(at: root) }

        let plugin = try StorageSuperPlugin(dataRootDirectory: root)
        let kernel = KernelCoreContainer()

        try plugin.onBoot(kernel: kernel)
        let first = try #require(kernel.resolveProvider((any StorageProviding).self))

        try plugin.onBoot(kernel: kernel)
        let second = try #require(kernel.resolveProvider((any StorageProviding).self))

        #expect(first === second, "重复 boot 不应替换已注册的服务")
        #expect(first.dataRootDirectory == root.standardizedFileURL)
    }

    @Test @MainActor
    func standardizesInjectedDataRoot() throws {
        let base = makeTemporaryDirectory("StoragePluginStandardizationTests")
        defer { try? FileManager.default.removeItem(at: base) }

        let messy = base
            .appendingPathComponent("..", isDirectory: true)
            .appendingPathComponent(base.lastPathComponent, isDirectory: true)

        let plugin = try StorageSuperPlugin(dataRootDirectory: messy)

        #expect(plugin.dataRootDirectory == base.standardizedFileURL)
    }

    @Test @MainActor
    func defaultInitResolvesARealDataRoot() throws {
        let plugin = try StorageSuperPlugin()

        #expect(plugin.dataRootDirectory.lastPathComponent.hasPrefix("db_"))
        #expect(isExistingDirectory(plugin.dataRootDirectory))
    }
}
