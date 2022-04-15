#!/bin/sh

# user variables, change the values before executing this script
DATABASE_NAME="my_db"
LOCAL_USERNAME="user"
LOCAL_PASSWORD=""
REMOTE_USERNAME="remote"
REMOTE_PASSWORD=""
DOMAIN_NAME="mydomain"

# constant variables
MYSQLD_CNF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
VIRTUAL_HOST_DIR="/etc/apache2/sites-available"


# start the setup
echo "----- UPDATE SYSTEM -----"
sudo apt update
echo "----- DONE UPDATE SYSTEM -----"

echo
echo "----- INSTALL PREREQUISITE PACKAGES -----"
sudo apt install pwgen -y																# package for generating passwords
echo "----- DONE INSTALL PREREQUISITE PACKAGES -----"

echo
echo "----- SETUP APACHE -----"
sudo apt install apache2 -y
# NOTE: no need to enable ufw for aws ec2 instance
echo "----- DONE SETUP APACHE -----"

echo
echo "----- SETUP MYSQL SERVER -----"
sudo apt install mysql-server -y
# -------------------------------
# setup mysql_secure_installation
# -------------------------------
sudo mysql -e "install plugin validate_password soname 'validate_password.so';"			# install validate password plugin
sudo mysql -e "SET GLOBAL validate_password_policy = 1;"								# set password validation policy (MEDIUM)
# sudo mysql -e "UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';"	# set root password
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"									# remove anonymous users
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"		# remove remote root
sudo mysql -e "DROP DATABASE test;"														# remove test database
sudo mysql -e "FLUSH PRIVILEGES;"														# reload priviledge tables
# ---------------
# create database
# ---------------
sudo mysql -e "CREATE DATABASE $DATABASE_NAME;"
# ----------------
# setup local user
# ----------------
# if LOCAL_PASSWORD is blank or weak, generate random password
if [ \( -z "$LOCAL_PASSWORD" -a "$LOCAL_PASSWORD" == "" \) -o \( $(sudo mysql -se "select VALIDATE_PASSWORD_STRENGTH('$LOCAL_PASSWORD');") -lt 50 \) ]; then
	LOCAL_PASSWORD=$(pwgen --capitalize --numerals --symbols --ambiguous --secure 16 1)
fi
sudo mysql -e "CREATE USER '$LOCAL_USERNAME'@'localhost' IDENTIFIED BY '$LOCAL_PASSWORD';"
sudo mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE ON $DATABASE_NAME.* TO '$LOCAL_USERNAME'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
# -----------------
# setup remote user
# -----------------
# if REMOTE_PASSWORD is blank, generate random password
if [ \( -z "$REMOTE_PASSWORD" -a "$REMOTE_PASSWORD" == "" \) -o \( $(sudo mysql -se "select VALIDATE_PASSWORD_STRENGTH('$REMOTE_PASSWORD');") -lt 50 \) ]; then
	REMOTE_PASSWORD=$(pwgen --capitalize --numerals --symbols --ambiguous --secure 16 1)
fi
sudo mysql -e "CREATE USER '$REMOTE_USERNAME'@'%' IDENTIFIED BY '$REMOTE_PASSWORD';"
sudo mysql -e "GRANT ALL ON $DATABASE_NAME.* TO '$REMOTE_USERNAME'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo sed -i 's/bind-address\t\t= .*/bind-address\t\t= '0.0.0.0'/' $MYSQLD_CNF_FILE		# bind-address=0.0.0.0 will enable remote connection
# --------------------------------------
# enable log_bin_trust_function_creators
# --------------------------------------
sudo sed -i '$ a log_bin_trust_function_creators\t\t= 1' $MYSQLD_CNF_FILE				# enable log_bin_trust_function_creators to allow CREATE FUNCTION
sudo systemctl restart mysql
echo "----- DONE SETUP MYSQL SERVER -----"

echo
echo "----- SETUP PHP -----"
sudo apt install php libapache2-mod-php php-mysql -y
# ------------------
# create html folder
# ------------------
sudo mkdir /var/www/$DOMAIN_NAME														# create folder to store html files
sudo chown -R $USER:$USER /var/www/$DOMAIN_NAME											# give permission to the html folder
sudo chmod -R 755 /var/www/$DOMAIN_NAME
# -------------------
# create virtual host
# -------------------
sudo bash -c "cat >> $VIRTUAL_HOST_DIR/$DOMAIN_NAME.conf" <<EOF							# create virtual host file for domain
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	ServerName $DOMAIN_NAME
	ServerAlias www.$DOMAIN_NAME
	DocumentRoot /var/www/$DOMAIN_NAME
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
sudo a2ensite $DOMAIN_NAME.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2
echo "----- DONE SETUP PHP -----"

# save user values to a file
echo
echo "Values are saved to lamp-setup-values.txt"
cat <<EOF >lamp-setup-values.txt
DATABASE_NAME		= $DATABASE_NAME
LOCAL_USERNAME		= $LOCAL_USERNAME
LOCAL_PASSWORD		= $LOCAL_PASSWORD
REMOTE_USERNAME		= $REMOTE_USERNAME
REMOTE_PASSWORD		= $REMOTE_PASSWORD
DOMAIN_NAME			= $DOMAIN_NAME
HTML_FOLDER			= /var/www/$DOMAIN_NAME
EOF

echo "Setup done, enjoy!"

# sudo ufw allow "Apache Full"
# sudo ufw allow mysql
# sudo ufw enable