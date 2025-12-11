[根目录](../CLAUDE.md) > **scripts**

# scripts 模块说明

## 模块职责
- 安装/卸载 macOS LaunchAgent 以常驻运行 copilot-api，生成配置文件与 CLI 链接，并提供日志路径管理。

## 入口与启动
- 安装：
  - `./scripts/install_copilot_agent.sh --dir "<安装目录>" [--account individual|business|enterprise] [--label <名称>] [--log-dir <目录>]`
  - 行为：渲染 plist -> `~/Library/LaunchAgents/<label>.plist`，创建 `config/copilot-switch.conf`，在 `~/bin` 链接 `copilotctl`，重载 launchd。
- 卸载：
  - `./scripts/uninstall_copilot_agent.sh [--label <名称>] [--plist <path>] [--config <path>] [--log-dir <path>] [--remove-logs] [--remove-config] [--remove-cli] [--force]`
  - 行为：`launchctl bootout` + 删除 plist，可选删除日志/配置/CLI。

## 对外接口
- 安装脚本参数：
  | 参数 | 含义 | 默认 |
  | --- | --- | --- |
  | `--dir` | copilot-api 安装目录（WorkingDirectory） | 必填 |
  | `--account` | 默认账户类型 `individual|business|enterprise` | `individual` |
  | `--label` | LaunchAgent Label | `com.zephyrus.copilot-api` |
  | `--log-dir` | 日志目录 | `~/Library/Logs` |
  | `--help` | 显示帮助 | - |
- 卸载脚本参数：
  | 参数 | 含义 | 默认 |
  | --- | --- | --- |
  | `--label` | LaunchAgent Label | config 中 `label` 或 `com.zephyrus.copilot-api` |
  | `--plist` | 指定 plist 路径 | `~/Library/LaunchAgents/<label>.plist` |
  | `--config` | 配置文件路径 | `config/copilot-switch.conf` |
  | `--log-dir` | 日志目录 | `~/Library/Logs` 或 config 中 `log_dir` |
  | `--remove-logs` | 删除日志文件 | false |
  | `--remove-config` | 删除配置文件 | false |
  | `--remove-cli` | 删除 `~/bin/copilotctl`（仅指向本仓库时） | false |
  | `--force` | 跳过确认 | false |
  | `--help` | 显示帮助 | - |
- 输出/副作用：生成/移除 plist、日志文件、配置文件、`~/bin/copilotctl` 链接，并重载 launchd。

## 关键依赖与配置
- 依赖：`bash`、`sed`、`plutil`、`launchctl`、`bun`（启动 copilot-api）。
- 模板：`../templates/com.zephyrus.copilot-api.plist.tmpl`。
- 生成文件：
  - `~/Library/LaunchAgents/<label>.plist`
  - `config/copilot-switch.conf`（key=value）
  - 日志：`~/Library/Logs/<label>.out.log`、`~/Library/Logs/<label>.err.log`
  - CLI 链接：`~/bin/copilotctl`

## 数据模型
- 无结构化数据；配置为简单 `key=value` 文本。

## 测试与质量
- 手动：`plutil -lint ~/Library/LaunchAgents/<label>.plist`，`launchctl print gui/$(id -u)/<label>`，检查日志输出。

## 常见问题 (FAQ)
- 未安装 bun：安装脚本会提示，需先安装 bun 后重启服务。
- `~/bin` 不在 PATH：按安装脚本提示将 `export PATH="$HOME/bin:$PATH"` 加入 shell 配置。
- 自定义 label 后卸载失败：卸载时需带上相同 `--label` 或显式 `--plist`。

## 相关文件清单
- `scripts/install_copilot_agent.sh`
- `scripts/uninstall_copilot_agent.sh`
- 运行期生成：`config/copilot-switch.conf`

## 变更记录
- 2025-12-11T12:27:24+0800 新建模块文档。
