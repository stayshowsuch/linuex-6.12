#!/bin/bash

# 设置变量
DEB_URL="https://github.com/stayshowsuch/linuex-6.12/raw/a02d205022b6b64d6b3b4e36112af7ba59c2c33f/linux-image-6.12.46_6.12.46-4_amd64.deb"
DEB_FILE="linux-image-6.12.46_6.12.46-4_amd64.deb"
TEMP_DIR="/tmp"
DOWNLOAD_PATH="$TEMP_DIR/$DEB_FILE"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 错误退出函数
error_exit() {
    log "错误: $1"
    exit 1
}

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    error_exit "此脚本需要 root 权限运行"
fi

# 检查网络连接
log "检查网络连接..."
if ! ping -c 1 github.com > /dev/null 2>&1; then
    error_exit "无法连接到 GitHub，请检查网络"
fi

# 创建临时目录（如果不存在）
mkdir -p "$TEMP_DIR" || error_exit "无法创建临时目录 $TEMP_DIR"

# 下载 .deb 文件
log "正在下载 $DEB_FILE ..."
if ! curl -L -o "$DOWNLOAD_PATH" "$DEB_URL" --retry 3 --retry-delay 5; then
    error_exit "下载 $DEB_FILE 失败"
fi

# 检查文件是否存在
if [ ! -f "$DOWNLOAD_PATH" ]; then
    error_exit "下载的文件 $DOWNLOAD_PATH 不存在"
fi

# 检查文件大小（确保文件非空）
FILE_SIZE=$(stat -c %s "$DOWNLOAD_PATH" 2>/dev/null || stat -f %z "$DOWNLOAD_PATH" 2>/dev/null)
if [ "$FILE_SIZE" -lt 1000 ]; then
    error_exit "下载的文件 $DEB_FILE 太小，可能下载失败"
fi

# 安装 .deb 文件
log "正在安装 $DEB_FILE ..."
if ! dpkg -i "$DOWNLOAD_PATH"; then
    log "dpkg 安装失败，尝试修复依赖..."
    if ! apt-get install -f -y; then
        error_exit "无法修复依赖，安装失败"
    fi
fi

# 更新 GRUB 配置
log "更新 GRUB 配置..."
if ! update-grub; then
    error_exit "更新 GRUB 配置失败"
fi

# 清理下载的 .deb 文件
log "清理临时文件..."
rm -f "$DOWNLOAD_PATH" || log "警告: 无法删除 $DOWNLOAD_PATH"

# 提示用户重启
log "内核安装完成，即将重启系统..."
log "请保存所有未保存的工作，系统将在 10 秒后重启"
sleep 10

# 执行重启
log "正在重启系统..."
reboot
