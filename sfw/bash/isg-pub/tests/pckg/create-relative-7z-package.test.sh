#!/bin/bash 

#v1.0.6
#------------------------------------------------------------------------------
# creates the relative package as component of larger product platform
#------------------------------------------------------------------------------
doTestCreateRelative7zPackage(){
	doLog " INFO START : create-relative-7z-package.test"

	bash sfw/bash/isg-pub/isg-pub.sh -a create-relative-7z-package	
	doLog " INFO STOP  : create-relative-7z-package.test"
	
	sleep $sleep_interval
   printf "\033[2J";printf "\033[0;0H"
	
}
#eof test doCreaterelative7zPackage

