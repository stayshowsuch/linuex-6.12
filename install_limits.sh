#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 权限运行此脚本"
    exit 1
fi

# ========== limits.conf ==========
LIMITS_CONF="/etc/security/limits.conf"
if [ -f "$LIMITS_CONF" ]; then
    cp -n "$LIMITS_CONF" "$LIMITS_CONF.bak"
    echo "已备份 $LIMITS_CONF 到 $LIMITS_CONF.bak"

    # 删除旧配置
    sed -i '/nofile/d' "$LIMITS_CONF"
    sed -i '/nproc/d' "$LIMITS_CONF"
    sed -i '/memlock/d' "$LIMITS_CONF"
    sed -i '/stack/d' "$LIMITS_CONF"
    sed -i '/core/d' "$LIMITS_CONF"

    # 追加新配置
    cat << EOF >> "$LIMITS_CONF"
# 自定义限制设置
* soft nofile 1048576
* hard nofile 1048576
* soft nproc unlimited
* hard nproc unlimited
* soft memlock unlimited
* hard memlock unlimited
* soft stack 1048576
* hard stack 1048576
* soft core unlimited
* hard core unlimited
EOF
    echo "已更新 $LIMITS_CONF 中的限制"
fi

# ========== system.conf ==========
SYSTEMD_CONF="/etc/systemd/system.conf"
if [ -f "$SYSTEMD_CONF" ]; then
    cp -n "$SYSTEMD_CONF" "$SYSTEMD_CONF.bak"
    echo "已备份 $SYSTEMD_CONF 到 $SYSTEMD_CONF.bak"

    # 删除旧配置
    sed -i '/^DefaultLimitNOFILE/d' "$SYSTEMD_CONF"
    sed -i '/^DefaultLimitNPROC/d' "$SYSTEMD_CONF"
    sed -i '/^DefaultLimitMEMLOCK/d' "$SYSTEMD_CONF"

    # 追加新配置
    cat << EOF >> "$SYSTEMD_CONF"
DefaultLimitNOFILE=1048576
DefaultLimitNOFILESoft=1048576
DefaultLimitNPROC=unlimited
DefaultLimitNPROCSoft=unlimited
DefaultLimitMEMLOCK=unlimited
DefaultLimitMEMLOCKSoft=unlimited
EOF
    echo "已更新 $SYSTEMD_CONF 中的限制"
fi

# ========== user.conf ==========
USER_CONF="/etc/systemd/user.conf"
if [ -f "$USER_CONF" ]; then
    cp -n "$USER_CONF" "$USER_CONF.bak"
    echo "已备份 $USER_CONF 到 $USER_CONF.bak"

    # 删除旧配置
    sed -i '/^DefaultLimitNOFILE/d' "$USER_CONF"
    sed -i '/^DefaultLimitNPROC/d' "$USER_CONF"
    sed -i '/^DefaultLimitMEMLOCK/d' "$USER_CONF"

    # 追加新配置
    cat << EOF >> "$USER_CONF"
DefaultLimitNOFILE=1048576
DefaultLimitNOFILESoft=1048576
DefaultLimitNPROC=unlimited
DefaultLimitNPROCSoft=unlimited
DefaultLimitMEMLOCK=unlimited
DefaultLimitMEMLOCKSoft=unlimited
EOF
    echo "已更新 $USER_CONF 中的限制"
fi

# ========== pam_limits ==========
PAM_FILES=("/etc/pam.d/common-session" "/etc/pam.d/common-session-noninteractive")
for PAM_FILE in "${PAM_FILES[@]}"; do
    if [ -f "$PAM_FILE" ] && ! grep -q "pam_limits.so" "$PAM_FILE"; then
        echo "session required pam_limits.so" >> "$PAM_FILE"
        echo "已在 $PAM_FILE 中启用 pam_limits.so"
    fi
done

# 重新加载 systemd 配置
systemctl daemon-reexec
systemctl daemon-reload
echo "已重新加载 systemd 配置"

# 提示用户重启
echo "配置已完成！请重启系统以应用更改。"
echo "验证命令: ulimit -a && systemctl show | grep Limit"
