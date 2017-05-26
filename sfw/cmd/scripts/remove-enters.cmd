:: File:remove_enters.cmd v.0.1.0 docs at the end
perl -e "use Win32::Clipboard ; $CLIP = Win32::Clipboard();$NEWCLIP=$CLIP->Get();$NEWCLIP=~s#\r\n##gi;$CLIP->Set($NEWCLIP);"
 
:: Purpose:
:: Remove enters from clipboard
::
:: Requirements
:: Windows , perl 
:: perl -MCPAN -e "install Win32::Clipboard"
::
:: Usage:
:: place in path, create shortcut on Desktop , assign AltGr + <<letter>>