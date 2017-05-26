#!/bin/bash 

#file: sfw/bash/isg-pub-test.sh docs at the eof file

umask 022    ;

# print the commands
# set -x
# print each input line as well

	start_dir=`pwd` 
	# it should be possible to call this from anywhere
   component_dir=`dirname $(readlink -f $0)`
	cd $component_dir ; cd .. ; cd .. ; cd ..

main(){

	doTestUsage
	doTestHelp
	doTestCtagsCreation
	doTestCloneToEnvTypes	
	doTestVersionChanges '0.2.3'
	doTestFullPackageCreation
	doTestDeploymentPackageCreation
	doTestRelativePackageCreation
	doTestRelativePackageCreationOfContainedApp
	doTestFullPackageCreationOfContainedApp
	doTestRemovePackageFiles
	doTestRemovePackage
	doTestToAppCloning
	doTestCheckPerlSyntax
	doTestGmailSending

	cd $start_dir
}

#
#----------------------------------------------------------
# test the compiling of the perl code
#----------------------------------------------------------
doTestCheckPerlSyntax(){
	echo START TEST perl-syntax-checking
	cat docs/txt/features/perl/01.perl-syntax-checking.txt
	sleep 3
	bash sfw/bash/isg-pub/isg-pub.sh -a check-perl-syntax
	echo after the completion all the perl files should be checked for syntax errors
	
	echo STOP TEST perl-syntax-checking

	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}

#
#----------------------------------------------------------
# test the sending of a package by gmail
#----------------------------------------------------------
doTestGmailSending(){
	echo START TEST full-package-creation with gmail 
	cat docs/txt/features/shell/08.gmail-package.txt
	sleep 3
	bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package -a gmail-package
	echo after the completion of the script you should have received an e-mail 
	echo from the configured account 
	
	echo test sending of a deploymet package
	bash sfw/bash/isg-pub/isg-pub.sh -a create-deployment-package -a gmail-package

	echo test sending the latest zip file if no full OR deployment package has been created	
	bash sfw/bash/isg-pub/isg-pub.sh -a gmail-package
	echo STOP  TEST full-package-creation with gmail

	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}



#
#----------------------------------------------------------
# test the version changes
#----------------------------------------------------------
doTestToAppCloning(){
	echo START TEST clone to app=rt-ticket
	sleep 3
	new_app=rt-ticket
	bash sfw/bash/isg-pub/isg-pub.sh -a to-app=$new_app
	echo "now the whole new app should be under this dir"
	echo search for the isg-pub string occurence
	find /opt/csitea/$new_app -exec file {} \; | grep text | cut -d: -f1| { while read -r file ;
			do (
				grep -nHP isg-pub "$file"
			);
			done ;
	}
	echo STOP  TEST clone to app=rt-ticket
	sleep 3
}


#
#----------------------------------------------------------
# test the creation of relative package of a contained app
#----------------------------------------------------------
doTestRelativePackageCreationOfContainedApp(){
	echo START TEST relative-package-creation of contained app
	sleep 3
	bash sfw/bash/isg-pub/isg-pub.sh -a create-relative-package -i meta/.deploy.ysg-cheat-sheets
	echo there should be a zip file containing all the relative 
	echo from the base dir files in the product version dir 
	echo should you have a file specified in the .include file which 
	echo does not really exist the script should exit with error specifying the 
	echo missing file
	stat -c "%y %n" *rel.zip | sort -nr
	echo STOP  TEST relative-package-creation of contained app
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}

#
#----------------------------------------------------------
# test the creation of relative package of a contained app
#----------------------------------------------------------
doTestFullPackageCreationOfContainedApp(){
	echo START TEST full-package-creation of contained app
	echo running : bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package -i meta/.deploy.ysg-cheat-sheets
	sleep 3
	bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package -i meta/.deploy.ysg-cheat-sheets
	echo there should be a zip file containing all the relative 
	echo from the base dir files in the product version dir 
	echo "should you have a file specified in the .include.<<app-name>> file which"
	echo does not really exist the script should exit with error specifying the 
	echo missing file
	stat -c "%y %n" *.zip | sort -nr
	echo STOP  TEST full-package-creation of contained app
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}


#
#----------------------------------------------------------
# test the removal of all the files in a package:w
#----------------------------------------------------------
doTestRemovePackageFiles(){
	echo START testing the removal of package files
	sleep 3
	echo create first a version to be able to delete from 
	bash sfw/bash/isg-pub/isg-pub.sh -a to-ver=0.0.1
	echo Action !!
	echo running : bash ../isg-pub.0.0.1.dev.ysg/sfw/bash/isg-pub/isg-pub.sh -a remove-package-files
	sleep 2
	bash ../isg-pub.0.0.1.dev.ysg/sfw/bash/isg-pub/isg-pub.sh -a remove-package-files
	echo STOP  TEST for remove-package-files
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}
#eof func doTestRemovePackageFiles


#
#----------------------------------------------------------
# test the removal of all the files in a package:w
#----------------------------------------------------------
doTestRemovePackage(){
	echo START TEST remove-package
	sleep 3
	echo create first a version to be able to delete from 
	bash sfw/bash/isg-pub/isg-pub.sh -a to-ver=0.0.1
	echo Action !!
	echo running : bash ../isg-pub.0.0.1.dev.ysg/sfw/bash/isg-pub/isg-pub.sh -a remove-package
	sleep 2
	bash ../isg-pub.0.0.1.dev.ysg/sfw/bash/isg-pub/isg-pub.sh -a remove-package
	echo STOP  TEST for remove-package
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}
#eof func doTestRemovePackageFiles

#
#----------------------------------------------------------
# 
#----------------------------------------------------------
doTestFullPackageCreation(){
	echo START TEST full-package-creation
	sleep 3
	echo running : 
	echo bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package
	sleep 1
	bash sfw/bash/isg-pub/isg-pub.sh -a create-full-package
	echo there should be a zip file containing all the relative 
	echo from the base dir files in the product version dir 
	echo should you have a file specified in the .include file which 
	echo does not really exist the script should exit with error specifying the 
	echo missing file
	stat -c "%y %n" *.zip | sort -nr
	echo STOP  TEST full-package-creation
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}

#
#----------------------------------------------------------
# test the creation of the relative package
#----------------------------------------------------------
doTestRelativePackageCreation(){
	echo START TEST relative-package-creation
	sleep 3
	bash sfw/bash/isg-pub/isg-pub.sh -a create-relative-package
	echo there should be a zip file containing all the relative 
	echo from the product version dir files
	echo should you have a file specified in the .include-isg-pub file which 
	echo does not really exist the script should exit with error specifying the 
	echo missing file
	stat -c "%y %n" *.rel.zip | sort -nr
	echo "test also the creation of the relative file paths package with "
	echo "overrided include file, which is the deploy file in this case"
	bash sfw/bash/isg-pub/isg-pub.sh -a create-relative-package -i meta/.deploy.isg-pub
	echo STOP  TEST relative-package-creation
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}

#
#----------------------------------------------------------
# test the version changes
#----------------------------------------------------------
doTestDeploymentPackageCreation(){
	echo START test the deployment package creation
	sleep 3
	bash sfw/bash/isg-pub/isg-pub.sh -a create-deployment-package
	echo there should be a zip file containing  the relative specified
	echo in the .deploy file files 
	echo from the base dir files in the product version dir 
	echo should you have a file speccified in the .deploy file which 
	echo does not really exist the script should exit with error specifying the 
	echo missing file
	stat -c "%y %n" *.zip | grep depl | sort -nr
	echo STOP  test the deployment package creation
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}


#
#----------------------------------------------------------
# test the version changes
#----------------------------------------------------------
doTestVersionChanges(){
	version="$1"
	shift 1;
	echo "feature specs:"
	sleep 4
	echo START TEST clone-to-versions
	sleep 1
	bash sfw/bash/isg-pub/isg-pub.sh -a to-ver=$version
	find . -maxdepth 2 | grep $version
	echo STOP  TEST clone-to-versions
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}



#
#----------------------------------------------------------
# The ctags in the product version dir provides the jump 
# to keyword functionality in vim with the Ctrl + AltGr + 9
#----------------------------------------------------------
doTestCtagsCreation(){
	rm -fv tags
	echo START TEST create-ctags
	bash sfw/bash/isg-pub/isg-pub.sh -a create-ctags
	echo there should be a tags file
	test -f tags && echo "test passed - tags file exists"
	test -f tags || echo "test failed - tags file does ot exist"
	sleep 1
	cat tags
	echo STOP  TEST create-ctags
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
}


#
#----------------------------------------------------------
# If you value your time you should develop in the dev enviroments
# test in your test ( tst ) environments 
# use , operate or run the apps in your prod ( prd ) environments
#----------------------------------------------------------
doTestCloneToEnvTypes(){
	bash sfw/bash/isg-pub/isg-pub.sh -a to-dev
	stat -c "%y %n" *.zip | sort -rn
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
	
	echo test the movement to the tst environment
	bash sfw/bash/isg-pub/isg-pub.sh -a to-tst
	stat -c "%y %n" *.zip | sort -rn
	sleep 3
	printf "\033[2J";printf "\033[0;0H"

	echo test movement to quality assurance
	echo test the movement to the qas environment
	bash sfw/bash/isg-pub/isg-pub.sh -a to-qas
	stat -c "%y %n" *.zip | sort -rn
	sleep 3
	printf "\033[2J";printf "\033[0;0H"
	
	echo test the movement to the prd environment
	bash sfw/bash/isg-pub/isg-pub.sh -a to-prd
	stat -c "%y %n" *.zip | sort -rn
	sleep 3
	printf "\033[2J";printf "\033[0;0H"

	find ../ -maxdepth 1| sort -nr
}
#eof doTestCloneToEnvTypes


doTestUsage(){

	bash sfw/bash/isg-pub/isg-pub.sh -u
	sleep 1 
	printf "\033[2J";printf "\033[0;0H"
	
	bash sfw/bash/isg-pub/isg-pub.sh -usage
	sleep 1 
	printf "\033[2J";printf "\033[0;0H"
	
	bash sfw/bash/isg-pub/isg-pub.sh --usage
	sleep 1
	printf "\033[2J";printf "\033[0;0H"
	
	echo "if the usage was displayed 2 times the test has passed"

		
}
#eof doTestUsage



doTestHelp(){

	bash sfw/bash/isg-pub/isg-pub.sh -h
	sleep 1 
	printf "\033[2J";printf "\033[0;0H"
	
	bash sfw/bash/isg-pub/isg-pub.sh --help
	sleep 1 
	printf "\033[2J";printf "\033[0;0H"
	
	echo test the help
	bash sfw/bash/isg-pub/isg-pub.sh -help
	sleep 1 
	printf "\033[2J";printf "\033[0;0H"

	echo "if the help was displayed 3 times the test has passed"
}
#eof doTestHelp



# Action !!!
main

#
#----------------------------------------------------------
# Purpose:
# to test the simplistic app stub with simplistic source control and 
# cloning or morphing functionalities ...
# to package the isg-pub app
#----------------------------------------------------------
#
#----------------------------------------------------------
#
#
# VersionHistory:
#----------------------------------------------------------
# 0.1.0 --- 2016-07-15 19:59:08 -- ysg -- packages gmailing added
# 0.0.8 --- 2016-07-09 20:17:01 -- ysg -- deployment package testing
# 0.0.4 --- 2016-07-02 23:33:48 -- ysg -- added version increase
# 0.0.3 --- 2016-07-01 22:04:33 -- ysg -- init
#----------------------------------------------------------
#
#eof file: isg-pub.sh v1.0.0
