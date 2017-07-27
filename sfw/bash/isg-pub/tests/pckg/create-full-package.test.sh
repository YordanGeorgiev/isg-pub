#!/bin/bash 

#v1.1.0
#------------------------------------------------------------------------------
# tests the full package creation
#------------------------------------------------------------------------------
doTestCreateFullPackage(){
	doLog " INFO START : create-full-package.test"
	
	cat docs/txt/isg-pub/tests/pckg/create-full-package.test.txt

	doSpecCreateFullPackage

	doHelpCreateFullPackage

	bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package
	test -z "$sleep_interval" || sleep "$sleep_interval"
   printf "\033[2J";printf "\033[0;0H"

	bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package -i meta/.tst.isg-pub
	test -z "$sleep_interval" || sleep "$sleep_interval"
   printf "\033[2J";printf "\033[0;0H"
	
	bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package -i meta/.prd.isg-pub
	test -z "$sleep_interval" || sleep "$sleep_interval"
   printf "\033[2J";printf "\033[0;0H"
	
	bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package -i meta/.git.isg-pub
	test -z "$sleep_interval" || sleep "$sleep_interval"
   printf "\033[2J";printf "\033[0;0H"

	bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package -i meta/.prd.isg-pub \
	-a gmail-package 
	test -z "$sleep_interval" || sleep "$sleep_interval"
   printf "\033[2J";printf "\033[0;0H"
	
	doLog " INFO STOP  : create-full-package.test"
}
#eof test doCreateFullPackage
