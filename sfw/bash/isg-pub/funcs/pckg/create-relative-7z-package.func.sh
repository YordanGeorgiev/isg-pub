#!/bin/bash


#v0.9.1.1
#------------------------------------------------------------------------------
# creates a package from the relative file paths specified in the .dev file
#------------------------------------------------------------------------------
doCreateRelative7zPackage(){

	doLog "INFO :: START :: create-relative-7z-package.func"

	test -z "$pcking_pw" && doExit 1 " Empty packaging password-> do export pcking_pw=secret !!!"
	which 7z 2>/dev/null || { echo >&2 "The 7z binary is missing ! Aborting ..."; exit 1; }

	flag_completed=0
	cd $product_version_dir
	mkdir -p $product_dir/data/zip
		test $? -ne 0 && doExit 2 "Failed to create $product_version_dir/data/zip !"

	#define default vars
	test -z $include_file         && \
		include_file="$product_version_dir/meta/.$env_type.$wrap_name"

	# relative file path is passed turn it to absolute one 
	[[ $include_file == /* ]] || include_file=$product_version_dir/$include_file

	test -f $include_file || \
		doExit 3 "did not found any deployment file paths containing deploy file @ $include_file"

	# start: add the perl_ignore_file_pattern
	while read -r line ; do \
		got=$(echo $line|perl -ne 'm|^\s*#\s*perl_ignore_file_pattern\s*=(.*)$|g;print $1'); \
		test -z "$got" || perl_ignore_file_pattern="$got|$perl_ignore_file_pattern" ;
	done < <(cat $include_file)

	# or how-to remove the last char from a string 	
	perl_ignore_file_pattern=$(echo "$perl_ignore_file_pattern"|sed 's/.$//')
	echo perl_ignore_file_pattern::: $perl_ignore_file_pattern
	# note: | grep -vP "$perl_ignore_file_pattern" | grep -vP '^\s*#'
	
	timestamp=`date +%Y%m%d_%H%M%S`
	# the last token of the include_file with . token separator - thus no points in names
	zip_7z_file_name=$(echo $include_file | rev | cut -d. -f 1 | rev)
	zip_7z_file_name="$zip_7z_file_name.$product_version.$env_type.$timestamp.$host_name.rel.7z"
	zip_7z_file="$product_dir/$zip_7z_file_name"
	
	# All  input  patterns must match at least one file and all input files found must be readable.
	# 7z does recursively include all the contents of the dirs - and we want exactly the oppposite
	set -x
	ret=1
	cat $include_file | sort -u | while read -r line ; do test -f $line && echo $line ; done \
		| grep -vP "$perl_ignore_file_pattern" | grep -vP '^\s*#' | perl -ne 's|\n|\000|g;print'| \
		xargs -0 7z u -r0 -m0=lzma2 -mx=5 -p"$pcking_pw" -w"$product_version_dir" "$zip_7z_file"
	ret=$? ; set +x ;
	[ $ret == 0 ] || rm -fv $zip_7z_file
	[ $ret == 0 ] || doLog "FATAL !!! deleted $zip_7z_file , because of packaging errors !!!"
	[ $ret == 0 ] || exit 1

	cd $product_dir
	doLog "INFO created the following relative package:"
	doLog "INFO `stat -c \"%y %n\" $zip_7z_file_name`"

	mkdir -p $network_backup_dir && \
	cmd="cp -v $zip_7z_file $product_dir/data/zip/" && doRunCmdOrExit "$cmd" && \
	doLog "INFO with the following local backup  :" && \
	doLog "INFO `stat -c \"%y %n\" $product_dir/data/zip/$zip_7z_file_name`" && \
	doLog "INFO in the network dir @::" && \
	doLog "INFO :: $network_backup_dir" && \
	cmd="cp -v $zip_7z_file $network_backup_dir/$zip_7z_file_name" && doRunCmdOrExit "$cmd" && \
	doLog "INFO with the following network backup  :" && \
	doLog "INFO `stat -c \"%y %n\" \"$network_backup_dir/$zip_7z_file_name\"`"

	flag_completed=1
	
	doLog "INFO :: STOP  :: create-relative-7z-package.func"

}
#eof doCreateRelative7zPackage
