#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$BASE_DIR/templates/com.zephyrus.copilot-api.plist.tmpl"
CONFIG="$BASE_DIR/config/copilot-switch.conf"
DEFAULT_LABEL="com.zephyrus.copilot-api"
DEFAULT_ACCOUNT="individual"
DEFAULT_LOG_DIR="$HOME/Library/Logs"
PATH_ENV="$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
VALID_TYPES="individual business enterprise"

usage() {
  cat <<'EOF'
安装/部署 copilot-api LaunchAgent

参数：
  --dir <path>       必填，copilot-api 安装目录（WorkingDirectory）
  --account <type>   默认账户类型 individual|business|enterprise（默认 individual）
  --label <name>     LaunchAgent Label（默认 com.zephyrus.copilot-api）
  --log-dir <path>   日志目录（默认 ~/Library/Logs，文件名为 <label>.out/err.log）
  --help             显示本帮助
示例：
  scripts/install_copilot_agent.sh --dir "$HOME/.copilot-api-adv/copilot-api" --account individual
EOF
}

escape_sed() { printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'; }

echo_err() { printf '错误: %s\n' "$*" >&2; }

INSTALL_DIR=""
LABEL="$DEFAULT_LABEL"
ACCOUNT="$DEFAULT_ACCOUNT"
LOG_DIR="$DEFAULT_LOG_DIR"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) INSTALL_DIR="$2"; shift 2;;
    --account) ACCOUNT="$2"; shift 2;;
    --label) LABEL="$2"; shift 2;;
    --log-dir) LOG_DIR="$2"; shift 2;;
    --help) usage; exit 0;;
    *) echo_err "未知参数 $1"; usage; exit 1;;
  esac
done

if [[ -z "$INSTALL_DIR" ]]; then
  echo_err "必须指定 --dir <安装目录>"; usage; exit 1
fi

# 规范化路径
INSTALL_DIR="$(cd "$INSTALL_DIR" && pwd)"
LOG_DIR="$(cd "$LOG_DIR" && pwd)"

# 校验账户类型
ok=false
for t in $VALID_TYPES; do
  [[ "$ACCOUNT" == "$t" ]] && ok=true && break
done
if [[ "$ok" != true ]]; then
  echo_err "账户类型必须为 individual|business|enterprise 之一"; exit 1
fi

# 校验目录与依赖
[[ -d "$INSTALL_DIR" ]] || { echo_err "安装目录不存在: $INSTALL_DIR"; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo_err "模板不存在: $TEMPLATE"; exit 1; }
command -v bun >/dev/null 2>&1 || {
  echo "警告: 未找到 bun，启动时可能失败；请先安装 bun (https://bun.sh)。"
}

mkdir -p "$LOG_DIR"
mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$BASE_DIR/config"

# 安装/链接 copilotctl 到 ~/bin，便于全局调用
mkdir -p "$HOME/bin"
CTL_SRC="$BASE_DIR/bin/copilotctl"
CTL_DST="$HOME/bin/copilotctl"
if ! ln -sf "$CTL_SRC" "$CTL_DST" 2>/dev/null; then
  cp "$CTL_SRC" "$CTL_DST"
fi

PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_OUT="$LOG_DIR/$LABEL.out.log"
LOG_ERR="$LOG_DIR/$LABEL.err.log"

# 渲染 plist
sed \
  -e "s/__LABEL__/$(escape_sed "$LABEL")/g" \
  -e "s#__INSTALL_DIR__#$(escape_sed "$INSTALL_DIR")#g" \
  -e "s#__ACCOUNT_TYPE__#$(escape_sed "$ACCOUNT")#g" \
  -e "s#__LOG_OUT__#$(escape_sed "$LOG_OUT")#g" \
  -e "s#__LOG_ERR__#$(escape_sed "$LOG_ERR")#g" \
  -e "s#__PATH_ENV__#$(escape_sed "$PATH_ENV")#g" \
  "$TEMPLATE" > "$PLIST_PATH"

plutil -lint "$PLIST_PATH" >/dev/null

cat > "$CONFIG" <<EOF
default_install_dir=$INSTALL_DIR
default_account_type=$ACCOUNT
known_install_dirs=$INSTALL_DIR
log_dir=$LOG_DIR
label=$LABEL
EOF

# 重载 launchd
launchctl bootout gui/$(id -u) "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl bootstrap gui/$(id -u) "$PLIST_PATH"

# PATH 提示
NEED_PATH_HINT=1
case ":$PATH:" in
  *":$HOME/bin:"*) NEED_PATH_HINT=0;;
esac

cat <<EOF
✓ 安装完成
- 配置文件: $CONFIG
- LaunchAgent: $PLIST_PATH
- WorkingDirectory: $INSTALL_DIR
- 默认账户: $ACCOUNT
- 日志: $LOG_OUT / $LOG_ERR
- copilotctl 可执行: $CTL_DST
$( [ $NEED_PATH_HINT -eq 1 ] && echo "提示: 将以下行加入 shell 配置以直接调用 copilotctl\n  export PATH=\"\$HOME/bin:\$PATH\"" )

建议执行首次登录:
  copilotctl login
查看状态:
  copilotctl status
查看帮助:
  copilotctl --help
EOF
