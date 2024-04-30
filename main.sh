#!/bin/bash

source config.sh #Loading variables from config.sh
if [ $? -eq 0 ]; then
    echo "Email: $MY_EMAIL"
    echo "Domain: $MY_DOMAIN"
    echo "Password: $MY_PASSWORD"
else
    echo "Welcome to the Effortless-H2Proxy-Setup script."
fi

if ! source lib.sh; then
    echo "Please have your email and domain name ready so that you can enter them manually while the script is running."
fi

# Get the path of the script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

system_identification

if download_package socat; then
    download_results socat 0
    if download_package git; then
        download_results git 0
    else
        download_results git 1
        exit 1
    fi
else
    download_results socat 1
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

open_port 80

email=$(prompt_for_email)
if [[ -n "$email" ]]; then
    acme_register "$email"
else
    echo "Email not provided or input timed out."
    exit 1
fi

domain=$(prompt_for_domain)
if [[ -n "$domain" ]]; then
    acme_issue "$domain"
else
    echo "Domain not provided or input timed out."
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "Download hystera2..."
    download_hy2
    echo "Install certificate..."
    sudo ./acme.sh --installcert -d "$domain" --ecc  --key-file    /etc/hysteria/server.key   --fullchain-file /etc/hysteria/server.crt
else
    echo "Failed to process domain."
    exit 1
fi

password=$MY_PASSWORD # read password from environment variable
config_path="/etc/hysteria/config.yaml"
new_path="/etc/hysteria/config_old"
new_path_file="/etc/hysteria/config_old/config.yaml"
default_password=$(openssl rand -base64 12)

if [[ -n "$password" ]]; then # if password is found
    perl -pi -e "s|your_password|$password|g" "${script_dir}/config.yaml"
    echo "Your hysteria2 password is ${password}, you can modify it in ${config_path}"
else
    perl -pi -e "s|your_password|${default_password}|g" "${script_dir}/config.yaml"
    echo "Your hysteria2 password is set to a secure generated password, you can modify it in ${config_path}"
fi

mkdir -p "${new_path}"
mv "${config_path}" "${new_path}" || { echo "Failed to move config.yaml."; exit 1; }
#if want to change file name, use "${new_path}"/new_name.yaml

cp "${script_dir}/config.yaml" "${config_path}" || { echo "Failed to copy config.yaml."; exit 1; }

hysteria server -c "${config_path}"
if [ $? -eq 0 ]; then
    setcap cap_net_bind_service=+ep /usr/local/bin/hysteria
    echo "enable hysteria-server.service"
    systemctl enable hysteria-server.service
    echo "Check status of hysteria-server.service"
    systemctl status hysteria-server.service
else
    echo "Failed to test ${config_path}."
    exit 1
fi

echo "Installation comleted."