#!/bin/bash
# file:test-isg-pub.sh v2.0.8


# v2.0.8
# set the variables to use within this script
doSetVars(){
   component_dir=`dirname $(readlink -f $0)`
   cd $component_dir
   cd ..
   component_base_dir=`pwd`
   for i in {1..2} ; do cd .. ;done ;
   product_version_dir=`pwd`;
   target_dir='/tmp/foo/bar'
   component_name=`basename $0`
   comonent_bare_name=${component_name%.*}
   component_name=`echo "$component_name" | perl -ne 's#(test\-)(.*)\.sh#$2#;print'`
   sh_to_test="$component_base_dir/$component_name/$component_name.sh"
   test $OSTYPE != 'cygwin' && export host_name=`hostname -s`
   test $OSTYPE == 'cygwin' && export host_name="$HOSTNAME"
   
}
#eof func doSetVars

#
# v2.0.8
#------------------------------------------------------------------------------
# test deployment with morphing  
#------------------------------------------------------------------------------
doTestHelp(){
   echo "#------------------------------------------------------------------------"
   echo " START TEST SUITE 1 --- doTestHelp"
   echo "#------------------------------------------------------------------------"
   
   
   msg_title="test 1"
   msg1="You should see the help appearing in the console"
   msg2=" If it does not it is a bug !!! "
   sleep 1
   
   echo "Action !!!"
   sh "$sh_to_test" -h  | less


   msg_title="test 2"
   msg1="There should be only the tmp dir existing"
   msg2="the tmp dir should exist , but no tmp.<<processId>> dirs"
   dirToTest="$component_base_dir/$component_name/tmp"
   doAssureIsDir "$msg_title" "$dirToTest" "$msg1" "$msg2"
   
   
   msg_title="test 3"
   msg1="no tmp dirs : $tmp.$$.tmp dirs should exist"
   cmdToTest="ls -al $component_base_dir/$component_name/tmp"
   doAssureCmdOutputVisually "$msg_title" "$cmdToTest" "$msg1" "$msg2"


   echo "#------------------------------------------------------------------------"
   echo " STOP TEST SUITE 1"
   echo "#------------------------------------------------------------------------"
}
#eof func doTestHelp


# v2.0.8
#------------------------------------------------------------------------------
# test deployment with morphing  
#------------------------------------------------------------------------------
doTestMorphingDeployment(){
   
   export target_component_name='foo-bar'
   export product_owner="ysg"
   export target_product_owner="somebody"
   export target_host="server"
	export target_dir='/tmp/morphus'

	rm -fvr "$target_dir/sfw/sh/$target_component_name"
	rm -fvr "$target_dir/sfw/sh/$component_name"

   echo "Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" \
	-a create-package -a deploy-package -d "$target_dir" \
	-s "$component_name¤$target_component_name" \
	-s "$product_owner¤$target_product_owner" \
	-s "host_name¤$target_host"
	# OBS ! no sigil $ before host_name

   echo "#------------------------------------------------------------------------"
   echo " START TEST SUITE 2 --- MORPHING DEPLOYMENT"
   echo "#------------------------------------------------------------------------"
  


   msg_title="test 1"
   msg1="there should be a package named <<component_name>>.zip in the <<product_version_dir>>"
   msg2="there should be a package named $component_name.zip in the $product_version_dir dir"
   file_to_test="$product_version_dir/$component_name.zip"
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"

   msg_title="test 2"
   msg1="there should be a script named <<TargetDir>>/<<target_component_name>>/<<target_component_name>>.sh"
   msg2="there should be a file named $target_dir/sfw/sh/$target_component_name/$target_component_name.sh"
   file_to_test="$target_dir/sfw/sh/$target_component_name/$target_component_name.sh"
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"

   msg_title="test 3"
   msg1="there should be a configuration file named :
	<<TargetDir>>/sfw/sh/<<target_component_name>>/<<target_component_name>>.<<target_host>>.conf"
   msg2="there should be a configuration file named : 
	$target_dir/sfw/sh/$target_component_name/$target_component_name.$target_host.conf"
   file_to_test="$target_dir/sfw/sh/$target_component_name/$target_component_name.$target_host.conf"
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"

   msg_title="test 4"
   msg1="The <<target_dir>>/sfw/sh/<<component_name>> dir should not exist, since .morph contains conversion for it - e.g. morphing is occuring"
   msg2="$target_dir/sfw/sh/$component_name not should exist, since morphing happens"
   dirToTest="$target_dir/sfw/sh/$component_name"
   doAssureIsNotDir "$msg_title" "$dirToTest" "$msg1" "$msg2"


   msg_title="test 5"
   msg1=" the product script the script should not contain any souce morphing rule "
   msg2=" the $target_dir/sfw/sh/$target_component_name/$target_component_name.sh should not contain the $component_name string "
   cmdToTest="grep -c $component_name $target_dir/sfw/sh/$target_component_name/$target_component_name.sh"
   doAssureCmdReturnsEqualToNumValue 0 "$msg_title" "$cmdToTest" "$msg1" "$msg2"

   echo " STOP TEST SUITE 2"
   echo "#------------------------------------------------------------------------"
}
#eof func doTestMorphingDeployment


# v2.0.8
#------------------------------------------------------------------------------
# tests deployment without morphing  
#------------------------------------------------------------------------------
doTestNonMorphingDeployment(){
   echo "#------------------------------------------------------------------------"
   echo " START TEST SUITE 4"
   echo "#------------------------------------------------------------------------"

   echo "#------------------------------------------------------------------------"
   echo " START doTestNonMorphingDeployment"
   echo " this test suit tests the deployment without product name conversion"
   echo "#------------------------------------------------------------------------"
   

   export target_component_name="$component_name"
   export product_owner="ysg"
   export target_product_owner="somebody"
   export target_host="host_name"
	export target_dir='/tmp'

   echo "Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" \
	-a create-package -a deploy-package -d "$target_dir"

   echo "Create the exclude file "
   echo "$component_name/robots.ini" > "$component_base_dir/$component_name/.exclude"
   echo "$component_name/tags" >> "$component_base_dir/$component_name/.exclude"
   echo "$component_name/.git" >> "$component_base_dir/$component_name/.exclude"
   echo "$component_name/tmp" >> "$component_base_dir/$component_name/.exclude"


   echo "Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" \
		-a create-package -a deploy-package -d "$target_dir"

   
   msg_title="test 1"
   msg1="there should be a package named <<component_name>>.zip in the <<product_version_dir>>"
   msg2="there should be a package named $component_name.zip in the $product_version_dir"
   file_to_test="$product_version_dir/$component_name.zip"
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"

   msg_title="test 2"
   msg1="there should be a dir named named <<target_component_name>> in the <<target_dir>>"
   msg2="there should be $target_dir/sfw/sh/$target_component_name " 
   dirToTest="$target_dir/sfw/sh/$target_component_name"
   doAssureIsDir "$msg_title" "$dirToTest" "$msg1" "$msg2"
   
   msg_title="test 3"
   msg1="there should be a script named <<TargetDir>>/sfw/sh/<<target_component_name>>/<<target_component_name>>.sh"
   msg2="there should be a file named $target_dir/$target_component_name/$target_component_name.sh"
   file_to_test="$target_dir/sfw/sh/$target_component_name/$target_component_name.sh"
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"

   msg_title="test 4"
   msg1="there should be a configuration file named :<<TargetDir>>/sfw/sh/<<target_component_name>>/<<target_component_name>>.<<target_host>>.conf"
   msg2="there should be a configuration file named : $target_dir/sfw/sh/$target_component_name/$target_component_name.$target_host.conf"
   file_to_test="$target_dir/sfw/sh/$target_component_name/$target_component_name.$target_host.conf"
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"

   msg_title="test 5"
   msg1="foreach file in the .exclude files there should be no file in the target product dir"
   msg2="there should not be a file named : $target_dir/$component_name/robots.ini"
   file_to_test="$target_dir/sfw/sh/$component_name/robots.ini"
   doAssureIsNotFile "$msg_title" "$file_to_test" "$msg1" "$msg2"

   msg_title="test 6"
   msg1="The <<target_dir>>/sfw/sh/<<component_name>> dir should exist, since no morphing happens"
   msg2="$target_dir/$component_name should exist, since no morphing happens"
   dirToTest="$target_dir/sfw/sh/$component_name"
   doAssureIsDir "$msg_title" "$dirToTest" "$msg1" "$msg2"
   
   msg_title="test 7"
   msg1=" the product script should contain the souce morphing rule "
   msg2=" the $target_dir/sfw/sh/$component_name/$component_name.sh should contain the $component_name string "
   cmdToTest="grep -c $component_name $target_dir/sfw/sh/$component_name/$component_name.sh"
   doAssureCmdReturnsGreaterThanNumValue 0 "$msg_title" "$cmdToTest" "$msg1" "$msg2"

   echo "#------------------------------------------------------------------------"
   echo " STOP TEST SUITE 4"
   echo "#------------------------------------------------------------------------"
}
#eof func doTestNonMorphingDeployment


# v2.0.8
#------------------------------------------------------------------------------
# tests deployment without morphing  
#------------------------------------------------------------------------------
doTestCreationOfDevelopmentPackage(){
   echo "#------------------------------------------------------------------------"
   echo " START doTestCreationOfDevelopmentPackage"
   echo " this test suit tests the creation of development zip package"
   echo "#------------------------------------------------------------------------"
   

   echo "Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" -a create-full-package 

   
   msg_title="test 1"
   msg1="there should be a zip package having the current timestamp in the target dir"
   msg2=""
	
	# ok this is oversimplications - it just check the lates	
	# and it will fail for the 59 minute of each hour ;)
   file_to_test=$(ls -1t $product_version_dir/$component_name.*.`date +%Y%m%d_%H`*.zip|head -n 1)
	echo file_to_test $file_to_test
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"


   echo "#------------------------------------------------------------------------"
   echo " STOP TEST SUITE 8"
   echo "#------------------------------------------------------------------------"
}
#eof func doTestCreationOfDevelopmentPackage 

# v2.0.8
#------------------------------------------------------------------------------
# tests deployment without morphing  
#------------------------------------------------------------------------------
doTestCreationOfTarPackage(){
   echo "#------------------------------------------------------------------------"
   echo " START doTestCreationOfTarPackage"
   echo " this test suit tests the creation of tar package"
   echo "#------------------------------------------------------------------------"
   
   ls -1t $product_version_dir/$component_name*.tar | xargs rm -fv

   echo "Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" -a create-tar-package 

   
   msg_title="test 1"
   msg1="there should be a tar package having the current timestamp in the target dir"
	# ok this is oversimplications - it just check the lates	
	# and it will fail for the 59 minute of each hour ;)
   file_to_test=$(ls -1t $product_version_dir/$component_name.*.`date +%Y%m%d_%H`*.tar|head -n 1)
   msg2="test that the file_to_test : $file_to_test exists "
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"


   echo "#------------------------------------------------------------------------"
   echo " STOP TEST SUITE 9"
   echo "#------------------------------------------------------------------------"
}
#eof func doTestCreationOfTarPackage 


# v2.0.8
#------------------------------------------------------------------------------
# do assure that the return code of a command is 0 and report 
#------------------------------------------------------------------------------
doAssureCmdReturnsGreaterThanNumValue(){

   export valueToCompare="$1"
   export msgTestTitle="$2"
   export cmdToTest="$3"
   export msg1="$4"
   export msg2="$5"

   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"

   cmdRet=$($cmdToTest)
   
   test $cmdRet -gt $valueToCompare && echo " $msgTestTitle --- ok"
   test $cmdRet -gt $valueToCompare || echo " $msgTestTitle --- NOK"
   
}
#eof func doAssureIsFile


# v2.0.8
#------------------------------------------------------------------------------
# do assure that the return code of a command is 0 and report 
#------------------------------------------------------------------------------
doAssureCmdReturnsEqualToNumValue(){

   export valueToCompare="$1"
   export msgTestTitle="$2"
   export cmdToTest="$3"
   export msg1="$4"
   export msg2="$5"

   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"
   
   cmdRet=1
   cmdRet=$($cmdToTest)
   
   test $cmdRet -eq $valueToCompare && echo " $msgTestTitle --- ok"
   test $cmdRet -eq $valueToCompare || echo " $msgTestTitle --- NOK"
   
}
#eof func doAssureCmdReturnsEqualToNumValue


# v2.0.8
#------------------------------------------------------------------------------
# the tester should assure the visual output from the cmd 
# by knowing which is the command
#------------------------------------------------------------------------------
doAssureCmdOutputVisually(){

   export msgTestTitle="$1"
   export cmdToTest="$2"
   export msg1="$3"
   export msg2="$4"
   
   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"
   echo " running the following cmdToTest : $cmdToTest"
   echo $($cmdToTest)
   
}
#eof func doAssureIsFile


# v2.0.8
#------------------------------------------------------------------------------
# assures a file is a file and prints result if yes or not 
#------------------------------------------------------------------------------
doAssureIsFile(){

   export msgTestTitle="$1"
   export file_to_test="$2"
   export msg1="$3"
   export msg2="$4"
   
   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"

   test -f $file_to_test && echo " $msgTestTitle --- ok"
   test -f $file_to_test || echo " $msgTestTitle --- NOK"
  	
	# now present the file stats
   test -f $file_to_test && stat -c "%y %n " $file_to_test
}
#eof func doAssureIsFile


# v2.0.8
#------------------------------------------------------------------------------
# assures a file is a file and prints result if yes or not 
#------------------------------------------------------------------------------
doAssureIsLink(){

   msgTestTitle="$1"
   file_to_test="$2"
   msg1="$3"
   msg2="$4"
   
   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"

   test -L $file_to_test && echo " $msgTestTitle --- ok"
   test -L $file_to_test || echo " $msgTestTitle --- NOK"
   
}
#eof func doAssureIsLink


# v2.0.8
#------------------------------------------------------------------------------
# assures a link is a link and prints result if yes or not 
#------------------------------------------------------------------------------
doAssureIsNotLink(){

   msgTestTitle="$1"
   file_to_test="$2"
   msg1="$3"
   msg2="$4"
   
   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"

   test -L $file_to_test || echo " $msgTestTitle --- ok"
   test -L $file_to_test && echo " $msgTestTitle --- NOK"
   
}
#eof func doAssureIsNotLink


# v2.0.8
#------------------------------------------------------------------------------
# assures a file is not a file and prints result if yes or not 
#------------------------------------------------------------------------------
doAssureIsNotFile(){

   export msgTestTitle="$1"
   export file_to_test="$2"
   export msg1="$3"
   export msg2="$4"
   
   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"

   test -f $file_to_test || echo " $msgTestTitle --- ok"
   test -f $file_to_test && echo " $msgTestTitle --- NOK"
   
}
#eof func doAssureIsNotFile


# v2.0.8
#------------------------------------------------------------------------------
# assure that the dir passed exists and print the result
#------------------------------------------------------------------------------
doAssureIsDir(){

   export msgTestTitle="$1"
   export dirToTest="$2"
   export msg1="$3"
   export msg2="$4"
   
   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"
   echo " $msgTestTitle --- the dirToTest is $dirToTest"
   test -d $dirToTest && echo " $msgTestTitle --- ok"
   test -d $dirToTest || echo " $msgTestTitle --- NOK"
   
}
#eof func doAssureIsDir


# v2.0.8
#------------------------------------------------------------------------------
# assure that the passed dir does not exist  
#------------------------------------------------------------------------------
doAssureIsNotDir(){

   export msgTestTitle="$1"
   export dirToTest="$2"
   export msg1="$3"
   export msg2="$4"
   
   shift "$#"

   echo " $msgTestTitle --- "
   echo " $msgTestTitle --- $msg1" 
   echo " $msgTestTitle --- $msg2"

   test -d $dirToTest || echo " $msgTestTitle --- ok"
   test -d $dirToTest && echo " $msgTestTitle --- NOK"
   
}
#eof func doAssureIsNotDir


# v2.0.8
#------------------------------------------------------------------------------
# assure that the passed dir does not exist  
#------------------------------------------------------------------------------
doTestCreateCtags(){

   echo "#------------------------------------------------------------------------"
   echo " START doTestCreateCtags"
   echo " this test suit tests the creation of tags file"
   echo "#------------------------------------------------------------------------"
   
   file_to_test="$product_version_dir/tags"
	test -f $file_to_test && rm -fv $file_to_test 
   echo "Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" -a create-ctags
   
   msg_title="test 1"
   msg1="there should be a tags file in the product_version_dir: "
   msg2=""
   doAssureIsFile "$msg_title" "$file_to_test" "$msg1" "$msg2"

   echo "#------------------------------------------------------------------------"
   echo " STOP doTestCreateCtags"
   echo "#------------------------------------------------------------------------"
   
}
#eof func doTestCreateCtags


# v2.0.8
#------------------------------------------------------------------------------
# ensure the -a create-link -l <<links_base_dir>> works ok
#------------------------------------------------------------------------------
doTestCreateLinkOk(){

   echo "#------------------------------------------------------------------------"
   echo " START doTestCreateLinkOk"
   echo " ensure the -a create-link -l <<links_base_dir>> works ok"
   echo "#------------------------------------------------------------------------"
   
   echo "Action!!!"
	file_to_test=/tmp/sfw/sh/$component_name.sh
	rm -vf $file_to_test

   bash "$component_base_dir/$component_name/$component_name.sh" -a create-link \
	-l /tmp
  	
   msg_title="test 1"
   msg1="there should be a link file pointing to the component_name.sh file"
   msg2=""
   doAssureIsLink "$msg_title" "$file_to_test" "$msg1" "$msg2"

   echo "#------------------------------------------------------------------------"
   echo " STOP doTestCreateLinkOk"
   echo "#------------------------------------------------------------------------"
   
}
#eof func doTestCreateLinkOk


# v2.0.8
#------------------------------------------------------------------------------
# ensure the -a create-link -l <<links_base_dir>> works ok
#------------------------------------------------------------------------------
doTestCreateLinkNok(){

   echo "#------------------------------------------------------------------------"
   echo " START doTestCreateLinkNok"
   echo " ensure the -a create-link -l <<links_base_dir>> fails if no link is passed"
   echo "#------------------------------------------------------------------------"
   
	file_to_test=/tmp/sfw/sh/$component_name.sh
	rm -vf $file_to_test

   echo "Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" -a create-link
	
  	

   msg_title="test 1"
   msg1="there should NOT be a link file pointing to the component_name.sh file"
   msg2=""
   doAssureIsNotLink "$msg_title" "$file_to_test" "$msg1" "$msg2"

   echo "#------------------------------------------------------------------------"
   echo " STOP doTestCreateLinkNok"
   echo "#------------------------------------------------------------------------"
   
}
#eof func doTestCreateLinkNok


# v2.0.8
#------------------------------------------------------------------------------
# test with the product version dir site
#------------------------------------------------------------------------------
doTestDocsGenerationForProject(){

		
	echo "first update the latest html to all the projects"
   #bash "$component_base_dir/$component_name/$component_name.sh" -a update-project-sites

	project_dir="$project_dir"
	project=`basename $project_dir`
	
	test -z "$1" || export lang_code=$1
	test -z "$lang_code" && export lang_code=en

	#issue-317
	rm -fv "$project_dir/docs/site/html/$project/$lang_code/"*
	rm -fv "$project_dir/docs/site/pdf/$project/$lang_code/"*

	#remove the test files as well
	for page_type in `echo "status" "doc"`; do (
		rm -fv $project_dir/conf/hosts/$host_name/lst/$project/"$page_type"-pages.lst
		rm -fv $project_dir/conf/hosts/$host_name/lst/$project/"$page_type"-pdfs.lst
	);
	done

   echo "Run generate the html docs Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" -c $lang_code \
	-p $project_dir


	for page_type in `echo "status" "doc"`; do (
		for page in `cat $project_dir/conf/hosts/$host_name/lst/$project/"$page_type"-pages.lst`; do (
			file_to_test1="$project_dir/docs/site/html/$project/$lang_code/$page"'.html'

			echo " ensure that the doc index html file : $file_to_test1 is generated"
			echo "#------------------------------------------------------------------------"
			
			echo "#------------------------------------------------------------------------"
			echo " ensure that the status index html file : $file_to_test2 is generated"
			echo "#------------------------------------------------------------------------"
			


			msg_title="$page_type : test 1"
			msg1="there should be a generated status $page_type html file "
			msg2="if the there is not the test has failed "

			doAssureIsFile "$msg_title" "$file_to_test1" "$msg1" "$msg2"

			echo -e "\n\n"
			echo " the both files should be visible trough the browser as well"
			url1=$(echo $file_to_test1|perl -nle 's|\/vagrant|file\:/\/\/C\:\/var|g;print')
			
			echo -e "\n\n"
			echo "you could see the files in your browser by : "
			echo "chrome $url1"

			echo -e "\n\n"

			#flush the screen
			printf "\033[2J";printf "\033[0;0H"
			);
			done

		for page in `cat $project_dir/conf/hosts/$host_name/lst/$project/"$page_type"-pdfs.lst`; do (
			file_to_test1="$project_dir/docs/site/pdf/$project/$lang_code/$page"'.pdf'

			echo "#------------------------------------------------------------------------"
			echo " ensure that the doc index html file : $file_to_test1 is generated"
			echo "#------------------------------------------------------------------------"
			
			msg_title="$page_type : test 1"
			msg1="there should be a generated status $page_type html file "
			msg2="if the there is not the test has failed "

			doAssureIsFile "$msg_title" "$file_to_test1" "$msg1" "$msg2"

			echo -e "\n\n"
			echo " the both files should be visible trough the browser as well"
			url1=$(echo $file_to_test1|perl -nle 's|\/vagrant|file\:/\/\/C\:\/var|g;print')
			
			echo -e "\n\n"
			echo "you could see the files in your browser by : "
			echo "chrome $url1"

			echo -e "\n\n"

			#flush the screen
			printf "\033[2J";printf "\033[0;0H"
			);
			done
		);
		done

	# regenerate the uri list for the current language
   bash "$component_base_dir/$component_name/$component_name.sh" -a generate-uri-list

   echo "#------------------------------------------------------------------------"
   echo " STOP doTestDocsGenerationFor$project"
   echo "#------------------------------------------------------------------------"
	echo -e "\n\n"
   
}
#eof func doTestDocsGenerationFor$project


# v2.0.8
#------------------------------------------------------------------------------
# test with the product version dir site
#------------------------------------------------------------------------------
doTestDocsGeneration(){
	
   echo "#------------------------------------------------------------------------"
   echo `date "+%Y-%m-%d %H:%M:%S"` " START doTestDocsGeneration "
	
	test -z "$1" || export lang_code=$1
	test -z "$lang_code" && export lang_code=en

	#ensure the lang_code 
	echo test-isg-pub lang_code is $lang_code

	rm -fv "$product_version_dir/docs/site/html/isg-pub/$lang_code/"*
	rm -fv "$product_version_dir/docs/site/pdf/isg-pub/$lang_code/"*


	for page_type in `echo "status" "doc"`; do (
		rm -fv $product_version_dir/conf/hosts/$host_name/lst/isg-pub/"$page_type"-pages.lst
	);
	done

   echo "Run generate the html docs Action!!!"
   bash "$component_base_dir/$component_name/$component_name.sh" -c $lang_code
	
	echo regenerate the uri list for the current language
   bash "$component_base_dir/$component_name/$component_name.sh" -a generate-uri-list 2>&1 >/dev/null &

	#flush the screen
	printf "\033[2J";printf "\033[0;0H"

   echo "START the file tests "
	for page_type in `echo "status" "doc"`; do (
		for page in `cat $product_version_dir/conf/hosts/$host_name/lst/isg-pub/"$page_type"-pages.lst`; do (
			file_to_test1="$product_version_dir/docs/site/html/isg-pub/$lang_code/$page"'.html'

			echo "#------------------------------------------------------------------------"
			echo " ensure that the doc index html file : $file_to_test1 is generated"
			echo "#------------------------------------------------------------------------"

			msg_title="$page_type : test 1"
			msg1="there should be a generated status $page_type html file "
			msg2="if the there is not the test has failed "

			doAssureIsFile "$msg_title" "$file_to_test1" "$msg1" "$msg2"
			
			echo -e "\n\n"
			echo " the both files should be visible trough the browser as well"
			url1=$(echo $file_to_test1|perl -nle 's|\/vagrant|file\:/\/\/C\:\/var|g;print')
			
			echo -e "\n\n"
			echo "you could see the files in your browser by : "
			echo "chrome $url1"

			echo -e "\n\n"

			#flush the screen
			printf "\033[2J";printf "\033[0;0H"
			
		);
		done

		test -f $product_version_dir/conf/hosts/$host_name/lst/isg-pub/"$page_type"-pdfs.lst || continue
		for page in `cat $product_version_dir/conf/hosts/$host_name/lst/isg-pub/"$page_type"-pdfs.lst`; do (
			file_to_test1="$product_version_dir/docs/site/pdf/isg-pub/$lang_code/$page"'.pdf'

			echo "#------------------------------------------------------------------------"
			echo " ensure that the doc index html file : $file_to_test1 is generated"
			echo "#------------------------------------------------------------------------"


			msg_title="$page_type : test 1"
			msg1="there should be a generated status $page_type html file "
			msg2="if the there is not the test has failed "

			doAssureIsFile "$msg_title" "$file_to_test1" "$msg1" "$msg2"
			

			echo " the both files should be visible trough the browser as well"
			url1=$(echo $file_to_test1|perl -nle 's|\/vagrant|file\:/\/\/C\:\/var|g;print')
			
			echo -e "\n\n"
			echo "you could see the files in your browser by : "
			echo "chrome $url1"

			echo -e "\n\n"

			#flush the screen
			printf "\033[2J";printf "\033[0;0H"
			
		);
		done
	);
	done

   echo "STOP  the file tests "


   echo "#------------------------------------------------------------------------"
   echo " STOP doTestDocsGenerationForProject"
   echo "#------------------------------------------------------------------------"
   
	#flush the screen
	printf "\033[2J";printf "\033[0;0H"
}
#eof func doTestDocsGeneration


# v2.0.8
#------------------------------------------------------------------------------
# test runs the application of sql scripts for one language
# issue-258
#------------------------------------------------------------------------------
doTestRunMySqlScripts(){
	
   echo "#------------------------------------------------------------------------"
   echo `date "+%Y-%m-%d %H:%M:%S"` " START doTestDocsGeneration "
	
	test -z "$1" || export lang_code=$1
	test -z "$lang_code" && export lang_code=en

	#ensure the lang_code 
	echo test-isg-pub lang_code is $lang_code

   echo "apply all the sql scripts"
   bash "$component_base_dir/$component_name/$component_name.sh" -c $lang_code -a 'run-project-mysql-scripts'
	
	#flush the screen
	printf "\033[2J";printf "\033[0;0H"


   echo "#------------------------------------------------------------------------"
   echo " STOP doTestDocsGenerationForProject"
   echo "#------------------------------------------------------------------------"
   
	printf "\033c"
}
#eof func doTestDocsGeneration


#
# v2.0.8
#------------------------------------------------------------------------------
# cleans the unneeded during after run-time stuff 
#------------------------------------------------------------------------------
doPrintHelp(){

   cat <<END_HELP    

   #------------------------------------------------------------------------------
   ## START HELP `basename $0`
   #------------------------------------------------------------------------------
   
   # Usage:
   #------------------------------------------------------------------------------
   # sh $0

   #------------------------------------------------------------------------------
   ## STOP HELP `basename $0`
   #------------------------------------------------------------------------------

END_HELP
}
#eof func doPrintHelp


# v2.0.8
#------------------------------------------------------------------------------
# the main call, uncomment the suite methods to run only one suite at the time
#------------------------------------------------------------------------------
main(){
   
   case $1 in "-?"|"--?"|"-h"|"--h"|"-help"|"--help")\
            doSetVars;doPrintHelp ; exit 0 ; 
   ;;esac
   doSetVars
   
   echo "###############################################################"
   echo " START TESTING"
	
#  doTestHelp
#  sleep 2
#   
#  doTestMorphingDeployment
#  sleep 2
#   
#  doTestNonMorphingDeployment
#  sleep 2
#
#  doTestCreationOfDevelopmentPackage 
#  sleep 2
#
#  doTestCreationOfTarPackage 
#  sleep 2
#
#  doTestCreateCtags
#  sleep 2
#
#  doTestCreateLinkOk
#  sleep 2
#   
#  doTestCreateLinkNok
#  sleep 2

	test -z $project_dir && doTestDocsGeneration

	test -z $project_dir || doTestDocsGenerationForProject

#	doTestRunMySqlScripts
#	sleep 2
	echo " STOP TESTING"
   echo "###############################################################"
   exit 0
}
#eof func main 


#Action !!!
main


#
# Purpose
#------------------------------------------------------------------------------
# To test and validate the functionalities of the isg-pub.sh component
#
# Usage:
#------------------------------------------------------------------------------
# sh $0
#
# VersionHistory
#------------------------------------------------------------------------------
# 2.0.9 --- 2014-08-10 13:34:18 --- ysg --- issue-258
# 2.0.8 --- 2014-06-17 22:29:35 --- ysg --- added project dir testing
# 2.0.7 --- 2014-05-24 11:03:20 --- ysg --- added create-link
# 2.0.3 --- 2014-05-03 09:12:28 --- ysg --- fixed bug with bootstrap conf file
# 2.0.8 --- 2013-09-20 22:05:08 --- ysg --- removed bootstrapping, now is build in
# 1.8.7 --- 2013-05-11 09:13:30 --- ysg --- added -s token-to-search¤token-to-replace arg
# 1.8.6 --- 2013-05-11 09:13:30 --- ysg --- added -s token-to-search¤token-to-replace arg
# 1.7.9 --- 2013-03-17 18:56:33 --- ysg --- added os independant hostname interpolation
# 1.4.0 --- 2013-03-14 12:53:21 --- ysg --- all test runs on 10952J659628 ok
# 1.3.2 --- 2013-03-14 11:56:39 --- ysg --- doTestHelp
# 1.3.1 --- 2013-02-01 22:14:01 --- ysg --- changed -t to -d
# 1.3.0 --- 2013-01-30 12:28:47 --- ysg --- added doAssure... (file,dir,value) methods 
# 1.2.0 --- 2013-01-30 09:10:02 --- ysg --- more parametrization, fixed bug with namign
# 1.1.0 --- 2013-01-28 10:43:01 --- ysg --- docs generalize component_name , component_dir
# 1.0.0 --- 2013-01-27 10:43:01 --- ysg --- Initial creation , parametrization
# 
#eof file:test-isg-pub.sh
