# 切换网关

一个原生 macOS 网关切换器，用于在 `192.168.31.1`、`192.168.31.2` 和 `192.168.31.3` 之间快速切换默认网关。

## 功能

- 显示当前默认网关、本机局域网 IP、网络服务、接口、DNS 和更新时间
- 一键切换到国内网关 `192.168.31.1`
- 一键切换到 `.2 网关` `192.168.31.2`
- 一键切换到代理网关 `192.168.31.3`
- 切换网关时同步写入 DNS：每个网关使用对应的 `192.168.31.x` 地址
- 提供主窗口和菜单栏快捷入口
- 支持安装一次性授权的免密 helper，后续切换不再反复输入密码
- 提供 WidgetKit 小组件源码，可做成桌面小组件按钮

## 运行

```bash
./script/build_and_run.sh
```

也可以在 Codex 里使用项目的 `Run` 动作。现在项目包含 `GatewaySwitcher.xcodeproj`，脚本会优先使用 Xcode 工程构建主 App 和 Widget Extension。

## 说明

应用会写入当前网络服务的手动 IPv4 配置，而不只是临时修改路由表：

```bash
networksetup -setmanual Wi-Fi 192.168.31.42 255.255.255.0 192.168.31.2
networksetup -setdnsservers Wi-Fi 192.168.31.2
```

如果没有安装免密 helper，切换时 macOS 会弹出管理员授权。点击应用里的“安装免密切换”后，会安装：

- `/usr/local/bin/gateway-switcher-helper`
- `/etc/sudoers.d/gateway-switcher`

sudoers 规则只允许当前登录用户免密执行这个 helper。helper 内部限制路由器和 DNS 只能是 `192.168.31.1`、`192.168.31.2` 或 `192.168.31.3`。

## 桌面小组件

小组件源码位于 `Sources/GatewaySwitcherWidget/GatewaySwitcherWidget.swift`。它提供三个按钮：

- 国内网关 `192.168.31.1`
- `.2 网关` `192.168.31.2`
- 代理网关 `192.168.31.3`

项目已经包含 `GatewaySwitcher.xcodeproj`，其中有三个 target：

- `GatewaySwitcher`：主 macOS App
- `GatewayKit`：共享网关切换逻辑
- `GatewaySwitcherWidgetExtension`：桌面小组件扩展

使用 Xcode 打开 `GatewaySwitcher.xcodeproj`，选择 `GatewaySwitcher` scheme 运行。构建出来的 App 会在 `Contents/PlugIns/` 内嵌 `GatewaySwitcherWidgetExtension.appex`，系统就能注册这个桌面小组件。

小组件按钮依赖免密 helper；请先在主 App 中点击“安装免密切换”。
