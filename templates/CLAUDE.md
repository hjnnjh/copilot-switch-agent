[根目录](../CLAUDE.md) > **templates**

# templates 模块说明

## 模块职责
- 提供 macOS LaunchAgent plist 模板，配合安装脚本渲染并启动 copilot-api（通过 bun）。

## 入口与使用
- `templates/com.zephyrus.copilot-api.plist.tmpl` 由安装脚本使用 `sed` 渲染，占位符替换后写入 `~/Library/LaunchAgents/<label>.plist`。

## 对外接口
- 占位符映射表：
  | 占位符 | 描述 | 来源 |
  | --- | --- | --- |
  | `__LABEL__` | LaunchAgent Label | 安装参数 `--label` |
  | `__INSTALL_DIR__` | 工作目录 & `COPILOT_INSTALL_DIR` | 安装参数 `--dir` |
  | `__ACCOUNT_TYPE__` | `COPILOT_ACCOUNT_TYPE` 环境变量 | 安装参数 `--account` |
  | `__PATH_ENV__` | PATH 注入 | 安装脚本内置 PATH_ENV |
  | `__LOG_OUT__` | 标准输出日志路径 | 由 `--log-dir` 派生 |
  | `__LOG_ERR__` | 标准错误日志路径 | 由 `--log-dir` 派生 |

## 关键依赖与配置
- 程序命令：`/bin/bash -c "cd \"__INSTALL_DIR__\" && export PATH=\"__PATH_ENV__\" && exec bun run start start -a \"$COPILOT_ACCOUNT_TYPE\""`。
- 属性：`KeepAlive` 与 `RunAtLoad` 启用，日志路径独立配置。
- 依赖：`bun` 运行 copilot-api；渲染后使用 `plutil -lint` 校验。

## 数据模型
- plist 文件，无额外数据模型。

## 测试与质量
- 渲染后执行 `plutil -lint ~/Library/LaunchAgents/<label>.plist`。
- 启动后检查日志文件是否写入。

## 常见问题 (FAQ)
- PATH 中缺少 bun：更新 PATH_ENV 或安装 bun 到模板 PATH 覆盖的目录。
- 安装目录权限不足：会导致 launchctl 启动失败，需确保可读写与可执行。

## 相关文件清单
- `templates/com.zephyrus.copilot-api.plist.tmpl`

## 变更记录
- 2025-12-11T12:27:24+0800 新建模块文档。
