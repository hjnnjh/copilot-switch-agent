# copilot-switch-agent

面向 macOS 的 Copilot API 后台服务安装、启动、切换与卸载脚本集，基于 launchd LaunchAgent。

## 组件概览
- `scripts/install_copilot_agent.sh`：安装/注册 LaunchAgent，渲染 plist，生成配置，链接 `copilotctl` 到 `~/bin`（若可用）。
- `scripts/uninstall_copilot_agent.sh`：卸载 LaunchAgent，按需删除日志/配置/CLI 链接（默认保守只删 plist）。
- `bin/copilotctl`：CLI，支持 start/stop/restart/status/switch/login/logs/list/config/heal。
- `templates/com.zephyrus.copilot-api.plist.tmpl`：LaunchAgent plist 模板。
- `config/copilot-switch.conf`：运行时生成的配置（被 .gitignore）。

## 依赖
- macOS（launchd 可用）
- bun（`~/.bun/bin`，用于运行 `bun run start ...`）

## 安装（注册 LaunchAgent）
```bash
scripts/install_copilot_agent.sh \
  --dir "$HOME/.copilot-api-adv/copilot-api" \
  --account individual \
  [--label com.zephyrus.copilot-api] \
  [--log-dir "$HOME/Library/Logs"]
```
- 结果：生成 `~/Library/LaunchAgents/<label>.plist`，写入 `config/copilot-switch.conf`，并尝试将 `copilotctl` 链接/复制到 `~/bin`。
- 若 PATH 未含 `~/bin`，按提示手动添加：`export PATH="$HOME/bin:$PATH"`。

## CLI 用法（copilotctl）
```bash
copilotctl start|stop|restart|status
copilotctl switch --account <individual|business|enterprise>
copilotctl switch --dir <install_dir>
copilotctl login
copilotctl logs [out|err|all] [-f]
copilotctl list
copilotctl config show
copilotctl config set <key> <value>   # key: default_install_dir|default_account_type|log_dir
copilotctl heal
copilotctl --help
```
- 账户切换不改目录；目录切换会重载服务并更新 WorkingDirectory/env。
- `login` 在当前目录执行 `bun run start auth`，成功后自动重启服务。

## 卸载（保守默认，仅停服务+删 plist）
```bash
scripts/uninstall_copilot_agent.sh \
  [--label com.zephyrus.copilot-api] \
  [--plist ~/Library/LaunchAgents/<label>.plist] \
  [--config config/copilot-switch.conf] \
  [--log-dir ~/Library/Logs] \
  [--remove-logs --remove-config --remove-cli] \
  [--force]
```
- `--remove-cli` 仅在 `~/bin/copilotctl` 指向本仓库 `bin/copilotctl` 时删除。

## 常见路径
- LaunchAgent plist：`~/Library/LaunchAgents/<label>.plist`
- 日志：`<log_dir>/<label>.out.log` / `<label>.err.log`
- 配置：`config/copilot-switch.conf`（运行时生成，已忽略）
- CLI 链接：`~/bin/copilotctl`
