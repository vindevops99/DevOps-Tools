#!/bin/bash
set -e

echo "=== Installing privacyIDEA 3.11.4 on Ubuntu 22.04 (Jammy) ==="

# Update and install dependencies
sudo apt update && sudo apt install -y software-properties-common wget curl gnupg2 ca-certificates

# Add NetKnights repository
wget https://lancelot.netknights.it/NetKnights-Release.asc
sudo mv NetKnights-Release.asc /etc/apt/trusted.gpg.d/
echo "deb http://lancelot.netknights.it/community/jammy/stable jammy main" | sudo tee /etc/apt/sources.list.d/privacyidea-community.list

# Update and install privacyidea-nginx
sudo apt update
sudo apt install -y privacyidea-nginx

# Prompt for PrivacyIDEA admin credentials
echo "=== Create PrivacyIDEA Admin User for Web GUI ==="
read -p "Enter admin username (default: admin): " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -p "Enter admin email (default: admin@localhost): " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@localhost}

while true; do
    read -sp "Enter password for PrivacyIDEA admin: " ADMIN_PASS
    echo
    read -sp "Confirm password for PrivacyIDEA admin: " ADMIN_PASS_CONFIRM
    echo
    if [[ "$ADMIN_PASS" == "$ADMIN_PASS_CONFIRM" ]]; then
        break
    else
        echo "❌ Passwords do not match. Please try again."
    fi
done

# Create the admin user
sudo pi-manage admin add "$ADMIN_USER" -e "$ADMIN_EMAIL" -p "$ADMIN_PASS"
echo "✅ PrivacyIDEA admin '$ADMIN_USER' created successfully."

# Prompt for creating MySQL user
read -p "Do you want to create a MySQL user for Navicat login? (yes/no): " CREATE_USER

if [[ "$CREATE_USER" == "yes" ]]; then
    read -p "Enter MySQL username for Navicat login (default: piadmin): " NAVICAT_USER
    NAVICAT_USER=${NAVICAT_USER:-piadmin}

    while true; do
        read -sp "Enter password for MySQL user '$NAVICAT_USER': " NAVICAT_PASS
        echo
        read -sp "Confirm password for MySQL user '$NAVICAT_USER': " NAVICAT_PASS_CONFIRM
        echo
        if [[ "$NAVICAT_PASS" == "$NAVICAT_PASS_CONFIRM" ]]; then
            break
        else
            echo "❌ Passwords do not match. Please try again."
        fi
    done

    sudo mysql -u root <<EOF
CREATE USER IF NOT EXISTS '${NAVICAT_USER}'@'%' IDENTIFIED BY '${NAVICAT_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${NAVICAT_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    echo "✅ MySQL user '$NAVICAT_USER' created with full privileges (Navicat login)."
else
    echo "⏭ Skipped MySQL user creation."
fi

echo "=== PrivacyIDEA 3.x installation completed ==="
echo "👉 Access the Web GUI via Nginx and log in with username: $ADMIN_USER"

