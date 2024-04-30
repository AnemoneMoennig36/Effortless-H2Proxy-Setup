function system_identification {
    if command -v dnf >/dev/null 2>&1; then
        pkg_manager="dnf"
        firewall_tool="firewalld"
    elif command -v apt >/dev/null 2>&1; then
        pkg_manager="apt"
        firewall_tool="ufw"
    else
        pkg_manager="none"
        firewall_tool="none"
    fi
}

function download_hy2 {
    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
        echo "Downloading hysteria2..."
        if ! bash <(curl -fsSL https://get.hy2.sh/); then
            echo "Failed to download or execute the script."
            return 1  # return error code, don't exit
        fi
    else
        echo "This script is intended to be run on Linux or macOS systems."
        exit 1  # return error code and exit script
    fi
}

function download_package {
    local package=$1
    case $pkg_manager in
        dnf)
            echo "Using dnf to install $package"
            dnf install ${package} -y
            ;;
        apt)
            echo "Updating package lists"
            apt update
            echo "Using apt to install $package"
            apt install ${package} -y
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
    if [ result -eq 0 ]; then
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
    email=${MY_EMAIL} # read email from environment variable
    if [[ -z "$email" ]]; then # if email is empty, ask user to input
        if read -t 300 -p "Please enter your email: " email; then
            echo "Email:$email"
        else
            echo "Sorry, too slow!"
            return 1
        fi
    fi
    echo $email
}

function prompt_for_domain {
    domain=${MY_DOMAIN}
    if [[ -z "$domain" ]];then
        if read -t 300 -p "Please enter your domain: " domain; then
            echo "Domain:$domain"
        else
            echo "Sorry, too slow!"
            return 1
        fi
    fi
    echo $domain
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

function acme_issue {
    local domain=$1 
    if ./acme.sh --issue -d "$domain" --standalone -k ec-256; then
        echo "Certificate issued successfully."
    else
        echo "Change default certificate authority"
        switch_ca 
    fi
}