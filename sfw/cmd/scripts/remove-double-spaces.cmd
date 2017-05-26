:: file:remove-double-space.cmd v.0.1.0 docs at the end
:: replace 2 or more space chars in the clip board with one space 
:: Action !!!
perl -e "use Win32::Clipboard ; $CLIP = Win32::Clipboard();$NEWCLIP=$CLIP->Get();$NEWCLIP=~s/[ ]{2,100}/ /gi;$CLIP->Set($NEWCLIP);"
:: debug pause 
::done exit
exit
::
::
:: Purpose:
:: --------------------------------------------------------
:: to remove double space in the clipboard ( Oracle Sql Developer generated 
:: code is full of time wasting spaces ... )
::
:: Requirements : 
:: --------------------------------------------------------
:: Windows OS, 
:: perl for Windows ( I use Strawberry perl ;o)
:: Win32::Clipboard module install by perl -MCPAN -e "install Win32::Clipboard;"
::
:: Usage:
:: --------------------------------------------------------
:: 1. place this cmd file in your path , double-click bat file 
:: 2. create a short cut of it , place on desktop 
:: 3. right click the shortcut , Properties , Click on ShortCut key , press S , click ok
:: From now AltGr + S will trigger the batch file 
::
:: VersionHistory:
:: --------------------------------------------------------
:: 1.0.0 -- 2014-11-07 10:05:27 -- ysg -- Initial creation
::
::
:: eof file:remove-double-space.cmd v.0.1.0 docs at the end