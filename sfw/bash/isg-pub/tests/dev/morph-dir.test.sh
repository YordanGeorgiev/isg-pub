#v1.0.5
#------------------------------------------------------------------------------
#  Purpose: 
#  export to_repl=<<the-string-to-replace-with>>
#------------------------------------------------------------------------------
doTestMorphDir(){
		
	doLog " INFO START : morph-dir.test"

	# doSpecMorphDir
	echo this function should not work without setting the following shell vars
	echo export dir_to_morph="<<the-dir-to-search-and-replace>>"
	echo to_srch="<<to_srch>>"
	echo to_repl="<<to_repl>>"

	sleep 1	
	bash sfw/bash/isg-pub/isg-pub.sh -a morph-dir
	echo now this test should succeed	
	mkdir -p /tmp/sfw/bash	
	cp -rv sfw/bash/isg-pub /tmp/sfw/bash
	export dir_to_morph=/tmp/sfw/bash/isg-pub
	export to_srch=isg-pub
	export to_repl=new-app
	bash sfw/bash/isg-pub/isg-pub.sh -a morph-dir
	
	echo "and check the produced dir"
	find /tmp/sfw/bash/new-app -type f
	doLog " INFO STOP  : morph-dir.test"

}
#eof doMorphDir

#eof file: sfw/bash/isg-pub/tests/dev/morph-dir.test.sh
