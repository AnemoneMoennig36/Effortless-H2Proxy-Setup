#!/bin/bash
# 获取脚本目录
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# 加载 lib.sh
source "$script_dir/lib.sh"
# 检查 config.sh 是否存在，不存在则创建
if [ ! -f config.sh ]; then
    echo "Welcome to the Effortless-H2Proxy-Setup script."
    echo "配置文件 config.sh 不存在，正在创建..."
    cp config.example.sh config.sh
fi

# 加载 config.sh
source config.sh

# 如果变量为空，提示用户填写信息
if [[ "$MY_EMAIL" == "your-email@example.com" || -z "$MY_EMAIL" ]]; then
    echo "配置文件 config.sh 为空，请填写相关信息或选择手动输入。"
    echo "1) 现在输入信息"
    echo "2) 退出并手动编辑 config.sh"

    read -p "请选择 [1/2]: " choice

    if [ "$choice" == "2" ]; then
        echo "请手动编辑 config.sh 后重新运行脚本。"
        exit 1
    fi

    # 用户选择 "1"，执行手动输入并保存到 config.sh
    MY_EMAIL=$(prompt_for_email)
    MY_DOMAIN=$(prompt_for_domain)
    MY_PASSWORD=$(prompt_for_password)

    # 更新 config.sh
    sed -i "s|MY_EMAIL=.*|MY_EMAIL=\"$MY_EMAIL\"|" config.sh
    sed -i "s|MY_DOMAIN=.*|MY_DOMAIN=\"$MY_DOMAIN\"|" config.sh
    sed -i "s|MY_PASSWORD=.*|MY_PASSWORD=\"$MY_PASSWORD\"|" config.sh
fi

# 显示最终配置
echo "Email: $MY_EMAIL"
echo "Domain: $MY_DOMAIN"
echo "Password: $MY_PASSWORD"

# Get the path of the script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

system_identification

if download_package socat; then #安装socat
    download_results socat 0 #能走到这所以绝对是0,显示安装成功
    if download_package git; then #安装git
        download_results git 0 #显示安装成功
    else
        download_results git 1 #显示安装失败
        exit 1
    fi
else
    download_results socat 1
    exit 1
fi

#!/bin/bash

open_port 80

email=${MY_EMAIL}
acme_register "$email"

domain=${MY_DOMAIN}
acme_issue "$domain"

if [ $? -eq 0 ]; then
    echo "Download hystera2..."
    download_hy2
    echo "Install certificate..."
    sudo "$ACME_BIN" --installcert -d "$domain" --ecc  --key-file    /etc/hysteria/server.key   --fullchain-file /etc/hysteria/server.crt
else
    echo "Failed to process domain."
    exit 1
fi

password=$MY_PASSWORD # read password from environment variable
config_path="/etc/hysteria/config.yaml"
new_path="/etc/hysteria/config_old"
new_path_file="/etc/hysteria/config_old/config.yaml"

perl -pi -e "s|your_password|$password|g" "${script_dir}/config.yaml"
echo "Your hysteria2 password is ${password}, you can modify it in ${config_path}"

mkdir -p "${new_path}"
mv "${config_path}" "${new_path}" || { echo "Failed to move config.yaml."; exit 1; }
#if want to change file name, use "${new_path}"/new_name.yaml

cp "${script_dir}/config.yaml" "${config_path}" || { echo "Failed to copy config.yaml."; exit 1; }
open_port 443
status1=$?  # 记录第一个 open_port 的执行状态

open_port 443 udp
status2=$?  # 记录第二个 open_port 的执行状态

if [ "$status1" -eq 0 ] || [ "$status2" -eq 0 ]; then
    firewall-cmd --reload
fi

if systemctl enable hysteria-server.service; then
    chmod 644 /etc/hysteria/server.key
    systemctl restart hysteria-server.service
else
    echo "❌ Failed to enable hysteria-server.service. Exiting."
    exit 1
fi

echo "Installation completed."
exit 0
