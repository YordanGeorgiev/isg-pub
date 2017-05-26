#v0.2.1
#------------------------------------------------------------------------------
#  gmail the latest created package - requires mutt binary !!!
#------------------------------------------------------------------------------
doTestGmailPackage(){

	doLog " START : gmail-package"
	doSpecGmailPackage
	
	bash sfw/bash/isg-pub/isg-pub.sh -a gmail-package	
	doLog " STOP  : gmail-package"

}
#eof func doTestGmailPackage
