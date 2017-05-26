@echo off
:: File: sfw/cmd/test/test-site-uris.cmd

call GetNiceTime.cmd
:: go the run dir
cd %~dp0z
:: this is the dir containing the batch file
set _MyDir=%CD%

for %%A in (%0) do set _MyDriveLetter=%%~dA
for %%A in (%0) do set _MyPath=%%~pA
for %%A in (%0) do set _MyName=%%~nA
for %%A in (%0) do set _MyEtxtension=%%~xA

set _CatFile=%_MyDir%\%_MyName%.lst
set _Program=chrome

set _
:: DEBUG PAUSE


:: for each line of the cat file do perform an action ( in this case open url with opera ) 
for /f "tokens=*" %%i in ('type "..\..\..\conf\hosts\doc-pub-host\lst\isg-pub\remote-uri.lst"') do cmd /c start /max %_Program% "%%i"



:: DEBUG PAUSE

:: Purpose: 
:: to provide a generic stub starter fo.cmd files
:: 
:: Usage: 
:: copy this file to a folder where you would like to start the development of th.cmd file 
:: with some customer logic 
:: create a .cmd_file_name>>.cat file with an item per like in the same directory 
:: change the program name in the _Program var
:: 
:: VersionHistory: 
:: 1.0.1 --- 2013-04-15 08:19:10 --- ysg --- added - todo-%today%.txt file opening
:: 1.0.0 --- 2012-05-23 09:08:57 --- ysg -- Initial creation 
