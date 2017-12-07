# src/bash/isg-pub/funcs/create-mysql-user.func.sh

# 0.9.8
#------------------------------------------------------------------------------
# create the projects mysql user form the loaded project cnf file
# credits: https://stackoverflow.com/a/33474729/65706
#------------------------------------------------------------------------------
doCreateMysqlUser(){

   doLog "DEBUG START doCreateMysqlUser"

   mysql -uroot -p${mysql_root_passwd} -e \
      "DROP USER ${mysql_user}@localhost ;" ; 
   mysql -uroot -p${mysql_root_passwd} -e \
      "CREATE USER ${mysql_user}@localhost IDENTIFIED BY '${mysql_user_pw}';"
   mysql -uroot -p${mysql_root_passwd} -e \
      "GRANT ALL PRIVILEGES ON *.* TO ${mysql_user}@'localhost';"
   mysql -uroot -p${mysql_root_passwd} -e \
      "FLUSH PRIVILEGES;"

	doLog "DEBUG STOP  doCreateMysqlUser"
}
# eof func doCreateMysqlUser


# eof file: src/bash/isg-pub/funcs/create-mysql-user.func.sh
