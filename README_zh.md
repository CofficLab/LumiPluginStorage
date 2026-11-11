# LumiPluginStorage

📖 [中文版](README_zh.md) | [English](README.md)

Lumi 及其兄弟应用共享的存储超级插件。

本包暴露 `PluginStorage` product 与模块，因此现有宿主可继续使用：

```swift
import PluginStorage
```

它提供：

- `StorageSuperPlugin`：在内核启动期间注册 `StorageProviding`；
- `StorageService`：限定插件与核心数据目录的作用域；
- `StoragePathResolver`：在旧宿主采用内核生命周期前，向其暴露相同的根目录约定；
- Application Support 下稳定的默认根目录，按 bundle ID 与调试/生产大版本目录分隔。

存储契约仍位于
[`LumiProviders`](https://github.com/lumi-softworks/LumiProviders)，本包拥有
默认实现与生命周期注册。

## Swift Package 集成

```swift
dependencies: [
    .package(url: "https://github.com/lumi-softworks/LumiPluginStorage.git", from: "1.0.0")
]
```

然后将 `PluginStorage` 加入 target 依赖，并在宿主的插件工厂中包含
`try StorageSuperPlugin()`。

需要自定义或测试根目录的宿主可以使用：

```swift
try StorageSuperPlugin(dataRootDirectory: customRoot)
```

如果宿主已注册 `StorageProviding` 实现，共享插件会保留它。

## Development

```sh
swift test
```
