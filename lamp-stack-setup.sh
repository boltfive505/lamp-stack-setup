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
echo "-------------------------"
echo "----- UPDATE SYSTEM -----"
echo "-------------------------"
sudo apt update

echo
echo "-----------------------------------------"
echo "----- INSTALL PREREQUISITE PACKAGES -----"
echo "-----------------------------------------"
sudo apt install pwgen -y			# package for generating passwords

echo
echo "--------------------------"
echo "----- INSTALL APACHE -----"
echo "--------------------------"
sudo apt install apache2 -y

echo
echo "-------------------------------------"
echo "----- SETUP FIREWALL FOR APACHE -----"
echo "-------------------------------------"
sudo ufw allow "Apache Full"

echo
echo "--------------------------------"
echo "----- INSTALL MYSQL SERVER -----"
echo "--------------------------------"
sudo apt install mysql-server -y
sudo mysql_secure_installation
y	# enable validate password plugin
root	# set password
root
y	# continue with password
y	# remove anonymous users
y	# disallow remote login
y	# remove test database
y	# reload priviledge tables

echo
echo "----------------------------------------------"
echo "----- MYSQL SETUP (1/4): CREATE DATABASE -----"
echo "----------------------------------------------"
sudo mysql -e "CREATE DATABASE $DATABASE_NAME;"

echo
echo "-------------------------------------------------------------------"
echo "----- MYSQL SETUP (2/4): CREATE USER FOR LOCALHOST CONNECTION -----"
echo "-------------------------------------------------------------------"
# if LOCAL_PASSWORD is blank, generate random password
if [ -z "$LOCAL_PASSWORD" -a "$LOCAL_PASSWORD" == "" ]; then
	LOCAL_PASSWORD=$(pwgen --capitalize --numerals --symbols --ambiguous --secure 16 1)
fi
sudo mysql -e "CREATE USER '$LOCAL_USERNAME'@'localhost' IDENTIFIED BY '$LOCAL_PASSWORD';"
sudo mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE ON $DATABASE_NAME.* TO '$LOCAL_USERNAME'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo
echo "----------------------------------------------------------------"
echo "----- MYSQL SETUP (3/4): CREATE USER FOR REMOTE CONNECTION -----"
echo "----------------------------------------------------------------"
# if REMOTE_PASSWORD is blank, generate random password
if [ -z "$REMOTE_PASSWORD" -a "$REMOTE_PASSWORD" == "" ]; then
	REMOTE_PASSWORD=$(pwgen --capitalize --numerals --symbols --ambiguous --secure 16 1)
fi
sudo mysql -e "CREATE USER '$REMOTE_USERNAME'@'%' IDENTIFIED BY '$REMOTE_PASSWORD';"
sudo mysql -e "GRANT ALL ON $DATABASE_NAME.* TO '$REMOTE_USERNAME'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
sed -i 's/bind-address\t\t= .*/bind-address\t\t= '0.0.0.0'/' $MYSQLD_CNF_FILE	# bind-address=0.0.0.0 will enable remote connection

echo
echo "-----------------------------------------------------------------------"
echo "----- MYSQL SETUP (4/4): ENABLING log_bin_trust_function_creators -----"
echo "-----------------------------------------------------------------------"
sed -i '$ a log_bin_trust_function_creators\t\t= 1' $MYSQLD_CNF_FILE

echo
echo "------------------------------------------------"
echo "----- MYSQL SETUP DONE, RESTARTING SERVICE -----"
echo "------------------------------------------------"
sudo systemctl restart mysql

echo ""
echo "-----------------------"
echo "----- INSTALL PHP -----"
echo "-----------------------"
sudo apt install php libapache2-mod-php php-mysql -y

echo
echo "-----------------------------------------------"
echo "----- PHP SETUP (1/1): CREATE HTML FOLDER -----"
echo "-----------------------------------------------"
sudo mkdir /var/www/$DOMAIN_NAME			# create folder to store html files
sudo chown -R $USER:$USER /var/www/$DOMAIN_NAME		# give permission to the html folder
sudo chmod -R 755 /var/www/$DOMAIN_NAME

echo
echo "------------------------------------------------"
echo "----- PHP SETUP (1/1): CREATE VIRTUAL HOST -----"
echo "------------------------------------------------"
cat <<EOF >$VIRTUAL_HOST_DIR/$DOMAIN_NAME.conf		# create virtual host file for domain
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
sudo apache2ctl configtest				# only for checking config status

echo
echo "----------------------------------------------"
echo "----- PHP SETUP DONE, RESTARTING SERVICE -----"
echo "----------------------------------------------"
sudo systemctl restart apache2

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

