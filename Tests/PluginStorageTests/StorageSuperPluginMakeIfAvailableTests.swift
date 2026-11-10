import Foundation
import KernelCore
import ProviderStorage
import Testing
@testable import PluginStorage

/// Contract tests for `StorageSuperPlugin.makeIfAvailable()`: the host-facing
/// factory helper that must never terminate the process when the plugin
/// cannot be created.
@Suite("StorageSuperPlugin.makeIfAvailable")
struct StorageSuperPluginMakeIfAvailableTests {

    @Test @MainActor
    func returnsPluginWhenBuilderSucceeds() throws {
        let root = makeTemporaryDirectory("StoragePluginMakeIfAvailableSuccess")
        defer { try? FileManager.default.removeItem(at: root) }

        let plugin = StorageSuperPlugin.makeIfAvailable {
            try StorageSuperPlugin(dataRootDirectory: root)
        }

        #expect(plugin != nil)
        #expect(plugin?.dataRootDirectory == root.standardizedFileURL)
    }

    @Test @MainActor
    func returnsNilWhenBuilderThrows() {
        struct Boom: Error {}

        let plugin = StorageSuperPlugin.makeIfAvailable {
            throw Boom()
        }

        #expect(plugin == nil, "创建失败时应返回 nil，而不是终止进程")
    }
}
