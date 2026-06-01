# 切换网关

一个原生 macOS 网关切换器，支持自定义配置网关，可新增、编辑、删除网关 Profile，一键切换默认网关和 DNS。

## 功能

- 显示当前默认网关、本机 IP、网络服务、接口、DNS 和更新时间
- 一键切换到已配置的任意网关
- 支持新增、编辑、删除网关配置（标题、IP、DNS、图标）
- DNS 可独立设置，或默认与网关相同
- 切换网关时同步写入 DNS
- 提供主窗口和菜单栏快捷入口
- 支持免密 helper，后续切换不再反复输入密码
- URL Scheme 深度链接切换（`gatewayswitcher://switch?id=<uuid>`，兼容旧格式 `profile=<rawValue>`）
- 桌面小组件快速切换（最多显示 3 个）

## 构建

```bash
swift build
```

## 运行

```bash
./script/build_and_run.sh          # 构建 .app 并运行
./script/build_and_run.sh --install # 安装到 /Applications 并运行
```

脚本使用 SPM 构建后手动组装 .app bundle，包括嵌入 Widget Extension 和 App Group entitlements。

## 网关配置

应用首次启动时自动创建 3 个默认 Profile：

| 标题 | 网关 IP | DNS |
|------|---------|-----|
| 国内网关 | 192.168.31.1 | 192.168.31.1 |
| .2 关 | 192.168.31.2 | 192.168.31.2 |
| 代理网关 | 192.168.31.3 | 192.168.31.3 |

点击主窗口「管理」按钮或菜单栏「管理网关...」可进入配置页面，支持增删改。

## 说明

应用会写入当前网络服务的手动 IPv4 配置：

```bash
networksetup -setmanual Wi-Fi 192.168.31.42 255.255.255.0 192.168.31.2
networksetup -setdnsservers Wi-Fi 192.168.31.2
```

如果没有安装免密 helper，切换时 macOS 会弹出管理员授权。安装 helper 后：

- `/usr/local/bin/gateway-switcher-helper` — 免密切换 helper
- `/etc/sudoers.d/gateway-switcher` — sudoers 规则
- `/etc/gateway-switcher-allowed-ips.conf` — 允许的 IP 白名单（随 Profile 配置自动更新）

helper 从白名单配置文件读取允许的路由器和 DNS IP，不再硬编码。

## 桌面小组件

小组件通过 App Group 共享数据读取当前 Profile 列表，最多显示 3 个按钮。Profile 变更后自动刷新。

小组件按钮依赖免密 helper；请先在主 App 中点击「安装免密切换」。

## 项目结构

```
GatewaySwitcher
├── Package.swift              — SPM 项目定义（唯一入口）
│
├── GatewaySwitcherApp/        — macOS 主 App（MVVM）
│   ├── App/                   — App 入口（Timer、Deep link 协调）
│   ├── View/                  — SwiftUI 视图
│   ├── ViewModel/             — AppViewModel + ProfileEditorViewModel
│   └── Resources/             — Assets.xcassets
│
├── Packages/                  — Feature 模块（本地 SPM target）
│   ├── Core/                  — 基础设施
│   │   ├── Model/             — GatewayProfile, NetworkSnapshot, GatewayError
│   │   ├── Store/             — ProfileStore（App Group 持久化）
│   │   └── Runner/            — CommandRunning + ProcessCommandRunner
│   ├── SwitcherFeature/       — 网关切换模块
│   │   ├── Service/           — GatewayService（业务编排）
│   │   └── Switcher/          — GatewaySwitcher（shell 命令执行）
│   ├── InspectorFeature/      — 网络检测模块
│   │   ├── Inspector/         — NetworkInspector
│   │   └── Parser/            — RouteParser
│   └── HelperFeature/         — 免密 Helper 模块
│       └── Helper/             — PasswordlessHelper + HelperWhitelistUpdater
│
├── GatewaySwitcherWidget/     — WidgetKit 桌面小组件
│
├── Tests/                     — 按模块分组的单元测试
│   ├── CoreTests/
│   ├── InspectorFeatureTests/
│   ├── SwitcherFeatureTests/
│   └── AppTests/
│
├── Config/                    — 构建配置
│   ├── App/                   — App entitlements + Info.plist
│   └── Widget/                — Widget entitlements + Info.plist
│
└── script/                    — 构建与安装脚本
    ├── build_and_run.sh       — 构建 .app bundle 并运行
    └── install_passwordless_helper.sh — 免密 helper 安装脚本
```

### 依赖图

```
Core ← InspectorFeature ← SwitcherFeature ← GatewaySwitcherApp
Core ← HelperFeature    ← SwitcherFeature
Core ← GatewaySwitcherWidget
```

### 架构

MVVM + Feature 模块化：

- **View**：SwiftUI 视图，只做渲染和绑定
- **ViewModel**：AppViewModel（主状态 + 业务调度）、ProfileEditorViewModel（表单逻辑）
- **Service**：GatewayService 编排切换、检测、安装、白名单同步
- **Model**：GatewayProfile、NetworkSnapshot、ProfileStore