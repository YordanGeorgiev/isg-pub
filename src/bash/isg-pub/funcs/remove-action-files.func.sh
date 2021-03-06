# v1.3.0
# ---------------------------------------------------------
# obs we assume that the caller is in the product_instance_dir
# simply delete each file which greps finds to match to the action
# name(s) cnfigured in the :
# src/bash/aws-botter/tests/rem-aws-botter-actions.lst
# list file
# ---------------------------------------------------------
doRemoveActionFiles(){

   doLog "DEBUG START doRemoveActionFiles"


   # for each defined action
   while read -r act ; do (

      doLog "INFO STOP  :: removing action: $act"
      find . | grep $act | cut -c 3- | xargs rm -fv "{}"
      # remove the action files from the include files as well
      for env in `echo dev tst prd`; do (
         perl -pi -e 's/^(.*)'"$act"'(.*)$\\n//g' "$product_instance_dir/met/.$env.$run_unit"
      );
      done

   );
   done< <(cat 'src/bash/'"$run_unit"'/tests/rem-'"$run_unit"'-actions.lst')

   doLog "DEBUG STOP  doRemoveActionFiles"
}
# eof func doRemoveActionFiles


# eof file: src/bash/aws-botter/funcs/remove-action-files.func.sh

