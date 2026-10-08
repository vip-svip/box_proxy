# Box Proxy —— KernelSU 在线订阅代理模块

对标 iOS Shadowrocket 的 Android/KernelSU 实现：**在线地址导入配置**、多配置槽位切换、一键启停、开机自启、WebUI 管理面板、TUN 全局代理。

内核使用 [mihomo (Clash.Meta)](https://github.com/MetaCubeX/mihomo)，规则/订阅格式与 Clash 生态完全兼容，可直接吃 Shadowrocket 转换出来的 Clash YAML 订阅。

---

## 一、安装

1. 手机已安装 **KernelSU**（或 KernelSU-Next / APatch 兼容管理器的 KernelSU 模式）。
2. 用 KernelSU 管理器 → 模块 → 从本地安装 → 选择 `box_proxy-v1.0.0.zip`。
3. 安装脚本会自动联网下载 mihomo 内核（含国内镜像回退）。若下载失败，重装后在 WebUI「设置 → 下载/更新内核」重试。
4. 重启手机。

## 二、在线地址 / 在线导入（核心功能）

本模块的"在线地址"有两种含义，正好覆盖你的需求：

### 1) 在“在线地址里导入模块” —— 在线订阅导入
打开模块 **WebUI → 配置 → 导入…**，在输入框粘贴任意在线地址：

- Clash / mihomo `yaml` 订阅链接
- Shadowrocket 转出来的 Clash 配置直链
- 你自己的自建订阅地址

点“导入”后，模块会：下载 → 校验非空 → 保存为本地配置槽位 → 记录来源 URL（用于后续一键在线更新）。

### 2) 在线资源索引（把在线地址做成列表页）
**WebUI → 模块 / 设置 → 在线资源地址**，填入一个 JSON 索引地址（见 `online/index.json` 示例）。页面会读取该在线地址并列出所有可用资源，点“导入此地址”即可逐个把在线配置/规则集导入本地。

### 3) 模块自身的在线更新
`module.prop` 里的 `updateJson` 指向在线 JSON（见 `online/update.json`）。把工程推到你的 GitHub 仓库后，KernelSU 管理器会读取它并提示在线更新模块。

## 三、WebUI 使用

在 KernelSU 管理器里点模块的 WebUI 按钮即可打开。界面复刻 Shadowrocket 配置页：

- **配置页**：恢复默认配置 / 导入…（在线地址）/ Wi-Fi 上传·在线更新全部 / 模块 / 测试规则 + 本地文件列表（勾选=当前启用，`i` 查看详情/更新/重命名/删除）
- **首页**：启停代理、状态、内核版本、配置数
- **数据**：代理开关、出口 IP 检测、运行日志
- **设置**：开机自启、下载/更新内核、在线资源地址、日志

## 四、命令行（可选）

```sh
MG=/data/adb/modules/box_proxy/bin/manager.sh
sh $MG list                 # 列出本地配置
sh $MG import <url> [name]  # 在线导入
sh $MG update-all           # 在线更新全部订阅
sh $MG use <name>           # 切换启用配置
sh $MG start|stop|toggle    # 启停
sh $MG status               # 状态
sh $MG logs 120             # 日志
sh $MG core-install         # 下载/更新 mihomo 内核
sh $MG autostart on|off     # 开机自启
sh $MG reset                # 恢复默认
```

## 五、目录结构

```
box_proxy/
├── module.prop          # 模块声明 + updateJson(在线更新)
├── customize.sh         # 安装脚本（建目录、下载内核）
├── service.sh           # 开机自启服务
├── action.sh            # KSU action 按钮：一键启停
├── uninstall.sh
├── template.yaml        # 默认 mihomo 配置模板
├── bin/
│   ├── manager.sh       # 核心管理脚本（被 WebUI/service 调用）
│   └── fetch_core.sh    # 内核下载（多镜像回退）
├── webroot/             # WebUI（KSU 会注入 kernelsu.exec 桥）
│   ├── index.html
│   ├── style.css
│   └── app.js
└── online/
    ├── update.json      # 模块在线更新清单
    ├── index.json       # 在线资源索引
    └── modules/         # 在线规则集示例
```

## 六、注意事项

- 运行时数据在 `/data/adb/boxproxy/`（配置、内核、日志）。
- TUN 模式需要内核支持；若启动失败看「数据 → 运行日志」。
- `updateJson` / `online/index.json` 里的 `yourname` 需替换成你的 GitHub 用户名和仓库。
- 本模块仅做本地代理配置管理与内核调度，不内置任何节点，请自行使用合法合规的订阅地址。

## 七、免责声明

仅供学习与技术研究。请在法律允许的范围内使用，不得用于任何违法用途。使用本模块产生的全部后果由使用者自行承担。
