# become the root
sudo su - 

# note you would have to type the password manually ...

# make a backup of your sudoers file - You have been warned !!!
cp -v /etc/sudoers /etc/sudoers.`date +%Y%m%d_%H%M%S`

# search and replace appuser for the name of the user you want to grant sudo to
echo '# ui_user does not want to type passwords with sudo' >> /etc/sudoers
echo 'appuser  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# done 
# eof file: sfw/bash/snippets/how-to-add-user-to-sudoers-file.sh
