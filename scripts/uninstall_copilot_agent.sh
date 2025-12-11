#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_LABEL="com.zephyrus.copilot-api"
DEFAULT_LOG_DIR="$HOME/Library/Logs"
CONFIG_DEFAULT="$BASE_DIR/config/copilot-switch.conf"

usage(){
  cat <<'EOF'
卸载 copilot-api LaunchAgent（默认保守：仅 bootout + 删除 plist）

参数：
  --label <name>       LaunchAgent Label（默认 com.zephyrus.copilot-api，可被 config 覆盖）
  --plist <path>       指定 plist 路径（默认 ~/Library/LaunchAgents/<label>.plist）
  --config <path>      配置文件路径（默认 $BASE_DIR/config/copilot-switch.conf）
  --log-dir <path>     日志目录（默认 ~/Library/Logs 或 config 中的 log_dir）
  --remove-logs        删除日志文件 <log-dir>/<label>.out.log / <label>.err.log
  --remove-config      删除配置文件
  --remove-cli         删除 ~/bin/copilotctl（仅当 realpath 指向 $BASE_DIR/bin/copilotctl）
  --force              跳过确认
  --help               显示本帮助
EOF
}

echo_err(){ printf '错误: %s\n' "$*" >&2; }

echo_info(){ printf '%s\n' "$*"; }

load_config(){
  LABEL="$DEFAULT_LABEL"
  LOG_DIR="$DEFAULT_LOG_DIR"
  CONFIG="$CONFIG_DEFAULT"
  if [[ -n "${CONFIG_OVERRIDE:-}" ]]; then
    CONFIG="$CONFIG_OVERRIDE"
  fi
  if [[ -f "$CONFIG" ]]; then
    while IFS='=' read -r k v; do
      [[ -z "$k" || "$k" =~ ^# ]] && continue
      case "$k" in
        label) LABEL="$v" ;;
        log_dir) LOG_DIR="$v" ;;
      esac
    done < "$CONFIG"
  fi
}

canonical(){ cd "$1" && pwd; }

parse_args(){
  REMOVE_LOGS=false
  REMOVE_CONFIG=false
  REMOVE_CLI=false
  FORCE=false
  CONFIG_OVERRIDE=""
  PLIST_OVERRIDE=""
  LABEL_OVERRIDE=""
  LOGDIR_OVERRIDE=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --label) LABEL_OVERRIDE="$2"; shift 2;;
      --plist) PLIST_OVERRIDE="$2"; shift 2;;
      --config) CONFIG_OVERRIDE="$2"; shift 2;;
      --log-dir) LOGDIR_OVERRIDE="$2"; shift 2;;
      --remove-logs) REMOVE_LOGS=true; shift;;
      --remove-config) REMOVE_CONFIG=true; shift;;
      --remove-cli) REMOVE_CLI=true; shift;;
      --force) FORCE=true; shift;;
      --help) usage; exit 0;;
      *) echo_err "未知参数 $1"; usage; exit 1;;
    esac
  done
}

resolve_paths(){
  [[ -n "$LABEL_OVERRIDE" ]] && LABEL="$LABEL_OVERRIDE"
  [[ -n "$LOGDIR_OVERRIDE" ]] && LOG_DIR="$LOGDIR_OVERRIDE"
  LOG_DIR="$(canonical "$LOG_DIR")"
  if [[ -n "$PLIST_OVERRIDE" ]]; then
    PLIST_PATH="$(canonical "$(dirname "$PLIST_OVERRIDE")")/$(basename "$PLIST_OVERRIDE")"
  else
    PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
  fi
}

confirm(){
  $FORCE && return 0
  echo "即将执行卸载："
  echo "- launchctl bootout gui/$(id -u)/$LABEL"
  echo "- 删除 plist: $PLIST_PATH"
  $REMOVE_LOGS && echo "- 删除日志: $LOG_DIR/$LABEL.out.log, $LOG_DIR/$LABEL.err.log"
  $REMOVE_CONFIG && echo "- 删除配置: $CONFIG"
  $REMOVE_CLI && echo "- 删除 CLI: $HOME/bin/copilotctl (若指向本仓库)"
  read -r -p "确认继续? [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo_err "已取消"; exit 2; }
}

bootout(){
  launchctl bootout gui/$(id -u)/"$LABEL" >/dev/null 2>&1 || true
}

remove_plist(){ rm -f "$PLIST_PATH"; }

remove_logs(){
  local out="$LOG_DIR/$LABEL.out.log"
  local err="$LOG_DIR/$LABEL.err.log"
  rm -f "$out" "$err"
}

remove_config(){ rm -f "$CONFIG"; }

remove_cli(){
  local dst="$HOME/bin/copilotctl"
  if [[ -e "$dst" ]]; then
    local target
    if target=$(realpath "$dst" 2>/dev/null); then
      if [[ "$target" == "$BASE_DIR/bin/copilotctl" ]]; then
        rm -f "$dst"
      else
        echo_info "跳过删除 ~/bin/copilotctl（指向其他路径: $target）"
      fi
    else
      echo_info "跳过删除 ~/bin/copilotctl（无法解析 realpath）"
    fi
  fi
}

main(){
  parse_args "$@"
  load_config
  [[ -n "$LABEL_OVERRIDE" ]] && LABEL="$LABEL_OVERRIDE"
  [[ -n "$LOGDIR_OVERRIDE" ]] && LOG_DIR="$LOGDIR_OVERRIDE"
  [[ -n "$PLIST_OVERRIDE" ]] && PLIST_PATH="$PLIST_OVERRIDE"
  # 规范化
  LOG_DIR="$(canonical "$LOG_DIR")"
  if [[ -n "${PLIST_PATH:-}" ]]; then
    PLIST_PATH="$(canonical "$(dirname "$PLIST_PATH")")/$(basename "$PLIST_PATH")"
  else
    PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
  fi

  confirm
  bootout
  remove_plist
  $REMOVE_LOGS && remove_logs
  $REMOVE_CONFIG && remove_config
  $REMOVE_CLI && remove_cli

  echo_info "✓ 卸载完成 (label=$LABEL)"
  echo_info "若需完全清理，请按需手动删除安装目录/其他文件。"
}

main "$@"
