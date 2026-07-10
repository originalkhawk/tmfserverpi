#!/bin/bash

echo
echo "=================================================="
echo " TrackMania Nations Forever Pi Installer"
echo "=================================================="
echo
echo "This installer will configure:"
echo
echo " • TrackMania Dedicated Server"
echo " • XASECO (PHP 8)"
echo " • MariaDB"
echo
echo "You'll be asked a few questions to configure your"
echo "server automatically."
echo
echo "Press Enter to begin..."
read

############################################################
# Check for Box86
############################################################

echo "Checking for Box86..."

if ! command -v box86 >/dev/null 2>&1; then
    echo
    echo "ERROR: Box86 is not installed."
    echo
    echo "TrackMania Dedicated Server requires Box86 to run."
    echo
    echo "Please install Box86 first, then run setup.sh again."
    echo
    echo "https://github.com/ptitSeb/box86"
    echo
    exit 1
fi

echo "Box86 found."
echo

############################################################
# TrackMania Dedicated Server
############################################################

echo
echo "--------------------------------------------------"
echo " TrackMania Dedicated Server"
echo "--------------------------------------------------"
echo

echo "SuperAdmin Password"
echo "Used by XASECO to control your dedicated server."
echo "This is NOT your TrackMania account password."
echo
read -p "SuperAdmin Password: " SUPER_ADMIN_PASSWORD

echo
echo "Dedicated Server Login"
echo "This is NOT your normal TrackMania player account."
echo
echo "Need one? Create or view it here:"
echo "https://players.trackmaniaforever.com/main.php?view=dedicated-servers"
echo
read -p "Dedicated Login: " DEDICATED_LOGIN

echo
echo "Dedicated Server Password"
echo "This is the password for your dedicated server login."
echo
read -p "Dedicated Password: " DEDICATED_PASSWORD

echo
echo "Validation Key (Optional)"
echo "Enter the last 3 letters or numbers of your TrackMania game key."
echo "Leave blank if you don't have one."
echo
read -p "Validation Key: " DEDICATED_VALIDATION

echo
echo "Server Name"
echo "The name players will see in the server browser."
echo
read -p "Server Name: " SERVER_NAME

echo
echo "Server Comment (Optional)"
echo "Displayed below your server name in the browser."
echo "Leave blank for no comment."
echo
read -p "Server Comment: " SERVER_COMMENT

echo
echo "Server Visibility"
echo
echo "  0 = Always visible"
echo "  1 = Always hidden"
echo "  2 = Hidden from TrackMania Nations players"
echo
read -p "Visibility: " SERVER_VISIBILITY

echo
echo "Maximum Players"
echo
read -p "Player Slots: " MAX_PLAYERS

echo
echo "Player Password (Optional)"
echo "Leave blank for a public server."
echo
read -p "Player Password: " PLAYER_PASSWORD

echo
echo "Maximum Spectators"
echo
read -p "Spectator Slots: " MAX_SPECTATORS

echo
echo "Spectator Password (Optional)"
echo "Leave blank for no spectator password."
echo
read -p "Spectator Password: " SPECTATOR_PASSWORD

############################################################
# MariaDB
############################################################

echo
echo "--------------------------------------------------"
echo " MariaDB"
echo "--------------------------------------------------"
echo

echo "XASECO stores records, statistics and settings"
echo "inside a MariaDB database."
echo

read -p "Database Name: " DATABASE_NAME

echo
read -p "Database Username: " DATABASE_USER

echo
read -p "Database Password: " DATABASE_PASSWORD

############################################################
# XASECO
############################################################

echo
echo "--------------------------------------------------"
echo " XASECO"
echo "--------------------------------------------------"
echo

echo "TrackMania Account"
echo "Enter your normal TrackMania player login."
echo
read -p "TrackMania Account: " TRACKMANIA_ACCOUNT

echo
echo "IOC Country Code"
echo "Examples: GBR, USA, FRA, DEU"
echo
echo "Need to look yours up?"
echo "https://en.wikipedia.org/wiki/List_of_IOC_country_codes"
echo
read -p "IOC Code: " IOC

echo
echo "Configuration complete!"
echo

############################################################
# Install Required Packages
############################################################

echo "Installing required packages..."
echo

apt update

apt install -y \
    php-cli \
    php-mysql \
    php-xml \
    mariadb-server \
    netcat-openbsd

echo
echo "Dependencies installed."
echo

############################################################
# Helper Function
############################################################

# Usage:
# replace "__placeholder__" "replacement" "file"

replace() {
    local search="$1"
    local replacement="$2"
    local file="$3"

    replacement=$(printf '%s' "$replacement" | sed 's/[&|\\]/\\&/g')

    sed -i "s|$search|$replacement|g" "$file"
}

############################################################
# Create MariaDB Database & User
############################################################

echo "--------------------------------------------------"
echo " Configuring MariaDB"
echo "--------------------------------------------------"
echo

echo "Creating database..."

mysql <<EOF
CREATE DATABASE IF NOT EXISTS \`$DATABASE_NAME\`;
CREATE USER IF NOT EXISTS '$DATABASE_USER'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DATABASE_NAME\`.* TO '$DATABASE_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "MariaDB configured."
echo

############################################################
# Confirm Database Login
############################################################

echo "Confirming database connection..."

mysql -u"$DATABASE_USER" -p"$DATABASE_PASSWORD" "$DATABASE_NAME" -e "exit"

echo "Database connection successful."
echo

############################################################
# TrackMania Dedicated Server
############################################################

echo "Configuring Dedicated Server..."

CFG="server/GameData/Config/dedicated_cfg.txt"

replace "__super_admin_password__" "$SUPER_ADMIN_PASSWORD" "$CFG"
replace "__dedicated_login__" "$DEDICATED_LOGIN" "$CFG"
replace "__dedicated_password__" "$DEDICATED_PASSWORD" "$CFG"

if [ -z "$DEDICATED_VALIDATION" ]; then
    replace "__dedicated_validation__" "" "$CFG"
else
    replace "__dedicated_validation__" "$DEDICATED_VALIDATION" "$CFG"
fi

replace "__server_name__" "$SERVER_NAME" "$CFG"

if [ -z "$SERVER_COMMENT" ]; then
    replace "__server_comment__" "" "$CFG"
else
    replace "__server_comment__" "$SERVER_COMMENT" "$CFG"
fi

replace "__server_visability__" "$SERVER_VISIBILITY" "$CFG"
replace "__max_player__" "$MAX_PLAYERS" "$CFG"

if [ -z "$PLAYER_PASSWORD" ]; then
    replace "__password_player__" "" "$CFG"
else
    replace "__password_player__" "$PLAYER_PASSWORD" "$CFG"
fi

replace "__max_spectator__" "$MAX_SPECTATORS" "$CFG"

if [ -z "$SPECTATOR_PASSWORD" ]; then
    replace "__password_spectator__" "" "$CFG"
else
    replace "__password_spectator__" "$SPECTATOR_PASSWORD" "$CFG"
fi

echo "Dedicated Server configured."
echo

############################################################
# XASECO Database
############################################################

echo "Configuring XASECO database..."

CFG="xaseco/localdatabase.xml"

replace "__database_user__" "$DATABASE_USER" "$CFG"
replace "__database_password__" "$DATABASE_PASSWORD" "$CFG"
replace "__database_name__" "$DATABASE_NAME" "$CFG"

echo "XASECO database configured."
echo

############################################################
# XASECO Main Config
############################################################

echo "Configuring XASECO..."

CFG="xaseco/config.xml"

replace "__trackmania_account__" "$TRACKMANIA_ACCOUNT" "$CFG"
replace "__super_admin_password__" "$SUPER_ADMIN_PASSWORD" "$CFG"

echo "XASECO configured."
echo

############################################################
# Dedimania
############################################################

echo "Configuring Dedimania..."

CFG="xaseco/dedimania.xml"

replace "__dedicated_login__" "$DEDICATED_LOGIN" "$CFG"
replace "__dedicated_password__" "$DEDICATED_PASSWORD" "$CFG"
replace "__IOC__" "$IOC" "$CFG"

echo "Dedimania configured."
echo

############################################################
# Create Startup Script
############################################################

echo "Creating startup script..."

cat > TMFServer.sh <<'EOF'
#!/bin/bash

echo
echo "======================================="
echo " TrackMania Nations Forever Pi Server"
echo "======================================="
echo

echo "Starting TrackMania Dedicated Server..."

(
    cd server
    ./start.sh
) &

echo "Waiting for XML-RPC server..."

for i in {1..60}
do
    if nc -z 127.0.0.1 5000; then
        break
    fi

    sleep 1
done

echo "Dedicated server is ready."
echo

echo "Starting XASECO..."

(
	cd xaseco
	php aseco.php TMN </dev/null >aseco.log 2>&1 &
)
echo
echo "Server started successfully."
EOF

echo "Creating stop script..."

cat > TMFStop.sh <<'EOF'
#!/bin/bash

echo
echo "======================================="
echo " TrackMania Nations Forever Pi Server"
echo "======================================="
echo
echo "Stopping XASECO..."
pkill -f "aseco.php TMN"

echo "Stopping TrackMania Dedicated Server..."
pkill -f TrackmaniaServer

echo
echo "Server stopped."
EOF


chmod +x TMFServer.sh
chmod +x TMFStop.sh
chmod +x server/start.sh

############################################################
# Finished
############################################################

echo
echo "=================================================="
echo " Installation Complete!"
echo "=================================================="
echo
echo "Your server has been configured."
echo
echo "To start the server run:"
echo
echo "    ./TMFServer.sh"
echo
echo "To stop the server run:"
echo "	  ./TMFStop.sh"
echo 
echo "Have fun, and happy racing!"
echo 
