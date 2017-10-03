# src/bash/enricher/funcs/remove-package-files.func.sh

# v1.2.8
# ---------------------------------------------------------
# cat doc/txt/enricher/funcs/remove-package-files.func.txt
# ---------------------------------------------------------
doRemovePackageFiles(){

   doLog "DEBUG START doRemovePackageFiles"

	# Action !!!
	#define default vars
	test -z $include_file         && \
			 include_file="$product_instance_dir/meta/.$env_type.$run_unit"

   # for each file in the include file remove it if its file
   # but not the actual meta include file
   for file in `cat "$include_file"`; do (

		 file=$product_instance_dir/$file

		 # remove any file except the include file
		 if [ "$file" == "$include_file" ]
		 then
					continue      # Skip rest of this particular loop iteration.
		 fi
		 test -f $file && cmd="rm -fv $file" && doRunCmdAndLog "$cmd"

   );
   done

        test $action != 'remove-package' && cmd="rm -fv $include_file" && doRunCmdAndLog "$cmd"

   doLog "DEBUG STOP  doRemovePackageFiles"
}
# eof func doRemovePackageFiles


# eof file: src/bash/enricher/funcs/remove-package-files.func.sh
