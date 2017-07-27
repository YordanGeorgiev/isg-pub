# sfw/bash/isg-pub/funcs/create-relative-package.spec.sh

# v1.0.9
# ---------------------------------------------------------
# todo: add doSpecCreateRelativePackage comments ...
# ---------------------------------------------------------
doSpecCreateRelativePackage(){

	doLog "DEBUG START doSpecCreateRelativePackage"
	
	cat docs/txt/isg-pub/specs/pckg/create-relative-package.spec.txt
	test -z "$sleep_interval" ||  sleep $sleep_interval
	doLog "DEBUG STOP  doSpecCreateRelativePackage"
}
# eof func doSpecCreateRelativePackage


# eof file: sfw/bash/isg-pub/funcs/create-relative-package.spec.sh
