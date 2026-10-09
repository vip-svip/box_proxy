# Box Proxy

一个基于 **KernelSU** 的代理平台模块，界面与体验仿 **Shadowrocket**：内置 mihomo 内核，支持在线模块库、节点导入、多协议节点、实时流量统计、黑白/深色主题。

> 版本策略：功能未达到“完美”前，一律写 **v1.0.0**。

## 特性

- **内置内核**：mihomo v1.18.8（arm64）+ geoip 数据，离线即可启动，无需安装时联网。
- **零预置**：`configs/` 默认完全为空，首次启动自动生成空白直连配置，绝不覆盖你的数据。
- **仿 Shadowrocket 模块系统**：在线模块库（广告拦截 / 国内直连 / 国外代理 / AI 服务 / Telegram / 流媒体 / 微软直连 / 局域网直连），一键安装、启停、规则合并，也支持从 URL 直接安装。
- **节点导入**
  - 在线订阅：自动识别 **Clash/mihomo YAML**、**base64 节点列表**、**明文节点列表**三种格式。
  - 手动粘贴：支持 `vmess` / `vless` / `trojan` / `ss` / `ssr` / `hysteria2` / `hysteria` / `tuic` / `socks5` / `http`。
- **节点测速与选优**：基于内核 API 一键测速、自动选优、手动切换。
- **WebUI**：首页 / 配置 / 模块 / 节点 / 设置，黑白配色 + 深色模式。
- **实用工具**：实时流量统计、在线更新订阅、备份/恢复、检查模块更新、查看出口 IP、配置语法检查。
- **本地文件默认全空**：支持导入本地文件、粘贴配置文本、WebUI 内编辑保存。

## 目录结构

```
box_proxy/
├── module.prop          # 模块声明
├── customize.sh         # 安装脚本（内置内核、目录留空、默认自启）
├── service.sh           # 开机自启服务
├── action.sh            # KSU 按钮：一键启停
├── uninstall.sh         # 卸载
├── bin/
│   ├── manager.sh       # 核心管理脚本
│   └── fetch_core.sh    # 内核下载（多镜像回退，可选）
├── cores/               # 内置内核（打包时包含，仓库源码包排除）
│   ├── mihomo
│   └── geoip.dat
├── templates/base.yaml  # 空白基础模板（纯直连）
├── online/              # 在线资源（模块库索引 / 模块规则 / 更新清单）
│   ├── index.json
│   ├── update.json
│   ├── changelog.md
│   └── modules/*.yaml
├── webroot/             # WebUI
│   ├── index.html
│   ├── style.css
│   └── app.js
└── update.json          # 仓库根在线更新清单
```

## 安装

1. 已安装 **KernelSU**。
2. KernelSU 管理器 → 模块 → 从本地安装 → 选择 `box_proxy-v1.0.0.zip`。
3. 重启手机（内核已内置，无需联网）。
4. 打开 WebUI（KernelSU 模块页 → 打开）→ 导入节点/订阅 → 启动。

## 运行时路径

| 路径 | 说明 |
|------|------|
| `/data/adb/boxproxy/configs/` | 配置文件（默认空） |
| `/data/adb/boxproxy/modules/` | 已安装模块规则 |
| `/data/adb/boxproxy/subscriptions/` | 订阅地址记录 |
| `/data/adb/boxproxy/state.json` | WebUI 应用状态（模块/订阅/节点） |
| `/data/adb/boxproxy/run/mihomo.log` | 运行日志 |
| `/data/adb/boxproxy/active` | 当前激活配置名 |

## 在线资源

- 模块库索引：`https://raw.githubusercontent.com/vip-svip/box_proxy/main/online/index.json`
- 更新清单：`https://raw.githubusercontent.com/vip-svip/box_proxy/main/update.json`

## 免责声明

仅供学习与技术研究使用，请在法律允许范围内使用，使用后果自负。
