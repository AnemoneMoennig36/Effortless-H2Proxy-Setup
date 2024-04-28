#!/bin/bash

# Get the path of the script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

function download_hy2 {
    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
        echo "Downloading script..."
        if ! bash <(curl -fsSL https://get.hy2.sh/); then
            echo "Failed to download or execute the script."
            return 1  # return error code, don't exit
        fi
    else
        echo "This script is intended to be run on Linux or macOS systems."
        exit 1  # return error code and exit script
    fi
}

function download_git {
    if command -v dnf >/dev/null 2>&1; then
        echo "Using dnf to install git"
        sudo dnf install git -y
    elif command -v apt >/dev/null 2>&1; then
        echo "Updating package lists"
        sudo apt update
        echo "Using apt to install git"
        sudo apt install git -y
    else
        echo "No supported package manager found."
        return 1
    fi
}

function download_socat {
    if command -v dnf >/dev/null 2>&1; then
        echo "Using dnf to install socat"
        sudo dnf install socat -y
    elif command -v apt >/dev/null 2>&1; then
        echo "Updating package lists"
        sudo apt update
        echo "Using apt to install socat"
        sudo apt install socat -y
    else
        echo "No supported package manager found."
        return 1
    fi
}

function open_port {
    if command -v ufw >/dev/null 2>&1; then
        echo "Using ufw to allow port 80"
        sudo ufw allow 80
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "Using firewalld to allow port 80"
        sudo firewall-cmd --add-port=80/tcp --permanent
        sudo firewall-cmd --reload
    else
        echo "No supported firewall tool found."
    fi
}

function input_email {
    if read -t 300 -p "Please enter your email: " email; then
        ./acme.sh --register-account -m "$email"
    else
        echo
        echo "Sorry, too slow!"
        return 1
    fi
}

function switch_ca {
    # Define an array of certificate authorities
    local ca_servers=("letsencrypt" "buypass" "zerossl")
    # Traverse array
    for ca_server in "${ca_servers[@]}"; do
       if ./acme.sh --set-default-ca --server "$ca_server"; then
            echo "${ca_server} executed successfully, exiting loop."
            return 0
        else
            echo "${ca_server} failed to set."
        fi
    done
    echo "Failed to issue certificate."
    return 1
}

function input_domain {
    if read -t 300 -p "Please enter your domain: " domain; then
        if ./acme.sh --issue -d "$domain" --standalone -k ec-256; then
            echo "Certificate issued successfully."
        else
            echo "Change default certificate authority"
            switch_ca 
        fi
    else
        echo "Sorry, too slow!"
        return 1
    fi
}

download_socat
download_git
if [ $? -ne 0 ]; then
    echo "Failed to Install."
    exit 1
fi

git clone https://github.com/acmesh-official/acme.sh.git || { echo "Failed to clone acme.sh."; exit 1; }

chmod -R 700 /root/.acme.sh

if [ ! -d "./acme.sh" ]; then
    echo "acme.sh directory does not exist. Exiting."
    exit 1
fi
cd ./acme.sh || exit 1

chmod +x acme.sh
open_port
input_email
input_domain
if [ $? -eq 0 ]; then
    echo "Download hystera2"
    download_hy2
    echo "Install certificate"
    sudo ./acme.sh --installcert -d "$domain" --ecc  --key-file    /etc/hysteria/server.key   --fullchain-file /etc/hysteria/server.crt
else
    echo "Failed to process domain."
    exit 1
fi

find "${script_dir}" -name "config.yaml" -print0 | xargs -0 perl -pi -e "s|your_password|${email}|g"

new_path="/etc/hysteria/config_old"
new_path_file="/etc/hysteria/config_old/config.yaml"
config_path="/etc/hysteria/config.yaml"

mkdir -p "${new_path}"
sudo mv "${config_path}" "${new_path}" || { echo "Failed to move config.yaml."; exit 1; }
#if want to change file name, use "${new_path}"/new_name.yaml

sudo cp "${script_dir}/config.yaml" "${config_path}" || { echo "Failed to copy config.yaml."; exit 1; }

hysteria server -c "${config_path}"
if [ $? -eq 0 ]; then
    sudo setcap cap_net_bind_service=+ep /usr/local/bin/hysteria
    echo "enable hysteria-server.service"
    sudo systemctl enable hysteria-server.service
    echo "Check status of hysteria-server.service"
    systemctl status hysteria-server.service
else
    echo "Failed to test ${config_path}."
    exit 1
fi

echo "Your password is ${email}, please change a strong one instead. You can change it in ${config_path}"