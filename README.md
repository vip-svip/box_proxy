# Box Proxy —— KernelSU 在线订阅代理模块 (v1.1.0)

对标 iOS Shadowrocket 的 Android/KernelSU 实现，**内置 mihomo 内核**，开箱即用。

## 本版变化 (v1.1.0)
- **内置 mihomo 内核（arm64）与 geoip 数据**：安装后无需联网下载内核，直接可用
- 本地配置列表清空，仅内置 `fanqie-lite`（番茄小说去广告 + 国内直连）
- WebUI 新增 **导入本地文件**、**自定义编辑**、**新建配置**
- 原始 Shadowrocket 配置保留于 `reference/fanqie-lite.conf`

## 一、安装
1. 手机已装 **KernelSU**（或 KernelSU-Next / APatch 的 KernelSU 模式）。
2. KernelSU 管理器 → 模块 → 从本地安装 → 选 `box_proxy-v1.1.0.zip`。
3. 重启手机。内核已内置，无需联网即可启动。

## 二、WebUI 功能（复刻 Shadowrocket 配置页）
- **配置**：恢复默认 / 从在线地址导入 / **导入本地文件** / **新建配置** / 在线更新全部 / 测试规则 + 本地文件列表
- **本地文件**：点文件名启用；点 `i` 可 **编辑 / 在线更新 / 重命名 / 删除**
- **首页**：启停代理、状态、内核版本、配置数
- **数据**：代理开关、出口 IP 检测、运行日志
- **设置**：开机自启、更新内核、在线资源地址、原始配置参考、日志

### 导入本地文件
配置页点「导入本地文件」→ 选手机里的 `.yaml/.conf/.txt` → 自动写入模块配置目录并出现在列表。

### 自定义编辑
文件详情点「编辑」→ 页面内直接改内容 → 保存（通过 base64 分块写入，见 `manager.sh` 的 `write-*` 命令）。

## 三、内置配置说明
`configs/fanqie-lite.yaml` 由 Shadowrocket 配置转换而来：
- **已移植**：番茄小说去广告 `REJECT` 规则、`GEOIP,CN,DIRECT`、`MATCH,DIRECT`
- **未移植（内核不支持）**：原配置的 `[URL Rewrite]` 与 `[Script]`(wloc 定位脚本) 依赖 Shadowrocket 的 JS 引擎，mihomo 无法执行；原始文件见 `reference/fanqie-lite.conf`

## 四、命令行（可选）
```sh
MG=/data/adb/modules/box_proxy/bin/manager.sh
sh $MG list | use <n> | delete <n> | rename <a> <b>
sh $MG read <n>          # 读配置
sh $MG new <n>           # 新建
sh $MG import <url> [n]  # 在线导入
sh $MG update-all        # 在线更新全部
sh $MG start|stop|toggle # 启停
sh $MG status | logs 120
sh $MG core-install      # (可选)更新内核
sh $MG autostart on|off
sh $MG reset             # 恢复 fanqie-lite
```

## 五、在线能力
- **在线导入配置**：WebUI「从在线地址导入」填订阅 URL
- **在线资源索引**：设置填 `online/index.json` 地址，列出资源一键导入
- **模块在线更新**：`module.prop` 的 `updateJson` 指向仓库根的 `update.json`

运行时数据目录：`/data/adb/boxproxy/`（configs / cores / run / reference）

## 免责声明
仅供学习与技术研究，请在法律允许范围内使用，使用后果自负。
