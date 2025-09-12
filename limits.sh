#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 权限运行此脚本"
    exit 1
fi

# 备份现有的 limits.conf 文件
LIMITS_CONF="/etc/security/limits.conf"
if [ -f "$LIMITS_CONF" ]; then
    cp "$LIMITS_CONF" "$LIMITS_CONF.bak"
    echo "已备份 $LIMITS_CONF 到 $LIMITS_CONF.bak"
fi

# 添加限制配置到 limits.conf
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

# 检查 systemd 用户限制（针对 nproc）
SYSTEMD_CONF="/etc/systemd/system.conf"
if [ -f "$SYSTEMD_CONF" ]; then
    cp "$SYSTEMD_CONF" "$SYSTEMD_CONF.bak"
    echo "已备份 $SYSTEMD_CONF 到 $SYSTEMD_CONF.bak"
    sed -i '/^#DefaultLimitNPROC=/c\DefaultLimitNPROC=unlimited' "$SYSTEMD_CONF"
    sed -i '/^DefaultLimitNOFILE=/c\DefaultLimitNOFILE=1048576' "$SYSTEMD_CONF"
    sed -i '/^DefaultLimitMEMLOCK=/c\DefaultLimitMEMLOCK=unlimited' "$SYSTEMD_CONF"
    echo "已更新 $SYSTEMD_CONF 中的限制"
fi

# 检查 systemd 用户限制（针对登录用户）
USER_CONF="/etc/systemd/user.conf"
if [ -f "$USER_CONF" ]; then
    cp "$USER_CONF" "$USER_CONF.bak"
    echo "已备份 $USER_CONF 到 $USER_CONF.bak"
    sed -i '/^#DefaultLimitNPROC=/c\DefaultLimitNPROC=unlimited' "$USER_CONF"
    sed -i '/^DefaultLimitNOFILE=/c\DefaultLimitNOFILE=1048576' "$USER_CONF"
    sed -i '/^DefaultLimitMEMLOCK=/c\DefaultLimitMEMLOCK=unlimited' "$USER_CONF"
    echo "已更新 $USER_CONF 中的限制"
fi

# 确保 pam_limits 模块启用
PAM_FILES=("/etc/pam.d/common-session" "/etc/pam.d/common-session-noninteractive")
for PAM_FILE in "${PAM_FILES[@]}"; do
    if [ -f "$PAM_FILE" ] && ! grep -q "pam_limits.so" "$PAM_FILE"; then
        echo "session required pam_limits.so" >> "$PAM_FILE"
        echo "已在 $PAM_FILE 中启用 pam_limits.so"
    fi
done

# 重启 systemd 以应用更改
systemctl daemon-reload
echo "已重新加载 systemd 配置"

# 提示用户重启
echo "配置已完成！请重启系统以应用更改。"
echo "验证命令: ulimit -a"
```
