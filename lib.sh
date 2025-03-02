function system_identification {
    if command -v dnf >/dev/null 2>&1; then
        export pkg_manager="dnf"
        export firewall_tool="firewalld"
    elif command -v apt >/dev/null 2>&1; then
        export pkg_manager="apt"
        export firewall_tool="ufw"
        echo "Updating package lists"
        apt update
    else
        export pkg_manager="none"
        export firewall_tool="none"
    fi
}

function download_hy2 {
    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
        echo "Downloading hysteria2..."
        if ! bash <(curl -fsSL https://get.hy2.sh/); then
            echo "Failed to download or execute the script."
            return 1
        fi
    else
        echo "This script is intended to be run on Linux or macOS systems."
        exit 1
    fi
}

function download_package {
    local package=$1
    case $pkg_manager in
        dnf)
            echo "Using dnf to install $package"
            dnf install -y "$package"
            ;;
        apt)
            echo "Using apt to install $package"
            apt install -y "$package"
            ;;
        *)
            echo "No supported package manager found."
            return 1
            ;;
    esac
}

function download_results {
    local package=$1
    local result=$2
    if [ "$result" -eq 0 ]; then
        echo "$package is installed."
    else
        echo "Failed to install $package."
    fi
}

function open_port {
    local port=$1
    case $firewall_tool in
        firewalld)
            echo "Using firewalld to allow port $port"
            firewall-cmd --add-port=${port}/tcp --permanent
            firewall-cmd --reload
            ;;
        ufw)
            echo "Using ufw to allow port $port"
            ufw allow ${port}/tcp
            ;;
        *)
            echo "No supported firewall tool found."
            return 1
            ;;
    esac
}

function acme_register {
    local email=$1
    if ./acme.sh --register-account -m "$email"; then
        echo "Account registered successfully."
    else
        echo "Failed to register account."
    fi
}

function prompt_for_email {
    email=${MY_EMAIL}
    if [[ -z "$email" ]]; then
        if read -t 300 -p "Please enter your email: " email; then
            echo "$email"
        else
            echo "Sorry, too slow!" >&2
            return 1
        fi
    else
        echo "$email"
    fi
}

function prompt_for_domain {
    domain=${MY_DOMAIN}
    if [[ -z "$domain" ]]; then
        if read -t 300 -p "Please enter your domain: " domain; then
            echo "$domain"
        else
            echo "Sorry, too slow!" >&2
            return 1
        fi
    else
        echo "$domain"
    fi
}

function prompt_for_password {
    password=${MY_PASSWORD}
    if [[ -z "$password" ]]; then
        if read -t 300 -p "Please enter your password: " password; then
            echo "$password"
        else
            echo "Sorry, too slow!" >&2
            return 1
        fi
    else
        echo "$password"
    fi
}

function switch_ca {
    local ca_servers=("letsencrypt" "buypass" "zerossl")
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

function acme_issue {
    local domain=$1 
    if ./acme.sh --issue -d "$domain" --standalone -k ec-256; then
        echo "Certificate issued successfully."
    else
        echo "Change default certificate authority"
        switch_ca 
    fi
}