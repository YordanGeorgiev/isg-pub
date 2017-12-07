# src/bash/isg-pub/funcs/create-mysql-user.test.sh

# v1.0.9
# ---------------------------------------------------------
# todo: add doTestCreateMysqlUser comments ...
# ---------------------------------------------------------
doTestCreateMysqlUser(){

	doLog "DEBUG START doTestCreateMysqlUser"
	
	cat doc/txt/isg-pub/tests/create-mysql-user.test.txt
	
	sleep "$sleep_interval"
	# add your action implementation code here ... 
   mysql -uroot -p${mysql_root_passwd} -e \
      "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${mysql_user_pw}')"
	# Action !!!

	doLog "DEBUG STOP  doTestCreateMysqlUser"
}
# eof func doTestCreateMysqlUser


# eof file: src/bash/isg-pub/funcs/create-mysql-user.test.sh
