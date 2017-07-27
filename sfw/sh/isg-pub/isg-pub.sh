#!/bin/bash
# file: isg-pub.sh v0.5.1.4
umask 022    ; 

# print the commands 
# set -x
# print each input line as well
# set -v
# exit the script if any statement returns a non-true return value. gotcha !!!
# set -e 
trap 'doExit $LINENO $BASH_COMMAND; exit' SIGHUP SIGINT SIGQUIT

# v0.9.2
#------------------------------------------------------------------------------
# register the run-time vars before the call of the $0
#------------------------------------------------------------------------------
doInit(){
   call_start_dir=`pwd` 
   component_dir=`dirname $(readlink -f $0)`
   tmp_dir="$component_dir/tmp/.tmp.$$"
   mkdir -p "$tmp_dir"
   ( set -o posix ; set ) >"$tmp_dir/vars.before"
   my_name_ext=`basename $0`
   component_name=${my_name_ext%.*}
   test $OSTYPE != 'cygwin' && host_name=`hostname -s`
   test $OSTYPE == 'cygwin' && host_name=`hostname`
}
#eof doInit


# v0.9.2
#------------------------------------------------------------------------------
# set the variables from the $0.$host_name.conf file which has ini like syntax
#------------------------------------------------------------------------------
doSetVars(){
   cd $component_dir
   cd ..; component_base_dir=`pwd`

   for i in {1..2} ; do cd .. ;done ;
   export product_version_dir=`pwd`;

	# this will be dev , tst, prd	
	product_type=$(echo `basename "$product_version_dir"`|cut --delimiter='.' -f5)
	environment_name=$(basename "$product_version_dir")
   
	cd .. 
   product_dir=`pwd`;

	cd .. 
   product_base_dir=`pwd`;

   cd "$component_dir/"
   doParseIniFile 
   ( set -o posix ; set ) >"$tmp_dir/vars.after"
   doLog "
   #----------------------------------------------------------
  	# = START MAIN = $component_name
   #----------------------------------------------------------
   "
   exit_code=1
	doLog "
	
	"
   doLog " [INFO ] == START == printing isg-pub.sh script vars :"
   cmd="$(comm --nocheck-order -3 $tmp_dir/vars.before $tmp_dir/vars.after | perl -ne 's#\s+##g;print "\n $_ "' )"
	doLog " $cmd " 
   doLog " [INFO ] == STOP  == printing isg-pub.sh script vars :"
	doLog "
	
	"

	# now set the current component version to the platform ini file

	# conf/hosts/doc-pub-host/ini/isg-pub.doc-pub-host.ini
	perl -pi -e "s|PlatformVersion=(.*)|PlatformVersion=$component_version|g;" $product_version_dir/conf/hosts/$host_name/ini/isg-pub.$host_name.ini

	# and clear the screen
	printf "\033[2J";printf "\033[0;0H"
}
#eof func doSetVars


# v0.9.2
#------------------------------------------------------------------------------
# parse the ini like $0.$host_name.conf and set the variables
# cleans the unneeded during after run-time stuff. Note the MainSection
#------------------------------------------------------------------------------
doParseIniFile(){
	# set a default ini file
	ini_file="$component_dir/$component_name.conf"

	# however if there is a host dependant ini file override it 
   test -f "$component_dir/$component_name.$host_name.conf" \
		&& ini_file="$component_dir/$component_name.$host_name.conf"
	
	# create a default host dependant ini file if non exists
   test -f "$ini_file" || \
   	cp -v "$component_dir/$component_name.host_name.conf" "$ini_file"
	
	# yet finally override if passed as param
	# if the the ini file is not passed define the default host independant ini file
   test -z "$1" || ini_file=$1;shift 1;
	#debug echo "@doParseIniFile ini_file:: $ini_file"

   eval `sed -e 's/[[:space:]]*\=[[:space:]]*/=/g' \
      -e 's/;.*$//' \
      -e 's/[[:space:]]*$//' \
      -e 's/^[[:space:]]*//' \
      -e "s/^\(.*\)=\([^\"']*\)$/\1=\"\2\"/" \
      < $ini_file \
      | sed -n -e "/^\[MainSection\]/,/^\s*\[/{/^[^;].*\=.*/p;}"`
}
#eof func doParseIniFile


# v0.9.2
#------------------------------------------------------------------------------
# parse the single letter command line args 
#------------------------------------------------------------------------------
doParseCmdArgs(){

	# traverse all the possible cmd args 
	while getopts ":a:c:d:h:i:j:l:p:s:q:" opt; do
	  case $opt in
		a)
			actions="$actions$OPTARG "
			;;
		c)
			export lang_code="$OPTARG"
			;;
		d)
			target_dir="$OPTARG"
			;;
		h)
			doPrintHelp
			;;
		i)
			# this is the file holding the full paths on the installation dirs
			# foreach line containing installation dir
			# the correspondend install-files-<<line_number>> is read
			export install_file="$OPTARG"
			;;
		j)
			test -z "$project" && export project="$OPTARG"
			;;
		s)
			echo "OPTARG IS $OPTARG"
			test -z "$search_and_replace_pairs" && rm -vf "$component_dir/.morph"
			# obs! the new line after the optarg !!!
			search_and_replace_pairs="$search_and_replace_pairs$OPTARG"$'\n'
			#' this is only for the silly quoting parser in my editor
			# [DEBUG] echo "search_and_replace_pairs is $search_and_replace_pairs"
			;;
		l)
			links_base_dir="$OPTARG"
			;;
		q)
			sql_dir="$OPTARG"
			;;
		p)
			export project_version_dir="$OPTARG"
			;;
		\?)
			doExit 2 "Invalid option: -$OPTARG"
			;;
		:)
			doExit 2 "Option -$OPTARG requires an argument."
			;;
	  esac
	done
}
#eof func doParseCmdArgs


#
# v0.9.2
#------------------------------------------------------------------------------
# perform the checks to ensure that all the vars needed to run are set 
#------------------------------------------------------------------------------
doCheckReadyToStart(){
   
   test -f $ini_file || doExit 3 "Cannot find ini_file : $ini_file" 
   test -z $target_dir && target_dir='.'
	
	
	#debug echo 1-@doCheckReadyToStart ini_file: proj_version_dir : $proj_version_dir ; sleep 2
	#debug 1-@doCheckReadyToStart ini_file: project : $project ; sleep 2
	
	# if we are not running external project do internally ...
	test -z $proj_version_dir \
		&& export $proj_version_dir=$product_version_dir
	
	#debug echo 2-@doCheckReadyToStart ini_file: proj_version_dir : $proj_version_dir ; sleep 2
	#debug echo 2-@doCheckReadyToStart ini_file: project : $project ; sleep 2

	proj_conf_file="$component_dir/$component_name.$project.$host_name.conf" \
		&& doParseIniFile "$proj_conf_file" \

	#debug echo 3-@doCheckReadyToStart ini_file: proj_version_dir : $proj_version_dir ; sleep 2
	#debug echo 3-@doCheckReadyToStart ini_file: project : $project ; sleep 2

	
	test -z "$lang_code" && lang_code='en'
	mkdir -p $proj_version_dir/docs/site/pdf/$project/$lang_code
		
	# set the project_db related db variables
	ini_file="$proj_version_dir/conf/hosts/$host_name/ini/mariadb.$host_name.ini"
	
	# set the connection vars from the ini vars - db , user , pass 
	doParseIniFile "$ini_file"

	#debug echo @doCheckReadyToStart ini_file: $ini_file ; sleep 10
	
	export lang_code=$lang_code
	export proj_lang_db="$proj_alias"'_'"$lang_code"

	#sleep 10
   test -z $include_file \
		&& export include_file="$proj_version_dir/meta/components/$project/.include"
   #define default vars 
   test -z $gen_include_file \
      && export gen_include_file="$proj_version_dir/meta/components/$project/.gen-include"
	
	doLog "@doCheckReadyToStart project::$project"
	doLog "@doCheckReadyToStart proj_alias::$proj_alias"
	doLog "@doCheckReadyToStart proj_conf_file:: $proj_conf_file"
	doLog "@doCheckReadyToStart proj_lang_db:: $proj_lang_db"
	sleep 3
}
#eof func doCheckReadyToStart


# v0.9.2
#------------------------------------------------------------------------------
# echo pass params and print them to a log file and terminal
# with timestamp and $host_name and $0 PID
#------------------------------------------------------------------------------
doLog(){
   type_of_msg=$1
   [[ $type_of_msg == *\[DEBUG\]* ]] && [[ $do_print_debug_msgs -ne 1 ]] && return

   # print to the terminal if we have one
   test -t 1 && echo "`date +%Y.%m.%d-%H:%M:%S` [@$host_name] [$$] $*"

   # define default log file none specified in conf file
   test -z $log_file && log_file="$component_dir/$component_name.`date +%Y%m`.log"
   echo "`date +%Y.%m.%d-%H:%M:%S` [@$host_name] [$$] $*" >> $log_file
}
#eof func doLog


# v0.9.2
#------------------------------------------------------------------------------
# run a command and log the call and its output to the log_file
# doPrintHelp: doRunCmdAndLog "$cmd"
#------------------------------------------------------------------------------
doRunCmdAndLog(){
  cmd="$*" ; 
  doLog " [DEBUG] running cmd and log: \"$cmd\""
   
   msg=$($cmd 2>&1)
   ret_cmd=$?
   error_msg="ERROR : Failed to run the command \"$cmd\" with the output \"$msg\" !!!"
   
   [ $ret_cmd -eq 0 ] || doLog "$error_msg"
   doLog " [DEBUG] : cmdoutput : \"$msg\""
}
#eof func doRunCmdAndLog


# v0.9.2
#------------------------------------------------------------------------------
# run a command on failure exit with message
# doPrintHelp: doRunCmdOrExit "$cmd"
# call by: 
# set -e ; doRunCmdOrExit "$cmd" ; set +e
#------------------------------------------------------------------------------
doRunCmdOrExit(){
   cmd="$*" ; 
   
   doLog " [DEBUG] running cmd or exit: \"$cmd\""
   msg=$($cmd 2>&1)
   ret_cmd=$?
   # if error occured during the execution exit with error
   error_msg="ERROR : FATAL : Failed to run the command \"$cmd\" with the output \"$msg\" !!!"
   [ $ret_cmd -eq 0 ] || doExit "$ret_cmd" "$error_msg"
   
   #if no error occured just log the message
   doLog " [DEBUG] : cmdoutput : \"$msg\""
}
#eof func doRunCmdOrExit


# v0.9.2
#------------------------------------------------------------------------------
# sends an e-mail with the latest n configured lines from the log
#------------------------------------------------------------------------------
doSendReport(){

   doLog " START function ======= doSendReport"



   test $exit_code -ne 0 && Emails="$EmailsOnFatalError"
   test -z $log_file_lines_number && log_file_lines_number=400
   # if there are no e-mails to send just return
   test -z $Emails && return 1

   # create a smaller log file in the tmp dir  - avoid getting into mail black lists ...
   export small_tmp_log=$tmp_dir/`basename $log_file`
   tail -n $log_file_lines_number $log_file > $small_tmp_log

	mutt --help >/dev/null 2>&1 || 
      { doLog "[ERROR] mutt not installed or not in PATH." >&2; 
		
			for Email in $Emails; do (
				mutt -s "tail -n $log_file_lines_number $log_file" -a "$small_tmp_log" "$Email" < $small_tmp_log
			);
			done
			return	
		}

   for Email in $Emails; do (
      cat $small_tmp_log | mutt -s "tail -n $log_file_lines_number $log_file" -a $small_tmp_log $Email
   );
   done
   
   doLog " STOP function ======= doSendReport"
}
#eof func doSendReport


# v0.9.2
#------------------------------------------------------------------------------
# cleans the unneeded during after run-time stuff 
# do put here the after cleaning code 
#------------------------------------------------------------------------------
doCleanAfterRun(){
   # remove the temporary dir and all the stuff bellow it
   cmd="rm -fvr $tmp_dir"
   doRunCmdAndLog "$cmd"
   find "$component_dir" -type f -name '*.bak' -exec rm -f {} \;
}
#eof func doCleanAfterRun


# v0.9.2
#------------------------------------------------------------------------------
# clean and exit with passed status and message
#------------------------------------------------------------------------------
doExit(){

   exit_code=0 
   exit_msg="$*"

   case $1 in [0-9]) 
      exit_code="$1";
      shift 1;
   esac 

   if [ "$exit_code" != 0 ] ; then
      exit_msg=" ERROR --- exit_code $exit_code --- exit_msg : $exit_msg" 
      echo "$Msg" >&2
      doSendReport
   fi

   doCleanAfterRun
	
	# if we were interrupted while creating a package delete the package	
	test -z $flag_completed || test $flag_completed -eq 0 \
			&& test -f $zip_file && rm -vf $zip_file

	#flush the screen
	printf "\033[2J";printf "\033[0;0H"
   doLog " $exit_msg" 
   echo -e "\n\n"

   exit $exit_code
}
#eof func doExit


#
#------------------------------------------------------------------------------
# create a zip package by adding all the relative file paths specified 
# in the deployment file. You could omit some files from your .inlude file by:
# cat meta/components/$compoenent_name/.include | grep -v str_to_exclude
#------------------------------------------------------------------------------
doCreatePackage(){

	doLog "[DEBUG] START doCreatePackage"
	pushd . 
	
	cd $product_version_dir

	deploy_file=$product_version_dir/meta/components/$component_name/.deploy-include
	for file in `cat $deploy_file` ; do (
		test -f $file && zip $component_name.zip $file	

	);
	done

	popd
	doLog "[DEBUG] STOP doCreatePackage"
}
#eof func doCreatePackage


#
#------------------------------------------------------------------------------
# do deploy the package , do search and replace if any morph rules are specified
#------------------------------------------------------------------------------
doDeployPackage(){
	
	pushd .

	doLog "[DEBUG] START doDeployPackage"
	deploy_tmp_dir="$os_tmp_dir/.$component_name/.$$"	

	# if no morphing is involved just unpack
   test -z "$search_and_replace_pairs" && \
			unzip -o "$product_version_dir/$component_name.zip" -d "$target_dir"

  	# and return from here  
	test -z "$search_and_replace_pairs" && return

	#if morphing is involved than first search and replace in deploy_tmp_dir
   set -e ; test -z "$deploy_tmp_dir" && \
			doExit 3 " failed to create deploy_tmp_dir: $deploy_tmp_dir"

	cmd="mkdir -p $deploy_tmp_dir/"
 	set -e ; doRunCmdOrExit "$cmd" ; set +e

	# Action !!!	
	unzip -o "$product_version_dir/$component_name.zip" -d "$deploy_tmp_dir/"

	cd "$deploy_tmp_dir/" || doExit "cannot cd to deploy_tmp_dir : $deploy_tmp_dir"

   test -z "$search_and_replace_pairs" || \
			echo "$search_and_replace_pairs" > "$component_dir/.morph"

	doLog "search_and_replace_pairs: $search_and_replace_pairs"

	for morph_rule in `cat "$component_dir/.morph"` ; do (
		# define what to search and what to replace
		#v2.0.1 to_srch=$(echo $morph_rule|cut --delimiter=¤ -f 1)
		#v2.0.1 to_repl=$(echo $morph_rule|cut --delimiter=¤ -f 2)

		to_srch=$(echo $morph_rule|perl -nle 'm/(.*)¤(.*)/g;print $1')
		to_repl=$(echo $morph_rule|perl -nle 'm/(.*)¤(.*)/g;print $2')

		doLog "morph_rule: $morph_rule"	
		doLog "to_srch: $to_srch"
		doLog "to_repl: $to_repl"

		#search and repl %var_id% with var_id_val in deploy_tmp_dir 
		find . -type d |\
		perl -nle '$o=$_;s#'"$to_srch"'#'"$to_repl"'#g;$n=$_;`mkdir -p $n` ;'
		find . -type f |\
		perl -nle '$o=$_;s#'"$to_srch"'#'"$to_repl"'#g;$n=$_;rename($o,$n) unless -e $n ;'

		#and search and replace in the files as well 
		find . -type f -exec perl -pi -e "s#$to_srch#$to_repl#g" {} \;
		find . -type f -name '*.bak' | xargs rm -f

	);
	done


	# after the search and replace we need to re-create the zip package
	for file in `find . -type f` ; do (
		test -f $file && zip $component_name.zip $file	
	);
	done
	
	#todo after test specify this as .
   set -e ; test -z "$target_dir" && doExit 3 " no deploy dir specified to deploy package"

	cmd="mkdir -p $dir_target/"
 	set -e ; doRunCmdOrExit "$cmd" ; set +e

	# Action !!!	
	unzip -o "$deploy_tmp_dir/$component_name.zip" -d "$target_dir/"

	cmd="rm -fvr $deploy_tmp_dir/"
 	#set -e ; doRunCmdOrExit "$cmd" ; set +e

	popd .
	doLog "[DEBUG] STOP doDeployPackage"
}
#eof func doDeployPackage


# v0.9.2
#------------------------------------------------------------------------------
# deploys the package to a desired dest dir , with desired morphing
#------------------------------------------------------------------------------
doMorphDir(){

   test -z "$search_and_replace_pairs" || \
			echo "$search_and_replace_pairs" > "$component_dir/.morph"

   for morph_rule in `cat "$component_dir/.morph"` ; do (
      # define what to search and what to replace
      to_search=$(echo $morph_rule | cut -d ¤ -f 1)
      to_replace=$(echo $morph_rule | cut -d ¤ -f 2)
      
      cmd="cp -rv $target_dir/$to_search $target_dir/$to_replace"
      doRunCmdAndLog "$cmd"
      
      # rename the files 
      find "$target_dir/$to_replace"  | \
      perl -nle'$o=$_;s#^(.*)('"$to_search"')(.*)#$1'"$to_replace"'$3#g;$n=$_;rename($o,$n) unless -e $n ;'
  
       # find and replace in files 
      find "$target_dir/$to_replace" -type f -exec perl -pi -e 's#'"$to_search"'#'"$to_replace"'#g' {} \;
     
      # remove the tmp files
      find "$target_dir/$to_replace" -name '*.bak' | xargs rm -f

   );
   done

}
#eof func doMorphDir


#
#------------------------------------------------------------------------------
# runs procs in parallel on a file set from the the find command 
#------------------------------------------------------------------------------
doRunProcsInParallel(){
   cmd="zgrep $str_to_grep '{}' >> $file_filtered_results"
   find ${DirFindRoot} -type f  -name ${nameFilter} -print0 | xargs -0 -I '{}' sh -c "$cmd"
}
#eof func doRunProcsInParallel


# v0.9.2
#------------------------------------------------------------------------------
# cleans the unneeded during after run-time stuff 
#------------------------------------------------------------------------------
doPrintHelp(){

	printf "\033[2J";printf "\033[0;0H"

   test -z $target_dir && target_dir='<<target_dir>>'
   
   cat <<END_HELP    

   #------------------------------------------------------------------------------
   ## START HELP `basename $0`
   #------------------------------------------------------------------------------
		`basename $0` is the starting shell execution point of the isg-pub application.
		`basename $0` is is also an utility script with the goodies listed bellow:

		# go get this help, albeit you knew that already ... 
		bash $0 -h
		or 
		bash $0 --help


		#------------------------------------------------------------------------------
		## USAGE:
		#------------------------------------------------------------------------------


		1. to create a full package
		#--------------------------------------------------------
		bash $0 -a create-full-package


		2. to check the perl syntax :
		#--------------------------------------------------------
		bash $0 -a check-perl-syntax


		3. to clone / initialize a new project from the product
		#--------------------------------------------------------
		bash $0 -j \$project -a init-proj-app


		4. to create the tags file in the \$product_version_dir
		$product_version_dir
		#--------------------------------------------------------
		sh $0 -a create-ctags


		5. to create a link pointing to the latest stable version
		#--------------------------------------------------------
		links_base_dir=/tmp/
		bash $0 -a create-link -l \$links_base_dir
		ls -la \$links_base_dir/sfw/sh/$component_name.sh


		6. to completely remove the whole deployed full package
		#--------------------------------------------------------
		bash $0 -a remove-package


		# and the same commands ran on a different project 
		# note this is different script than this one !!!
		# define the isg-pub project as the starting template
		doParseIniEnvVars sfw/sh/isg-pub/isg-pub.isg-pub.`hostname -s`.conf
		# create a relative package out of it
		bash sfw/bash/isg-pub/isg-pub.sh -a create-relative-package
		# set the project vars in the current shell
		doParseIniEnvVars sfw/sh/isg-pub/isg-pub.$project.`hostname -s`.conf
		# 
		#
		#
		# create a relative package for the isg-pub template app
		doParseIniEnvVars sfw/sh/isg-pub/isg-pub.isg-pub.doc-pub-host.conf
		bash sfw/bash/isg-pub/isg-pub.sh -a create-relative-package

		doParseIniEnvVars sfw/sh/isg-pub/isg-pub.<<proj_name>>.doc-pub-host.conf

		bash $0 -j \$project -a init-proj-app
		bash $0 -j \$project -a check-perl-syntax
		bash $0 -j \$project -a run-project-mysql-scripts
		bash $0 -j \$project -a dump-tables
		bash $0 -j \$project -a eat-tables


		# to create the tags file in the $backup_root
		7. to create a new package and deploy it by passing search and replace rules
		#------------------------------------------------------------------------------
		#  
		# via the command line
		src_tool_name=isg-pub
		tgt_tool_name=type_here_your_target_tool
		src_version=$component_version
		tgt_version=1.0.0
		target_dir=type_here_your_target_dir
		search_and_replace_pairs1=\$src_tool_name¤\$tgt_tool_name
		search_and_replace_pairs2=\$src_version¤\$tgt_version

		sh $0 -a create-package -a deploy-package -d \$target_dir \\
		-s \$search_and_replace_pairs1 -s \$search_and_replace_pairs2


		8. to create a new package and deploy it by editing manually the morph file
		#------------------------------------------------------------------------------
		sh $0 -a create-package -a deploy-package -d "$target_dir"

		# this would "morph" each "$target_dir/search_morph_rule"
		# into "$target_dir/replace_morph_rule" defined in the
		$component_dir/.morph file
		sh $0 -a morph-dir -d "$target_dir"

		  
		9. to dump all the mysql tables into separate files 
		#------------------------------------------------------------------------------
		bash $0 -j \$project -a dump-tables
		
		10. to load all the mysql tables from the dump tables action
		#------------------------------------------------------------------------------
		bash $0 -j \$project -a eat-tables

		# this will dump the mysql tables into separate files in the following dir:
		$proj_version_dir/data/sql/mysql/dump/tables
		

      #------------------------------------------------------------------------------
      ## FOR DEVELOPERS
      #------------------------------------------------------------------------------

		`basename $0` is an utility script having the following purpose
		to provide an easy installable starting template for writing bash and sh scripts
		with  the following functionalities: 
		- printing help with cmd switch -h ( verify with doTestHelp in test-sh )
		- prints the set in the script variables set during run-time
		- separation of host specific vars into separate configuration file :
		 <<component_dir>>/<<component_name>>.<<MyHost>>.conf
		 $ini_file
		- thus easier enabling portability between hosts         
		- logging on terminal and into configurable log file set now as: 
		 $log_file
		- for loop examples with head removal and inline find and replace 
		- cmd args parsing  
		- doSendReport func to the tail from the log file to pre-configured emails
		- support for parallel run by multiple processes - each process uses its own tmp dir

   #------------------------------------------------------------------------------
   ## STOP HELP `basename $0`
   #------------------------------------------------------------------------------

END_HELP
}
#eof func doPrintHelp

# v0.9.2
#------------------------------------------------------------------------------
# cleans the unneeded during after run-time stuff 
#------------------------------------------------------------------------------
doPrintUsage(){

	printf "\033[2J";printf "\033[0;0H"

   test -z $target_dir && target_dir='<<target_dir>>'
   
   cat <<END_HELP    

   #------------------------------------------------------------------------------
   ## START USAGE `basename $0`
   #------------------------------------------------------------------------------
      bash $0 --help
      bash $0 -a check-perl-syntax
      bash $0 -a run-project-mysql-scripts
      bash $0 -a create-full-package
      bash $0 -a create-full-version-package
      bash $0 -a create-ctags
      bash $0 -a run-perl-tests
      bash $0 -a send-report
      bash $0 -a remove-package
      bash $0 -a remove-project-package
      bash $0 -a create-tar-package
      bash $0 -a create-project-package
      bash $0 -a update-project-sites

      doParseIniEnvVars /vagrant/csitea/cnf/projects/isg-pub/isg-pub.isg-pub.`hostname -s`.conf

      bash sfw/bash/isg-pub/isg-pub.sh -a create-relative-package
      doParseIniEnvVars sfw/sh/isg-pub/isg-pub.<<proj-name>>.`hostname -s`.conf

      bash $0 -j \$project -a init-proj-app
      bash $0 -j \$project -a check-perl-syntax
      bash $0 -j \$project -a run-project-mysql-scripts
      bash $0 -j \$project -a dump-tables
      bash $0 -j \$project -a eat-tables
      echo bash sfw/bash/scripts/to-win.sh \$proj_version_dir
      bash sfw/bash/scripts/to-win.sh \$proj_version_dir


      links_base_dir=/opt/
      bash $0 -a create-link -l \$links_base_dir
      ls -la \$links_base_dir/sfw/sh/$component_name.sh

      src_tool_name=isg-pub
      tgt_tool_name=type_here_your_target_tool
      src_version=$component_version
      tgt_version=1.0.0
      target_dir=type_here_your_target_dir
      search_and_replace_pairs1=\$src_tool_name¤\$tgt_tool_name
      search_and_replace_pairs2=\$src_version¤\$tgt_version

      bash $0 -a create-package -a deploy-package -d \$target_dir \\
      -s \$search_and_replace_pairs1 -s \$search_and_replace_pairs2

      bash $0 -a create-package -a deploy-package -d "$target_dir"
      bash $0 -a morph-dir -d "$target_dir"

END_HELP
}
#eof func doPrintUsage


#
#------------------------------------------------------------------------------
# creates the full package as component of larger product platform
#------------------------------------------------------------------------------
doCreateFullComponentVersionPackage(){

	#debug ok	echo proj_version_dir:: $proj_version_dir
	#debug ok	echo project:: $project
	#debug ok	sleep 5

	doLog " === START === create-full-version-package" ; 
	flag_completed=0

   #define default vars 
   test -z $include_file         && \
         include_file="$product_version_dir/meta/components/$component_name/.include"
   #define default vars 
   test -z $gen_include_file         && \
         gen_include_file="$product_version_dir/meta/components/$component_name/.gen-include"
   test -z $target_dir || \
         target_dir=$product_version_dir

	cd $product_version_dir
	# the generated files are just autoupdated !!!
	find docs/site/txt/gen/>"$gen_include_file"
	find sfw/gen>>"$gen_include_file"

   cd $product_base_dir

   timestamp=`date +%Y%m%d_%H%M%S`
   zip_file="$product_version_dir/$component_name.$component_version.$product_type.full.$timestamp.$host_name.zip"

	# zip MM ops
	# -MM
	# --must-match
	# All  input  patterns must match at least one file and all input files found must be readable.
	set -x ; ret=1
   cat $include_file | perl -ne 's|\n|\000|g;print'| \
		xargs -0 -I "{}" zip -MM $zip_file "$component_name/$environment_name/{}"	

	ret=$? ; set +x ;
	[ $ret == 0 ] || rm -fv $zip_file 
	[ $ret == 0 ] || doLog "FATAL !!! deleted $zip_file , because of packaging errors !!!" 
	[ $ret == 0 ] || exit 1

	set -x ; ret=1
   cat $gen_include_file | perl -ne 's|\n|\000|g;print'| \
		xargs -0 -I "{}" zip -MM $zip_file "$component_name/$environment_name/{}"

	ret=$? ; set +x ;
	[ $ret == 0 ] || doLog "FATAL !!! deleted $zip_file , because of packaging errors !!!" 
	[ $ret == 0 ] || exit 1


	doLog "[INFO ] created the following full development package:" 
	doLog "[INFO ] `stat -c \"%y %n\" $target_dir/$zip_file`"

	test -d $network_backup_dir && \
	#cmd="cp --parents -v $target_dir/$zip_file $network_backup_dir/" && doRunCmdOrExit "$cmd" && \
	cmd="rsync -a -v $target_dir/$zip_file $network_backup_dir/" && doRunCmdOrExit "$cmd" && \
   doLog "[INFO ] with the following network backup  :" && \
	doLog "[INFO ] `stat -c \"%y %n\" $network_backup_dir/$zip_file`" && \
   doLog "[INFO ] in the network dir @::" && \
	doLog "[INFO ] :: $network_backup_dir"
	flag_completed=1

	doLog " === STOP  === create-full-version-package" ; 
}
#eof func doCreateFullComponentVersionPackage





# 
#------------------------------------------------------------------------------
# removes a package from the $product_version_dir
#------------------------------------------------------------------------------
doRemoveComponentPackage(){

   # for each file in the include file remove it if its file 
   # but not the actual meta include file 
   for file in `cat "$product_version_dir/meta/components/$component_name/.include"`; do (
       file=$product_version_dir/$file
       test -f $file && \
       test $file == $product_version_dir/meta/components/$component_name/.include || \
       cmd="rm -fv $file" && \
       doRunCmdAndLog "$cmd"
   );
   done

   #remove the dirs as well 
   for dir in `cat "$product_version_dir/meta/components/$component_name/.include"`; do (
       dir="$product_version_dir/$dir"
       test -d "$dir" && cmd="rm -fRv $dir" && doRunCmdAndLog "$cmd"
   );
   done

   # now remove any zip file if 
   #cmd="rm -fv $product_version_dir/$component_name*$current_version*.zip"
   #doRunCmdAndLog "$cmd"

}
#eof func doRemoveComponentPackage


# 
#------------------------------------------------------------------------------
# removes a package from the $proj_version_dir
#------------------------------------------------------------------------------
doRemoveProjectPackage(){

   doLog "[DEBUG] START doRemoveProjectPackage"

	test -z "$proj_version_dir" \
			&& doExit 6 "the proj_version_dir $proj_version_dir is empty. Nothing to do!!!"
	export project=`basename $proj_version_dir`

   # for each file in the include file remove it if its file 
   # but not the actual meta include file 
   for file in `cat "$proj_version_dir/meta/components/$component_name/.include"`; do (
       file=$proj_version_dir/$file
       test -f $file && \
       test $file == $proj_version_dir/meta/components/$component_name/.include || \
       cmd="rm -fv $file" && \
       doRunCmdAndLog "$cmd"
   );
   done

   #remove the dirs as well 
   for dir in `cat "$proj_version_dir/meta/components/$component_name/.include"`; do (
       dir="$proj_version_dir/$dir"
       test -d "$dir" && cmd="rm -fRv $dir" && doRunCmdAndLog "$cmd"
   );
   done

   # now remove any zip file if 
   #cmd="rm -fv $product_version_dir/$component_name*$current_version*.zip"
   #doRunCmdAndLog "$cmd"

   doLog "[DEBUG] STOP  doRemoveProjectPackage"
}
#eof func doRemoveProjectPackage

#
# shamelessy stolen from so: http://stackoverflow.com/a/14254247/65706
doWaitForChildProcsToExit(){

   doLog "[DEBUG] START doWaitForChildProcsToExit"
   while true;
   do
       if [ -s $tmp_dir/.pid ] ; then
           for pid in `cat $tmp_dir/.pid`
           do
               doLog "Checking the pid: $pid"
               kill -0 "$pid" 2>/dev/null || sed -i "/^$pid$/d" $tmp_dir/.pid
           done
       else
           doLog "All your process completed"
            ## Do what you want here... here all your pids are in finished stated
           break
       fi
   done

   doLog "[DEBUG] STOP doWaitForChildProcsToExit"
}
#eof func doWaitForKidsToExit

#
#------------------------------------------------------------------------------
# creates the ctags file for the projet
#------------------------------------------------------------------------------
doCreateCtags(){
   ctags --help >/dev/null 2>&1 || 
      { doLog "ERROR. ctags is not installed or not in PATH. Aborting." >&2; exit 1; }
   pushd .
   cd $product_version_dir

   cmd="rm -fv ./tags"                         	&& doRunCmdAndLog "$cmd"
   cmd="ctags  -R -n --fields=+i+K+S+l+m+a ."  	&& doRunCmdAndLog "$cmd"
   cmd="ls -la $product_version_dir/tags"  		&& doRunCmdAndLog "$cmd"
	
   popd
}
#eof func doCreateCtags





#
#------------------------------------------------------------------------------
# creates a 
#------------------------------------------------------------------------------
doCreateLinkToMe(){
	# do exit if the links base dir is not provided	
	test -z "$links_base_dir" && doExit "no links_base_dir specified !!!"
	
	set +e
	# this is the link which points to the latest stable 
	# intance of me
	link_path="$links_base_dir/sfw/sh/$component_name.sh"

	# this is me being the latest stable version
	target_path="$component_dir/$my_name_ext"

	mkdir -p `dirname $link_path`
	ls -la `dirname $link_path`

	test -L $link_path && unlink $link_path

	ln -s $target_path $link_path

	cmd="ls -la $link_path"
	set -e ; doRunCmdOrExit "$cmd" ; set +e ;
} 
#eof func doCreateLinkToMe



#
#------------------------------------------------------------------------------
# creates a status-index.html and docs-index.html file out of specified db
#------------------------------------------------------------------------------
doPerlMysqlMorping(){
	
	doLog " [DEBUG] == START == doPerlMysqlMorphing"
	cd $product_version_dir

	perl "$product_version_dir/sfw/perl/isg-pub/isg_pub_preq_cheker.pl"
	export ret=$?
	test $ret -ne 0 && doExit 1 "[FATAL] perl modules not found!!!"

	# and clear the screen
	printf "\033[2J";printf "\033[0;0H"

	#debug echo isg-pub.sh lang_code $lang_code 
	#debug sleep 10
	#issue-282
	find . -name '*.pm' -exec perl -MAutoSplit -e 'autosplit($ARGV[0], $ARGV[1], 0, 1, 1)' {} \;

	perl_ini="$product_version_dir/conf/hosts/$host_name/ini/run_isg_pub.$host_name.ini"
	perl $product_version_dir/sfw/perl/isg-pub/run_isg_pub.pl \
		"$perl_ini" \
		--proj_version_dir=$proj_version_dir \
		--lang_code $lang_code

	doLog " [DEBUG] == STOP  == doPerlMysqlMorphing"
}
#eof func doPerlMysqlMorping


#
#------------------------------------------------------------------------------
# this is deprecated - use only for copy pasting the cmd line for the pdf conversion
# converts the generated html files into pdf files with nicer pdf formatting
#------------------------------------------------------------------------------
doConvertHtmlFilesToPdfFiles(){

	doLog " [INFO ] == START -- doConvertHtmlFilesToPdfFiles"
	
	cd "$product_version_dir"
	pushd .

	doLog " [DEBUG] first copy the files from the html dir to the pdf dir"
	cp -fv "$proj_version_dir/docs/site/html/$project/$lang_code/"*html \
			 $proj_version_dir/docs/site/pdf/$project/$lang_code/

		# any forking here does not work
		# issue-70
		perl_ini="$product_version_dir/conf/hosts/$host_name/ini/run_isg_pub.$host_name.ini"
		
		
		for page_type in `echo "list" "doc"`; do (
			for page in `cat $product_version_dir/conf/hosts/$host_name/lst/isg-pub/"$page_type"-pages.lst`; do (

				perl $product_version_dir/sfw/perl/isg-pub/run_isg_pub.pl "$perl_ini" \
				--proj_version_dir=$proj_version_dir \
				--action 'remove-html-element-by-class' \
				--htmlfile=$proj_version_dir/docs/site/pdf/$project/$lang_code/$page.html \
				--htmlclass='srch_table,left_navi,top_menu,lang_menu'

				test -f $proj_version_dir/docs/site/pdf/$project/$lang_code/$page.pdf \
					&& rm -vf $proj_version_dir/docs/site/pdf/$project/$lang_code/$page.pdf
				# if this is list page use landscape for pdf as the tables are big 
				[[ $page_type == "list" ]] && paper_orientation='Landscape'

				# if this is doc page use portrait as we want official doc like doc
				[[ $page_type == "doc" ]] && paper_orientation='Portrait'
				
				#set -x	
				i=0
				for amt_running_insts in $(ps -ef|grep wkhtmltopdf|grep -v grep| wc -l) ; do (
				
					doLog "amt_running_insts : $amt_running_insts"
					i=$((i+1))
					#wait one second 
					sleep 1

					# give up on the 20 ths second						
					test $i -gt 20 && break

					# after 1 second sleep try once again if there are runing instances 
					test $amt_running_insts -gt 0 && continue

					#wkhtmltopdf --zoom 0.7 --page-size A4 \
					# adjust the screen resolution according to the one of the running host
					xvfb-run --server-args="-screen 0, 1366x768x24" \
					wkhtmltopdf --page-size A4 \
					--orientation "$paper_orientation" \
					--allow $proj_version_dir/docs/site/pdf/$project/$lang_code/ \
					--page-width 500 \
					--margin-bottom 25 \
					--margin-left 20 \
					--margin-right 5 \
					--margin-top 25 \
					$proj_version_dir/docs/site/pdf/$project/$lang_code/$page.html\
					$proj_version_dir/docs/site/pdf/$project/$lang_code/$page.pdf

					rm -fv $proj_version_dir/docs/site/pdf/$project/$lang_code/$page.html

				);
				done
			);
			done
		);
		done

				set +x	
	popd
	doLog " [INFO ] == STOP  -- doConvertHtmlFilesToPdfFiles"
} 
# eof func doConvertHtmlFilesToPdfFiles





#
#------------------------------------------------------------------------------
# run all the mysql scripts by connecting to the correct db by lang_code param
# issue-258
#------------------------------------------------------------------------------
doRunProjectMySqlScripts(){
	
	pushd .; cd $product_version_dir 

	doLog "[DEBUG] START doRunProjectMySqlScripts"
	pushd .
	test -z "$proj_version_dir" \
			&& export proj_version_dir=$product_version_dir


	export tmp_log_file=$tmp_dir/.$$.log
	doLog " START == running sql scripts "	
	#sleep 1 ; 
	# and clear the screen
	#flush the screen
	printf "\033[2J";printf "\033[0;0H"
	
	echo $mysql_user 
	#set -e
	#run the create database script by passing the name of the db from the ini file
	test -z "$sql_dir" && mysql -u"$mysql_user" -p"$mysql_user_pw" \
	-e "set @proj_lang_db='$proj_lang_db';source \
	$proj_version_dir/sfw/sql/mysql/product/00.create-project-lang-db.mysql ;" > "$tmp_log_file" 2>&1
	
	test -z "$sql_dir" && is_sql_biz_as_usual_run="1"
	test -z "$sql_dir" \
			&& export sql_dir="$proj_version_dir/sfw/sql/mysql/product"
	# if a relative path is passed add to the product version dir
	[[ $sql_dir == /* ]] || export sql_dir="$proj_version_dir""$sql_dir"
	#echo @1188 sql_dir $sql_dir
	#sleep 10

	# show the developer what happened
	cat "$tmp_log_file" 

	# and save the tmp log file into the log file
	cat "$tmp_log_file" >> $log_file

	test -z "$is_sql_biz_as_usual_run" && sleep 1 ; 
	#flush the screen
	printf "\033[2J";printf "\033[0;0H"
	
	echo -e "should run the following sql files : \n" 
	find "$sql_dir" -type f -name "*.sql"|sort -n
	sleep 2

	# run the sql scripts in alphabetical order
	for sql_script in `find "$sql_dir" -type f -name "*.sql"|sort -n`; do (

		#just to have it clearer
		relative_sql_script=$(echo $sql_script|perl -ne "s#$proj_version_dir##g;print")

		# give the poor dev a time to see what is happening
		test -z "$is_sql_biz_as_usual_run" && sleep 1 ; 

		# and clear the screen
		printf "\033[2J";printf "\033[0;0H"

		doLog " START === running $relative_sql_script"
		echo -e '\n\n'
		# set the params ... Note the quotes - needed for non-numeric values 
		# run the sql save the result into a tmp log file
		mysql -t -u"$mysql_user" -p"$mysql_user_pw" -D"$proj_lang_db" < "$sql_script" > "$tmp_log_file" 2>&1

		# show the user what is happenning 
		cat "$tmp_log_file"
		# and save the tmp log file into the script log file
		cat "$tmp_log_file" >> $log_file
		echo -e '\n\n'
		doLog " STOP  === running $relative_sql_script"
		#debug sleep 1 

	);
	done
	
	doLog " STOP  == running sql scripts "	
	test -z "$is_sql_biz_as_usual_run" && sleep 1 ; 
	# and clear the screen
	printf "\033[2J";printf "\033[0;0H"

	popd 
	doLog "[DEBUG] STOP  doRunProjectMySqlScripts"
	set +e
}
#eof func doRunProjectMySqlScripts


#----------------------------------------------------------
# do morph the needed dirs in the project dir
#----------------------------------------------------------
doInitializeProjectAppLayer(){
   #set -x
	test -d $proj_version_dir && mv -v $proj_version_dir $proj_version_dir.`date +%Y%m%d_%H%M%S`
	mkdir -p $proj_version_dir/data/zip
	# define the latest zip file from the product dir as the latest deployment zip file
	src_zip_file=$(stat -c "%y %n" $product_dir/*| sort -nr| grep "$component_name" |head -n 1|perl -nle '@t=split /\s+/, $_;print $t[3] ')
   echo $src_zip_file
	unzip -o "$src_zip_file" -d "$proj_version_dir/"
   # sleep 10
	mkdir -p $product_version_dir/conf/hosts/$host_name/projects/$project
	# define the list file
	list_file="$product_version_dir/conf/hosts/$host_name/projects/$project/search-and-replace.lst"
	
	# create the list file
	mkdir -p $(dirname $list_file)
	echo -e "$component_name""\t""$project">$list_file
	product_alias=$(echo $component_name|perl -ne 's/-/_/g;print')
	echo -e "$product_alias""\t""$proj_alias">>$list_file
	
	cat $list_file
	
	echo "@doInitializeProjectAppLayer:: product:: \"$component_name\""
	echo "@doInitializeProjectAppLayer:: product_alias:: \"$product_alias\""
	echo "@doInitializeProjectAppLayer:: project:: \"$project\""
	echo "@doInitializeProjectAppLayer:: product_version_dir:: \"$product_version_dir\""
	echo "@doInitializeProjectAppLayer:: proj_version_dir:: \"$proj_version_dir\""
	sleep 5

   test -f $list_file && rm -fv $list_file
   sleep 2
	cat $list_file | { while read -r line ;
	do (
		echo -e "START === $line" ; 
		doLog "line: $line"
		export to_srch=$(echo $line|cut --delimiter=$' ' -f 1)
		doLog "to_srch:\"$to_srch\" " ; 
		export to_repl=$(echo $line|cut --delimiter=$' ' -f 2) 
		doLog "to_repl:\"$to_repl\" " ; 
		doLog "proj_version_dir: $proj_version_dir"

		#search and repl %var_id% with var_id_val in deploy_tmp_dir 
		find $proj_version_dir -type d|perl -nle '$o=$_;s#'"$to_srch"'#'"$to_repl"'#g;$n=$_;`mkdir -p $n` ;'
		find $proj_version_dir -type f|perl -nle '$o=$_;s#'"$to_srch"'#'"$to_repl"'#g;$n=$_;rename($o,$n) unless -e $n ;'


		doLog "start search and replace in non-binary files"
		#search and replace ONLY in the txt files and omit the binary files
		find $proj_version_dir -exec file {} \; | grep text | cut -d: -f1| { while read -r file ;
				do (
					#debug doLog doing find and replace in $file 
					perl -pi -e "s#$to_srch#$to_repl#g" "$file"
				);
				done ;
			}
			#eof while 2
		doLog "stop search and replace in non-binary files"
	);
	done ; 

		find "$proj_version_dir/" -type f -name '*.bak' | xargs rm -f
	}
	#eof while 1

   # and create the app link
   export link_path="$product_version_dir""/doc_pub/public/img/apps/""$proj_alias""_en"
   export target_path="$proj_version_dir""/doc_pub/public/img/apps/""$proj_alias""_en"
   mkdir -p `dirname $link_path`
   test -L "$link_path" && unlink $link_path
   ln -s "$target_path" "$link_path"
   sudo chmod -Rv 755 "$link_path"
   ls -la $link_path;
}
#eof func doInitializeProjectAppLayer


#
#------------------------------------------------------------------------------
# checks the perl syntax of the cgi perl modules
#------------------------------------------------------------------------------
doCheckPerlSyntax(){
	
  doLog "[INFO] == START == doCheckPerlSyntax"
  pushd .
  cd $proj_version_dir

  #remove all the autosplit.ix files
  find . -name autosplit.ix | xargs rm -fv

  # remove all the empty dirs
  find . -type d -empty -exec rm -fvr {} \;

  cd sfw/perl;

  # run the autoloader utility
  find . -name '*.pm' -exec perl -MAutoSplit -e 'autosplit($ARGV[0], $ARGV[1], 0, 1, 1)' {} \;

  # go back
  cd ../.. ;

  # foreach perl file check the syntax by setting the correct INC dirs
  for file in `find "sfw/perl/isg_pub" -type f \( -name "*.pl" -or -name "*.pm" \)` ; do (
			 perl -MCarp::Always -I `pwd`/sfw/perl -I `pwd`/sfw/perl/lib -Twc "$file"

  );
  done

  # go back .. 

  cd doc_pub;

  # run the autoloader utility
  find . -name '*.pm' -exec perl -MAutoSplit -e 'autosplit($ARGV[0], $ARGV[1], 0, 1, 1)' {} \;

  # go back
  cd ..;

  # and the doc_pub
  # foreach perl file check the syntax by setting the correct INC dirs
  for file in `find "doc_pub/" -type f \( -name "*.pl" -or -name "*.pm" \)` ; do (
			 perl -MCarp::Always -I `pwd`/doc_pub -I `pwd`/doc_pub/lib -Twc "$file"

  );
  done


  sleep 1 ;

  # and clear the screen
  printf "\033[2J";printf "\033[0;0H"

  popd
  doLog "[INFO] == STOP  == doCheckPerlSyntax"

}
#eof func doCheckPerlSyntax 



#
#------------------------------------------------------------------------------
# checks the perl syntax of the cgi perl modules
#------------------------------------------------------------------------------
doRunPerlTests(){
	
	doLog "[INFO] == START == doRunPerlTests"
	pushd .
	cd $product_version_dir

	
	
	# foreach perl file check the syntax by setting the correct INC dirs	
	for file in `find "sfw/perl/isg_pub_unit_tests" -type f -name "*.pl"|sort` ; do (
		perl -T "$file"
		sleep 2

		# and clear the screen
		printf "\033[2J";printf "\033[0;0H"
	);
	done

	sleep 1 ; 


	popd 
	doLog "[INFO] == STOP  == doRunPerlTests"
}
#eof func doRunPerlTests 





# v0.9.2
#------------------------------------------------------------------------------
# the main function called 
#------------------------------------------------------------------------------
doDumpTables(){
	
	tables_dump_dir="$proj_version_dir/data/sql/mysql/dump/$component_version/$proj_lang_db/tables"
	doLog "Dumping tables into separate SQL command files"
	doLog "for database:: '$proj_lang_db' into dir:: $tables_dump_dir"
	tbl_count=0
	mkdir -p "$tables_dump_dir"

	for t in $(mysql -NBA -u"$mysql_user" -p"$mysql_user_pw" -D"$proj_lang_db" -e 'show tables'); do (
		doLog "dumping table ::: $t ..."
		mysqldump --extended-insert=FALSE -u "$mysql_user" -p"$mysql_user_pw" "$proj_lang_db" $t \
				| gzip > "$tables_dump_dir/$t.sql.gz"
		((tbl_count++))
	);
	done

	doLog "Total $tbl_count tables dumped from database '$proj_lang_db' into dir=$tables_dump_dir"
}

# v0.9.2
#------------------------------------------------------------------------------
# the main function called 
#------------------------------------------------------------------------------
doEatTables(){
	
	tables_dump_dir="$proj_version_dir/data/sql/mysql/dump/$component_version/$proj_lang_db/tables"
	doLog "Eating tables iseparate SQL command files"
	
	find $tables_dump_dir -name '*.sql.gz' | xargs -P 5 gunzip -fv {}  \;

	find $tables_dump_dir -type f -name '*.sql' | \
		{ while read -r sql_script ; do  \
		doLog "running the sql for the following file: $sql_script" ; mysql -u$mysql_user -p$mysql_user_pw -D"$proj_lang_db" < $sql_script  ; done ; }
}
#eof func doEatTables


# v0.9.2
#------------------------------------------------------------------------------
# the main function called 
#------------------------------------------------------------------------------
main(){
   doInit
   
	#debug echo 1-@main proj_version_dir : $proj_version_dir ; sleep 2
	#debug echo 1-@main project : $project ; sleep 2

   case $1 in "-?"|"--?"|"-h"|"--h"|"-help"|"--help") \
            doSetVars;doPrintHelp ; exit 0 ; esac
   case $1 in "-u"|"-usage"|"--usage") \
            doPrintUsage ; exit 0 ; esac
   
   doParseCmdArgs "$@"
   doSetVars
   doCheckReadyToStart

   for action in `echo $actions`; do (
		pushd .
      test "$action" == 'create-package'              	&& doCreatePackage
      test "$action" == 'deploy-package'              	&& doDeployPackage
      test "$action" == 'send-report'                 	&& doSendReport
      test "$action" == 'morph-dir'                   	&& doMorphDir
      test "$action" == 'create-full-version-package'		&& doCreateFullComponentVersionPackage
      test "$action" == 'remove-package'              	&& doRemoveComponentPackage
      test "$action" == 'remove-project-package' 			&& doRemoveProjectPackage
      test "$action" == 'create-tar-package'          	&& doCreateComponentTarPackage
      test "$action" == 'create-ctags'                	&& doCreateCtags
      test "$action" == 'conf-files-backup'           	&& doCreateHostConfFilesBackup
      test "$action" == 'create-link'           			&& doCreateLinkToMe
      test "$action" == 'html-to-pdf'           			&& doConvertHtmlFilesToPdfFiles
		test "$action" == 'update-project-sites'				&& doUpdateProjectSites
		test "$action" == 'run-project-mysql-scripts'		&& doRunProjectMySqlScripts
		test "$action" == 'check-perl-syntax'					&& doCheckPerlSyntax
		test "$action" == 'run-perl-tests'						&& doRunPerlTests
		test "$action" == 'init-proj-app'						&& doInitializeProjectAppLayer
		test "$action" == 'dump-tables'							&& doDumpTables
		test "$action" == 'eat-tables'							&& doEatTables
		popd
   );
   done
  	
	test -z "$action" && doPerlMysqlMorping

  doExit 0 "
  #----------------------------------------------------------
  # = STOP  MAIN = $component_name
  #----------------------------------------------------------
  " ;
}
#eof func main



# Action !!! call the main by passing the cmd args 
main "$@"


#
#----------------------------------------------------------
# Purpose:
# to provide an easy starting template for writing bash and sh scripts
#----------------------------------------------------------
# 
# with  the following features: 
# - prints the set in the script variables
# - separation of host specific vars into $0.$host_name.conf file
# - doLog function for both xterm and log file printing
# - for loop examples with head removal and inline find and replace 
# 
#----------------------------------------------------------
#
# ErrorCodes 
# 1 --- Cannot find conf file 
# 2 --- called with a wrong cmd argument or -h for help 
# 
#----------------------------------------------------------
#  EXIT CODES
# 0 --- Successfull completion 
# 1 --- UnknownError 1 set in the beginning
# 2 --- Unknown cmd arg option supplied 
# 3 --- A configuration file is missing - Cannot find ini_file 
# 4 --- cannot chdir to 
# 5 --- no package available for deployment
# 6 --- A target dir has not been supplied 
# 7 --- A target dir for for deployment cannot be created 
#----------------------------------------------------------
#
# VersionHistory: 
#----------------------------------------------------------
# 0.9.7.1 -- 2016-08-15 09:30:37 -- ysg -- fixed bug mailx -> muttc
# 0.8.7.1 -- 2014-12-08 18:58:34 -- ysg -- doDeploySite
# 0.7.6.1 -- 2014-07-24 18:32:42 -- ysg -- doUpdateProjectSites
# 0.7.6.1 -- 2014-07-24 18:32:42 -- ysg -- doUpdateProjectSites
# 0.5.1.4 -- 2014-06-02 15:58:28 -- ysg -- add nice html table css in index.html
# 0.0.1.0 -- 2014-05-29 10:41:12 -- ysg -- initial version
# 
#----------------------------------------------------------
#
#eof file:isg-pub.sh v1.9.6
