# LAMP Stack Setup Script

Personal use, for AWS EC2 (Ubuntu 20.04).
The script is not yet perfect. It should expect no errors, since this is made as a one-time execution and cannot be run again even if it errors. So make sure to set the values correctly.
**USE WITH CAUTION**

IMPORTANT: Change the values inside the script before executing.

How to use:

- From the terminal, download by typing `git clone https://github.com/boltfive505/lamp-stack-setup`
- To change the values, type `sudo nano lamp-stack-setup/setup.sh`
- Edit the following values:
  ```
  DATABASE_NAME       = "my_db"
  LOCAL_USERNAME      = "user"
  LOCAL_PASSWORD      = ""            # provide a strong password. If blank or weak, will auto generate random password
  REMOTE_USERNAME     = "remote"
  REMOTE_PASSWORD     = ""            # provice a strong password. If blank or weak, will auto generate random password
  DOMAIN_NAME         = "mydomain"    # your website name
  ```
- Execute the script by typing `sudo bash lamp-stack-setup/setup.sh`. It will do the following
  ```
  Update the system
  Install pwgen (password generator)
  Install and setup apache
  Install and setup mysql-server
      create database
      create local user
      create remote user
      set `bind-address` to '0.0.0.0' to allow remote access
      enable `log_bin_trust_function_creators` to allow CREATE FUNCTION
  Install and setup php
      create /var/www/ folder to store html files and set folder permission
      create custom virtual host
  ```
- After the setup is done, values (including passwords) will be saved to `lamp-values.txt`. Reminder to delete the file by typing `rm lamp-values.txt` after you get the values.
