# 切换网关

一个原生 macOS 网关切换器，用于在 `192.168.31.1`、`192.168.31.2` 和 `192.168.31.3` 之间快速切换默认网关。

## 功能

- 显示当前默认网关、本机局域网 IP、网络服务、接口、DNS 和更新时间
- 一键切换到国内网关 `192.168.31.1`
- 一键切换到 `.2 网关` `192.168.31.2`
- 一键切换到代理网关 `192.168.31.3`
- 切换网关时同步写入 DNS
- 提供主窗口和菜单栏快捷入口
- 支持安装一次性授权的免密 helper，后续切换不再反复输入密码
- 支持 URL Scheme 深度链接切换网关（`gatewayswitcher://switch?profile=china`）
- 桌面小组件快速切换

## 构建

```bash
swift build
```

## 运行

```bash
./script/build_and_run.sh          # 构建 .app 并运行
./script/build_and_run.sh --install # 安装到 /Applications 并运行
```

脚本使用 SPM 构建后手动组装 .app bundle，包括嵌入 Widget Extension。

## 在 Xcode 中开发

```bash
xed .
```

Xcode 会从 Package.swift 自动生成项目，无需 .xcodeproj 文件。

## 说明

应用会写入当前网络服务的手动 IPv4 配置，而不只是临时修改路由表：

```bash
networksetup -setmanual Wi-Fi 192.168.31.42 255.255.255.0 192.168.31.2
networksetup -setdnsservers Wi-Fi 192.168.31.2
```

如果没有安装免密 helper，切换时 macOS 会弹出管理员授权。点击应用里的"安装免密切换"后，会安装：

- `/usr/local/bin/gateway-switcher-helper`
- `/etc/sudoers.d/gateway-switcher`

sudoers 规则只允许当前登录用户免密执行这个 helper。helper 内部限制路由器和 DNS 只能是 `192.168.31.1`、`192.168.31.2` 或 `192.168.31.3`。

## 桌面小组件

小组件源码位于 `Sources/GatewaySwitcherWidget/GatewaySwitcherWidget.swift`，通过 `SharedKit` 共享 `WidgetGatewayProfile` 定义。

小组件按钮依赖免密 helper；请先在主 App 中点击"安装免密切换"。

## 项目结构

```
Package.swift              — SPM 项目定义（唯一入口）
Sources/
  GatewayKit/              — 网关切换核心逻辑库
  SharedKit/               — App 与 Widget 共享的类型（WidgetGatewayProfile）
  GatewaySwitcherApp/      — macOS App 入口 + SwiftUI 界面
    Resources/             — Assets.xcassets（应用图标）
  GatewaySwitcherWidget/   — WidgetKit 桌面小组件
Tests/
  GatewayKitTests/         — 单元测试
Config/
  App/Info.plist           — App Info.plist（SPM 不允许作为资源，由构建脚本引用）
  Widget/Info.plist        — Widget Info.plist
script/
  build_and_run.sh         — 构建 .app bundle 并运行
  install_passwordless_helper.sh — 免密 helper 安装脚本
  generate_app_icon.swift  — 图标生成工具
```