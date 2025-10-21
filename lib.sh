ACME_BIN="$HOME/.acme.sh/acme.sh"

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
    local protocol=${2:-tcp}  # 默认协议是 TCP

    case $firewall_tool in
        firewalld)
            echo "Using firewalld to check port $port/$protocol..."
            if firewall-cmd --list-ports | grep -q "${port}/${protocol}"; then
                echo "Port $port/$protocol is already open."
            else
                echo "Opening port $port/$protocol..."
                if firewall-cmd --add-port=${port}/${protocol} --permanent; then
                    firewall-cmd --reload
                    echo "Port $port/$protocol opened successfully."
                else
                    echo "Failed to open port $port/$protocol."
                    return 1
                fi
            fi
            ;;
        ufw)
            echo "Using ufw to check port $port/$protocol..."
            if ufw status | grep -q "${port}/${protocol}"; then
                echo "Port $port/$protocol is already open."
            else
                echo "Opening port $port/$protocol..."
                if ufw allow ${port}/${protocol}; then
                    echo "Port $port/$protocol opened successfully."
                else
                    echo "Failed to open port $port/$protocol."
                    return 1
                fi
            fi
            ;;
        *)
            echo "No supported firewall tool found."
            return 1
            ;;
    esac
}

function acme_register {
    local email=$1
    local ACME_PATH="$ACME_BIN"

    if [ ! -x "$ACME_PATH" ]; then
        echo "❌ acme.sh not found or not executable at $ACME_PATH"
        return 1
    fi

    # 获取当前 CA 域名
    local default_ca=$("$ACME_PATH" --list-ca | grep "DEFAULT_CA" | awk '{print $NF}' | sed -E 's|https://([^/]+)/.*|\1|')

    # 确保 default_ca 不是空的
    if [ -z "$default_ca" ]; then
        echo "❌ Failed to detect default CA. Exiting."
        return 1
    fi

    # 计算 account.conf 的路径
    local acme_account_file="$HOME/.acme.sh/ca/${default_ca}/account.conf"

    # 检查账户是否已注册
    if [ -f "$acme_account_file" ]; then
        echo "✅ ACME account already registered with CA: $default_ca. Skipping registration."
        return 0
    fi

    # 账户未注册，执行注册
    if "$ACME_PATH" --register-account -m "$email"; then
        echo "✅ Account registered successfully with CA: $default_ca."
        return 0
    else
        echo "❌ Failed to register account with CA: $default_ca."
        return 1
    fi
}

function prompt_for_email {
    if read -t 300 -p "Please enter your email: " email; then
        echo "$email"
    else
        echo "Sorry, too slow!" >&2
        return 1
    fi
}

function prompt_for_domain {
    if read -t 300 -p "Please enter your domain: " domain; then
        echo "$domain"
    else
        echo "Sorry, too slow!" >&2
        return 1
    fi
}

function prompt_for_password {
    if read -t 300 -p "Please enter your password: " password; then
        echo "$password"
    else
        echo "Sorry, too slow!" >&2
        return 1
    fi
}

function switch_ca {
    local ca_servers=("letsencrypt" "buypass" "zerossl")
    for ca_server in "${ca_servers[@]}"; do
        if "$ACME_BIN" --set-default-ca --server "$ca_server"; then
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
    local ca_servers=("letsencrypt" "buypass" "zerossl")

    # 遍历所有可能的 CA 证书存储路径
    for ca in "${ca_servers[@]}"; do
        if [ -f "/root/.acme.sh/${domain}_${ca}_ecc/fullchain.cer" ]; then
            echo "SSL certificate for $domain already exists with CA: $ca. Skipping issuance."
            return 0  # 直接返回，不再申请
        fi
    done

    # 证书不存在，开始申请
    if "$ACME_BIN" --issue -d "$domain" --standalone -k ec-256; then
        echo "Certificate issued successfully."
    else
        echo "Changing default certificate authority..."
        switch_ca 
    fi
}
