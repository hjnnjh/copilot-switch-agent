# copilot-switch-agent

macOS 上管理 [copilot-api](https://github.com/ericc-ch/copilot-api) 后台服务的工具集，基于 launchd LaunchAgent 实现服务常驻运行。

## 功能特性

- 🚀 **一键安装**：自动配置 LaunchAgent，开机自启动 copilot-api 服务
- 🔄 **账户切换**：支持 individual/business/enterprise 三种 GitHub Copilot 账户类型
- 📁 **多目录管理**：可在多个 copilot-api 安装目录间快速切换
- 📊 **使用量查询**：查看 GitHub Copilot 配额使用情况
- 🛠 **CLI 工具**：`copilotctl` 命令行工具管理服务生命周期

## 依赖

- macOS（需要 launchd）
- [bun](https://bun.sh)（用于运行 copilot-api）
- [copilot-api](https://github.com/ericc-ch/copilot-api)（需预先安装）

## 安装

### 运行安装脚本

```bash
./scripts/install_copilot_agent.sh \
  --dir <copilot-api安装目录> \
  --account <账户类型>
```

**参数说明**：

| 参数 | 必填 | 说明 | 默认值 |
|------|------|------|--------|
| `--dir` | ✅ | copilot-api 安装目录 | - |
| `--account` | ❌ | 账户类型：`individual`/`business`/`enterprise` | `individual` |
| `--label` | ❌ | LaunchAgent 标识符 | `com.zephyrus.copilot-api` |
| `--log-dir` | ❌ | 日志目录 | `~/Library/Logs` |

**示例**：

```bash
# 使用 business 账户安装
./scripts/install_copilot_agent.sh \
  --dir "$HOME/.copilot-api-adv/copilot-api" \
  --account business
```

### 配置 PATH（可选）

安装后 `copilotctl` 被链接到 `~/bin/copilotctl`。如果 `~/bin` 不在 PATH 中，添加以下行到 `~/.zshrc`：

```bash
export PATH="$HOME/bin:$PATH"
```

## CLI 命令文档

### 命令列表

| 命令 | 说明 |
|------|------|
| `start` | 启动服务（渲染 plist 并 bootstrap） |
| `stop` | 停止服务（bootout） |
| `restart` | 重启服务 |
| `status` | 查看服务运行状态 |
| `switch` | 切换账户类型或安装目录 |
| `login` | 执行 GitHub 认证，成功后自动重启 |
| `check-usage` | 查看 GitHub Copilot 使用量统计 |
| `logs` | 查看服务日志 |
| `list` | 列出已知目录和当前配置 |
| `config` | 查看或修改配置 |
| `heal` | 自检：bun/目录/plist/日志权限 |
| `help` | 显示帮助信息 |

### 常用命令示例

```bash
# 查看服务状态
copilotctl status

# 切换账户类型
copilotctl switch --account business

# 切换安装目录（会自动重载服务）
copilotctl switch --dir ~/.copilot-api-v2/copilot-api

# 同时切换目录和账户
copilotctl switch --dir ~/.copilot-api-v2 --account enterprise

# GitHub 认证登录
copilotctl login

# 查看 Copilot 使用量
copilotctl check-usage

# 查看实时日志
copilotctl logs -f

# 查看错误日志
copilotctl logs err

# 列出所有已知安装目录
copilotctl list

# 查看当前配置
copilotctl config show

# 修改配置项
copilotctl config set default_account_type individual

# 健康检查
copilotctl heal
```

## 配置说明

### 配置文件

配置文件位于项目目录下：`config/copilot-switch.conf`

```ini
default_install_dir=/path/to/copilot-api
default_account_type=business
known_install_dirs=/path/to/copilot-api,/path/to/another
log_dir=/Users/xxx/Library/Logs
label=com.zephyrus.copilot-api
```

| 配置项 | 说明 |
|--------|------|
| `default_install_dir` | 当前使用的 copilot-api 目录 |
| `default_account_type` | 当前账户类型 |
| `known_install_dirs` | 历史使用过的目录列表（逗号分隔） |
| `log_dir` | 日志文件存放目录 |
| `label` | LaunchAgent 标识符 |

### 文件位置

| 文件 | 路径 |
|------|------|
| LaunchAgent plist | `~/Library/LaunchAgents/<label>.plist` |
| 标准输出日志 | `<log_dir>/<label>.out.log` |
| 错误输出日志 | `<log_dir>/<label>.err.log` |
| CLI 工具 | `~/bin/copilotctl`（符号链接） |

## 卸载

```bash
./scripts/uninstall_copilot_agent.sh [选项]
```

**选项**：

| 选项 | 说明 |
|------|------|
| `--label <name>` | 指定 LaunchAgent 标识符 |
| `--remove-logs` | 同时删除日志文件 |
| `--remove-config` | 同时删除配置文件 |
| `--remove-cli` | 同时删除 `~/bin/copilotctl` 链接 |
| `--force` | 跳过确认提示 |

**示例**：

```bash
# 默认卸载（仅停止服务并删除 plist）
./scripts/uninstall_copilot_agent.sh

# 完全卸载（包括日志、配置、CLI）
./scripts/uninstall_copilot_agent.sh --remove-logs --remove-config --remove-cli --force
```

## 项目结构

```
copilot-switch-agent/
├── bin/
│   └── copilotctl              # CLI 工具
├── scripts/
│   ├── install_copilot_agent.sh    # 安装脚本
│   └── uninstall_copilot_agent.sh  # 卸载脚本
├── templates/
│   └── com.zephyrus.copilot-api.plist.tmpl  # plist 模板
└── config/
    └── copilot-switch.conf     # 运行时配置（.gitignore）
```

## License

MIT
