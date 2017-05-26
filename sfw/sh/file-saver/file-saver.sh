#!/bin/bash
# file: file-saver.sh at the end 
umask 022    ; 

# print the commands 
# set -x
# print each input line as well
# set -v
# exit the script if any statement returns a non-true return value. gotcha !!!
# set -e 

# v2.0.7
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
   component_version='1.1.3'
   test $OSTYPE != 'cygwin' && host_name=`hostname -s`
   test $OSTYPE == 'cygwin' && host_name=`hostname`
}
#eof doInit


# v2.0.7
#------------------------------------------------------------------------------
# set the variables from the $0.$host_name.conf file which has ini like syntax
#------------------------------------------------------------------------------
doSetVars(){
   cd $component_dir
   cd ..; component_base_dir=`pwd`

   for i in {1..2} ; do cd .. ;done ;
   export product_version_dir=`pwd`;

	# this will be dev , tst, prd	
	environment_name=$(echo `basename "$product_version_dir"`|cut --delimiter='.' -f5)
   
	cd .. 
   product_dir=`pwd`;

   cd "$component_dir/"
   doParseIniFile 
   ( set -o posix ; set ) >"$tmp_dir/vars.after"
   doLog "
   #----------------------------------------------------------
   # START MAIN 
   #----------------------------------------------------------
   "
   exit_code=1
   doLog " Using the following variables :"
   cmd="$(comm --nocheck-order -3 $tmp_dir/vars.before $tmp_dir/vars.after | perl -ne 's#\s+##g;print "\n $_ "' )"
   doLog "
   $cmd"
}
#eof func doSetVars


# v2.0.7
#------------------------------------------------------------------------------
# parse the ini like $0.$host_name.conf and set the variables
# cleans the unneeded during after run-time stuff. Note the MainSection
#------------------------------------------------------------------------------
doParseIniFile(){
   ini_file=$1;shift 1;
   test -z "$ini_file" && ini_file="$component_dir/$component_name.$host_name.conf"
   test -f "$ini_file" || \
   	cp -v $component_dir/$component_name.host_name.conf \
				$component_dir/$component_name.$host_name.conf 
   eval `sed -e 's/[[:space:]]*\=[[:space:]]*/=/g' \
      -e 's/;.*$//' \
      -e 's/[[:space:]]*$//' \
      -e 's/^[[:space:]]*//' \
      -e "s/^\(.*\)=\([^\"']*\)$/\1=\"\2\"/" \
      < $ini_file \
      | sed -n -e "/^\[MainSection\]/,/^\s*\[/{/^[^;].*\=.*/p;}"`
}
#eof func doParseIniFile


# v2.0.7
#------------------------------------------------------------------------------
# parse the single letter command line args 
#------------------------------------------------------------------------------
doParseCmdArgs(){


while getopts ":a:d:f:h:i:l:s:" opt; do
  case $opt in
	a)
		actions="$actions$OPTARG "
		;;
	d)
		target_dir="$OPTARG"
		;;
 	f)
      file_to_backup="$OPTARG"
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
	s)
		echo "OPTARG IS $OPTARG"
      test -z "$search_and_replace_pairs" && rm -vf "$component_dir/.morph"
      # obs! the new line after the optarg !!!
      search_and_replace_pairs="$search_and_replace_pairs$OPTARG"$'\n'
      #' this is only for the silly quoting parser in my editor
      # debug echo "search_and_replace_pairs is $search_and_replace_pairs"
      ;;
	l)
      links_base_dir="$OPTARG"
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


# v2.0.7
#------------------------------------------------------------------------------
# perform the checks to ensure that all the vars needed to run are set 
#------------------------------------------------------------------------------
doCheckReadyToStart(){
   
   test -f $ini_file || doExit 3 "Cannot find ini_file : $ini_file" 
   test -z $target_dir && target_dir='.'
   
}
#eof func doCheckReadyToStart

# v2.0.7
#------------------------------------------------------------------------------
# echo pass params and print them to a log file and terminal
# with timestamp and $host_name and $0 PID
#------------------------------------------------------------------------------
doLog(){
   type_of_msg=$1
   [[ $type_of_msg == *DEBUG* ]] && [[ $do_print_debug_msgs -ne 1 ]] && return

   # print to the terminal if we have one
   test -t 1 && echo "`date +%Y.%m.%d-%H:%M:%S` [@$host_name] [$$] $*"

   # define default log file none specified in conf file
   test -z $log_file && log_file="$component_dir/$component_name.`date +%Y%m`.log"
   echo "`date +%Y.%m.%d-%H:%M:%S` [@$host_name] [$$] $*" >> $log_file
}
#eof func doLog


# v2.0.7
#------------------------------------------------------------------------------
# run a command and log the call and its output to the log_file
# doPrintHelp: doRunCmdAndLog "$cmd"
#------------------------------------------------------------------------------
doRunCmdAndLog(){
  cmd="$*" ; 
  doLog " DEBUG running cmd and log: \"$cmd\""
   
   msg=$($cmd 2>&1)
   ret_cmd=$?
   error_msg="ERROR : Failed to run the command \"$cmd\" with the output \"$msg\" !!!"
   
   [ $ret_cmd -eq 0 ] || doLog "$error_msg"
   doLog " DEBUG : cmdoutput : \"$msg\""
}
#eof func doRunCmdAndLog


# v2.0.7
#------------------------------------------------------------------------------
# run a command on failure exit with message
# doPrintHelp: doRunCmdOrExit "$cmd"
# call by: 
# set -e ; doRunCmdOrExit "$cmd" ; set +e
#------------------------------------------------------------------------------
doRunCmdOrExit(){
   cmd="$*" ; 
   
   doLog " DEBUG running cmd or exit: \"$cmd\""
   msg=$($cmd 2>&1)
   ret_cmd=$?
   # if error occured during the execution exit with error
   error_msg="ERROR : FATAL : Failed to run the command \"$cmd\" with the output \"$msg\" !!!"
   [ $ret_cmd -eq 0 ] || doExit "$ret_cmd" "$error_msg"
   
   #if no error occured just log the message
   doLog " DEBUG : cmdoutput : \"$msg\""
}
#eof func doRunCmdOrExit


# v2.0.7
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

   for Email in $Emails; do (
      cat $small_tmp_log | mailx -s "tail -n $log_file_lines_number $log_file" -a $small_tmp_log $Email
   );
   done
   doLog " STOP function ======= doSendReport"
}
#eof func doSendReport

# v2.0.7
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


# v2.0.7
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

   doLog " $exit_msg" 
   echo -e "\n\n"

   exit $exit_code
}
#eof func doExit


#------------------------------------------------------------------------------
# create a zip package by adding all the relative file paths specified 
# in the deployment file. You could omit some files from your .inlude file by:
# cat meta/components/$compoenent_name/.include | grep -v str_to_exclude
#------------------------------------------------------------------------------
doCreatePackage(){

	doLog "DEBUG START doCreatePackage"
	pushd . 
	
	cd $product_version_dir

	deploy_file=$product_version_dir/meta/components/$component_name/.deploy-include
	for file in `cat $deploy_file` ; do (
		test -f $file && zip $component_name.zip $file	

	);
	done

	popd
	doLog "DEBUG STOP doCreatePackage"
}
#eof func doCreatePackage

#
#------------------------------------------------------------------------------
# do deploy the package , do search and replace if any morph rules are specified
#------------------------------------------------------------------------------
doDeployPackage(){
	
	pushd .

	doLog "DEBUG START doDeployPackage"
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
	doLog "DEBUG STOP doDeployPackage"
}
#eof func doDeployPackage


# v2.0.7
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


# v2.0.7
#------------------------------------------------------------------------------
# cleans the unneeded during after run-time stuff 
#------------------------------------------------------------------------------
doPrintHelp(){

   test -z "$target_dir" && target_dir='<<target_dir>>'
   
   cat <<END_HELP    

   #------------------------------------------------------------------------------
   ## START HELP `basename $0`
   #------------------------------------------------------------------------------
      #------------------------------------------------------------------------------
      ## PURPOSE
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

		# go get this help:
		sh $0 -h

		#------------------------------------------------------------------------------
		## USAGE:
		#------------------------------------------------------------------------------
		#  to create a new package and deploy it by passing search and replace rules
		# via the command line
		src_tool_name=file-saver
		tgt_tool_name=type_here_your_target_tool
		src_version=$component_version
		tgt_version=1.0.0
		target_dir=type_here_your_target_dir
		search_and_replace_pairs1=\$src_tool_name¤\$tgt_tool_name
		search_and_replace_pairs2=\$src_version¤\$tgt_version

		sh $0 -a create-package -a deploy-package -d \$target_dir -s \$search_and_replace_pairs1 -s \$search_and_replace_pairs2


		#  to create a new package and deploy it by editing manually the morph file
		sh $0 -a create-package -a deploy-package -d "$target_dir"

		# this would "morph" each "$target_dir/search_morph_rule"
		# into "$target_dir/replace_morph_rule" defined in the
		$component_dir/.morph file
		sh $0 -a morph-dir -d "$target_dir"

		# to create the tags file in the $product_version_dir
		sh $0 -a create-ctags

		# to create the tags file in the $backup_root
		sh $0 -a create-ctags

		# to create a link pointing to the latest stable version
		links_base_dir=/tmp/
		sh $0 -a create-link -l \$links_base_dir
		ls -la \$links_base_dir/sfw/sh/$component_name.sh

		#------------------------------------------------------------------------------
		## INSTALLATION
		#------------------------------------------------------------------------------
		cd /tmp/
		wget --no-check-certificate https://github.com/YordanGeorgiev/file-saver/archive/master.zip
		ls -la
		unzip -o master.zip -d .
		mv -v ./file-saver-master/ ./file-saver
		find .
		# optional just check how it is working 
		sh /tmp/file-saver/test-file-saver.sh

   #------------------------------------------------------------------------------
   ## STOP HELP `basename $0`
   #------------------------------------------------------------------------------

END_HELP
}
#eof func doPrintHelp


#
#------------------------------------------------------------------------------
# creates the full package as component of larger product platform
#------------------------------------------------------------------------------
doCreateComponentFullPackage(){

   cd $product_version_dir

   #define default vars 
   test -z $include_file         && \
         include_file="$product_version_dir/meta/components/$component_name/.include"
   test -z $target_dir || \
         target_dir=$product_version_dir
   
   timestamp=`date +%Y%m%d_%H%M%S`
   zip_file="$component_name.$component_version.$environment_name.$host_name.$timestamp.zip"

   # create the zip file 
   for file in `cat $include_file`; do (
      cmd="zip $zip_file $file" 
      doRunCmdOrExit "$cmd"
   );
   done
   
   doLog "INFO created the following development package $target_dir/$zip_file"
}
#eof func doCreateComponentFullPackage


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
#eof func doRemovePackage


#
# shamelessy stolen from so: http://stackoverflow.com/a/14254247/65706
doWaitForChildProcsToExit(){

   doLog "DEBUG START doWaitForChildProcsToExit"
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

   doLog "DEBUG STOP doWaitForChildProcsToExit"
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
# create a backup for all the files marked for backup
#------------------------------------------------------------------------------
doCreateHostBackup(){
   export timestamp=`date +%Y%m%d_%H%M%S`;

	test -z "$backup_root_dir" && backup_root_dir=/tmp/
	doLog " ERROR the backup_root_dir was not configured using /tmp/ instead !!!"
   
   # note this will work only with full file paths in the meta include file !!!
   for file in `cat "$files_to_backup_list_file"`; do (
      
      test -f $file || continue

      dir_target="$backup_root_dir"`dirname $(readlink -f "$file")`
      cmd="mkdir -p $dir_target"
      doRunCmdAndLog "$cmd"

      cmd="cp -v $file $dir_target/"
      doRunCmdAndLog "$cmd"

      dir_target="$backup_root_dir"'/'"$timestamp"`dirname $(readlink -f "$file")`

      cmd="mkdir -p $dir_target"
      doRunCmdAndLog "$cmd"

      cmd="cp -pv $file $dir_target/"
      doRunCmdAndLog "$cmd"

   );
   done

	doLog "and verify"
	doLog $'\n'"#-----------------------------------------------------"$'\n'
	output="$output"$(find "$backup_root_dir"'/'"$timestamp"| sort -nr|uniq -u)
	output=$'\n\n'"$output"$'\n\n'
	doLog "$output"
	doLog $'\n'"#-----------------------------------------------------"$'\n'


   doCreateSetPermissionsScript

}
#eof func doCreateHostBackup


#
#------------------------------------------------------------------------------
# self-descriptive
#------------------------------------------------------------------------------
doCreateSetPermissionsScript(){
	
	test -z "$restore_chmod_sh" && 
	restore_chmod_sh=$product_version_dir/conf/$component_name/hosts/.$host_name.restore-chmod.sh

	test -f "$restore_chmod_sh" || mkdir -p `dirname "$restore_chmod_sh"`
	test -f "$restore_chmod_sh" || touch "$restore_chmod_sh"`

	test -z "$restore_chown_sh" && 
	restore_chown_sh=$product_version_dir/conf/$component_name/hosts/.$host_name.restore-chown.sh

	test -f "$restore_chown_sh" || mkdir -p `dirname "$restore_chown_sh"`
	test -f "$restore_chown_sh" || touch "$restore_chown_sh"`
		

   test -f "$restore_chmod_sh" && \
      cmd="mv -v $restore_chmod_sh $restore_chmod_sh.`date +%Y%m%d_%H%M%S`"
   test -f "$restore_chmod_sh" && doRunCmdAndLog "$cmd"

   test -f "$restore_chown_sh" && \
      cmd="mv -v $restore_chown_sh $restore_chown_sh.`date +%Y%m%d_%H%M%S`"
   test -f "$restore_chown_sh" && doRunCmdAndLog "$cmd"
   
	for file in `cat "$files_to_backup_list_file"`; do (
      echo "chown -v $(stat -c \"%U\":\"%G\" $file) \"$file\"" >> "$restore_chown_sh"
      echo "chmod -v $(stat -c %a $file) \"$file\"" >> "$restore_chmod_sh"
   );
   done


}
#eof func doCreateSetPermissionsScript


#
#------------------------------------------------------------------------------
# creates a 
#------------------------------------------------------------------------------
doCreateLinkToMe(){

	# do exit if the links base dir is not provided	
	test -z "$links_base_dir" && doExit "no links_base_dir specified !!!"
	
	# this is the link which points to the latest stable 
	# intance of me
	link_path="$links_base_dir/sfw/sh/$component_name.sh"

	# this is me being the latest stable version
	target_path="$product_version_dir/sfw/sh/$component_name/$component_name.sh"

	cmd="mkdir -p `dirname $link_path`"
	set -e ; doRunCmdOrExit "$cmd" ; set +e ;

	cmd="unlink $link_path"
	doRunCmdAndLog "$cmd"

	cmd="ln -s ""$target_path"" $link_path"
	set -e ; doRunCmdOrExit "$cmd" ; set +e ;

	cmd="ls -la $link_path"
	set -e ; doRunCmdOrExit "$cmd" ; set +e ;
} 
#eof func doCreateLinkToMe


doBackupFile(){

	doLog "START doBackupFile"

	test -z "$file_to_backup" && doExit " FATAL: no file to backup specified : $file_to_backup"
	if [[ "$file_to_backup" != /* ]]
		then file_to_backup="$product_version_dir/$file_to_backup"
	fi

	cmd="test -f $file_to_backup"
 	set -e ; doRunCmdOrExit "$cmd" ; set +e

	#define the version
	file_version=$(grep 'export version' $file_to_backup | cut -d= -f2)
	test -z "$file_version" && file_version='1.0.0'
	#todo: parametrize 
	mkdir -p $backup_root_dir/`dirname $file_to_backup`

	cmd="cp -v $file_to_backup $backup_root_dir/$file_to_backup"
	doRunCmdAndLog "$cmd"
	
	# copy the file to backup by preserving the file permissions
	cp -vp $file_to_backup $backup_root_dir/$file_to_backup.$file_version.`date +%Y%m%d_%H%M%S`.backup
	
	doLog "and verify"
	doLog $'\n'"#-----------------------------------------------------"$'\n'
	output="$output"$(stat -c "%a %U:%G %n" $backup_root_dir$file_to_backup* | sort -nr|uniq -u)
	output=$'\n\n'"$output"$'\n\n'
	doLog "$output"
	doLog $'\n'"#-----------------------------------------------------"$'\n'


	# if the files to backup list file is not configured set default
	test -z "$files_to_backup_list_file" && \
		files_to_backup_list_file="$component_dir/.$host_name.files-to-backup.lst"
	test -r $files_to_backup_list_file || touch $files_to_backup_list_file
	doLog "files_to_backup_list_file : $files_to_backup_list_file"

	flag_file_is_found=$(grep -c "$file_to_backup" "$files_to_backup_list_file")
	msg="the file to backup : $file_to_backup was not found in this host\'s list of files to backup"
	msg="$msg adding it to the list of files to backup"
	doLog "flag_file_is_found:$flag_file_is_found"

	test -z "$flag_file_is_found" && echo "$file_to_backup" >> "$files_to_backup_list_file"
	test -z "$flag_file_is_found" && doLog "$msg"doLog "$msg"
	test $flag_file_is_found -lt 1 && echo "$file_to_backup" >> "$files_to_backup_list_file"
	test $flag_file_is_found -eq 1 && doLog " only once do nothing"
	test $flag_file_is_found -gt 1 && doLog " more than once do nothing"
	#output=$(cat "$files_to_backup_list_file")
	#output=$'\n\n'"$output"$'\n\n'
	#doLog "$output"

	doLog "STOP doBackupFile"
}
#eof func doBackupFile


# v2.0.7
#------------------------------------------------------------------------------
# the main function called 
#------------------------------------------------------------------------------
main(){
   doInit
   
   case $1 in "-?"|"--?"|"-h"|"--h"|"-help"|"--help") \
            doSetVars;doPrintHelp ; exit 0 ; esac
   
   doParseCmdArgs "$@"
   doSetVars
   doCheckReadyToStart

   for action in `echo $actions`; do (
      test "$action" == 'create-package'              && doCreatePackage
      test "$action" == 'deploy-package'              && doDeployPackage
      test "$action" == 'send-report'                 && doSendReport
      test "$action" == 'morph-dir'                   && doMorphDir
      test "$action" == 'create-full-package'			&& doCreateComponentFullPackage
      test "$action" == 'remove-package'              && doRemoveComponentPackage
      test "$action" == 'create-ctags'                && doCreateCtags
      test "$action" == 'backup'                      && doCreateHostBackup
      test "$action" == 'create-link'           		&& doCreateLinkToMe
		test "$action" == 'save-files-permissions'		&& doCreateSetPermissionsScript
   );
   done
 
  test -z "$file_to_backup" || doBackupFile && action='single-file-backup'
  test -z "$action" && doCreateHostBackup

  doExit 0 "
  #----------------------------------------------------------
  # STOP MAIN 
  #----------------------------------------------------------
  " ;
}
#eof func main



# Action !!! call the main by passing the cmd args 
main "$@"


#
#------------------------------------------------------------------------------
# Purpose:
# to provide an easy starting template for writing bash and sh scripts
#------------------------------------------------------------------------------
# 
# with  the following features: 
# - prints the set in the script variables
# - separation of host specific vars into $0.$host_name.conf file
# - doLog function for both xterm and log file printing
# - for loop examples with head removal and inline find and replace 
# 
#------------------------------------------------------------------------------
#
# ErrorCodes 
# 1 --- Cannot find conf file 
# 2 --- called with a wrong cmd argument or -h for help 
# 
#------------------------------------------------------------------------------
#  EXIT CODES
# 
# 0 --- Successfull completion 
# 1 --- UnknownError 1 set in the beginning
# 2 --- Unknown cmd arg option supplied 
# 3 --- A configuration file is missing - Cannot find ini_file 
# 4 --- cannot chdir to 
# 5 --- no package available for deployment
# 6 --- A target dir has not been supplied 
# 7 --- A target dir for for deployment cannot be created 
#------------------------------------------------------------------------------
#
# VersionHistory: 
#------------------------------------------------------------------------------
#
# 1.1.3 --- 2015-05-05 13:47:22 --- ysg --- added support for relative file paths
# 1.1.2 --- 2014-08-19 11:22:12 --- ysg --- added tags file
# 1.1.1 --- 2014-08-19 07:21:06 --- ysg --- save 1 file if passed , all others if not
# 1.1.0 --- 2014-05-25 11:11:07 --- ysg --- added defaults in -a backupadded defaults in -a backup
# 1.0.9 --- 2014-05-25 11:02:13 --- ysg --- add file to files_to_backup_list_file
# 1.0.8 --- 2014-05-25 08:53:57 --- ysg --- added default for backup_root_dir
# 1.0.7 --- 2014-05-24 21:03:23 --- ysg --- enters and sort in output
# 1.0.5 --- 2014-05-24 11:35:07 --- ysg --- cleaner output of saved files
# 1.0.4 --- 2014-05-16 06:07:55 --- ysg --- check for file exists and empty
# 1.0.3 --- 2014-05-12 18:15:08 --- ysg --- set file_version=1.0.0 by default
# 1.0.2 --- 2014-05-06 15:23:37 --- ysg --- create-full-package
# 
#
#------------------------------------------------------------------------------
#
#eof file:file-saver.sh v1.9.6
