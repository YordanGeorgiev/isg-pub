#!/usr/bin/perl -w
package isg_pub::load ; 
	use strict ; use warnings ; use diagnostics;

	$|++;
	
	require Exporter ; 
	our @ISA = qw(Exporter);
	our %EXPORT_TAGS = ( 'all' => [ qw() ] );
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
	our @EXPORT = qw() ; 
	our $AUTOLOAD =();

	use utf8 ; 
	use Carp ; 
	use Cwd qw ( abs_path ) ; 
	use Getopt::Long;
	
   BEGIN {
		use Cwd qw (abs_path) ; 
      my $my_inc_path = Cwd::abs_path( $0 );

      $my_inc_path =~ m/^(.*)(\\|\/)(.*?)(\\|\/)(.*)/;
      $my_inc_path = $1;

		unless (grep {$_ eq "$my_inc_path"} @INC) {
      	push ( @INC , "$my_inc_path" );
			$ENV{'PERL5LIB'} .= "$my_inc_path" ;
		}
      
		unless (grep {$_ eq "$my_inc_path/lib" } @INC) {
      	push ( @INC , "$my_inc_path/lib" );
			$ENV{'PERL5LIB'} .= ":$my_inc_path/lib" ;
		}
   }

	use isg_pub::Control::Utils::Initiator ; 
	use isg_pub::Control::Utils::Configurator ; 
	use isg_pub::Control::Utils::Logger ; 
	use isg_pub::Control::Utils::ETL::ExcelToMariaDbLoader ; 


	#
	# -----------------------------------------------------------------------------
	# start vars
	# -----------------------------------------------------------------------------
	#
	# start vars
	our $ModuleDebug 							= 0 ; 
	our $ScriptExitCode 						= 1 ; 
	# the type of load 
	our $LoadModel								= 'upsert' ; 

	# names	
	our $ProductName							= q{} ; 
	our $project 								= q{} ; 
	our $ProductVersion						= q{} ;
	our $ProductType							= q{} ; 
	our $ProductOwner							= q{} ; 
	our $EnvironmentName						= q{} ; 
	our $HostName								= q{} ; 
	our $lang_code 							= 'en' ; 

	# paths	
	our $ProductBaseDir						= q{} ; 
	our $ProductDir							= q{} ; 
	our $ProductVersionDir 					= q{} ; 
	our $ProjectDir 							= q{} ; 
	our $ConfDir								= q{} ; 
	our $IniFile								= q{} ;
	our $confHolder 							= q{} ;
	our $ModuleIniFile 						; 
	
	# objects
	our $objConfigurator 	 				= q{} ;
	our $objLogger								= q{} ; 
	our $objFilePathBuilder 				= q{} ; 
	our $objCGI 								= q{} ; 
	our $objItem 								= q{} ; 
	our $LoadTables							= q{} ; 
	our $CmdArgLoadXlsFile					= q{} ; 

	#
	# -----------------------------------------------------------------------------
	# stop vars
	# -----------------------------------------------------------------------------


	#
	# -----------------------------------------------------------------------------
	# the main entry point of the cgi script
	# -----------------------------------------------------------------------------
	sub main {
		
		my $die_msg = "\n\n Undefined working Project !!! Run : \n" ; 
		$die_msg .= "doParseIniEnvVars <<Path-to-Conf-Ini-File , for example: \n" ; 
		$die_msg .= "doParseIniEnvVars sfw/sh/isg-pub/isg-pub.isg-pub.doc-pub-host.conf \n\n\n"  ;
		

		die "$die_msg" unless ( length $ENV{'project'} ) ; 
		my $Project = $ENV{'project'} ;

		GetOptions(	
					 	"lang:s"					=>\$lang_code
					, 	"debug:s"				=>\$ModuleDebug
					, 	"project-dir:s"		=>\$ProjectDir
					, 	"tables:s"				=>\$LoadTables
					, 	"load-model:s"			=>\$LoadModel
					, 	"load-xls:s"			=>\$CmdArgLoadXlsFile

		);

		my ( $ret , $msg , $debug_msg ) = doInitialize();
		$LoadModel = 'nested-set' unless $LoadModel ; 

		# http://stackoverflow.com/a/1481979/65706
		unless ( length $ProjectDir or -d $ProjectDir  ) {
			$ProjectDir=$ENV{'proj_version_dir'} ; 
			#debug print "1: ProjectDir is $ProjectDir " . "\n" ; sleep 10 ; 
			unless  ( length $ProjectDir or -d $ProjectDir  ) {
				$ProjectDir=$ProductVersionDir
			}
		}
		else {

		}

		#debug print "2 ProjectDir is $ProjectDir " . "\n" ; sleep 10 ; 
		$CmdArgLoadXlsFile	= "$ProjectDir/docs/xls/$Project/en/$Project-en.xlsx"
			unless ( $CmdArgLoadXlsFile ) ; 
		
		die "cannot find xls file to load " unless ( -r $CmdArgLoadXlsFile );

		unless ( $ret == 0 ) { 
			croak $msg ; 
			exit ( $ret ) ; 
		}

		$ModuleIniFile  = 
			"$ProjectDir/conf/hosts/$HostName/ini/ExcelToMariaDbLoader.$HostName.ini"  ; 

		$msg = "START ExecuteRunXlsToMariaDbCommand";
		$objLogger->LogInfoMsg( "$msg" );
		$objLogger->LogInfoMsg( "module ini file : $ModuleIniFile" );
		#debug sleep 5 ; 


		#sleep 2 ; 

		$objLogger->LogDebugMsg ( "lang_code: $lang_code" ) ; 
		#debug sleep 5 ; 


		$msg = "ModuleIniFile : " ; 
		$objLogger->LogDebugMsg ( $msg ) ; 
		$msg = "$ModuleIniFile " ; 
		$objLogger->LogDebugMsg ( $msg ) ; 

		#	sleep 5 ; 

		my $objExcelToMariaDbLoader = 
			"isg_pub::Control::Utils::ETL::ExcelToMariaDbLoader"->new ( 
				  $ProjectDir
				, $ModuleIniFile
				, \$confHolder  
				, $lang_code
				, $LoadTables
				, $LoadModel
				, $CmdArgLoadXlsFile
			) ;
			
		my ( $ScriptExitCode, $ModuleExitMsg ) = ( 1 , 1 ) ; 
		#debug sleep 2 ; 
		( $ScriptExitCode, $ModuleExitMsg ) = $objExcelToMariaDbLoader->main();

		$objLogger->LogDebugMsg( "dumpFields " . $objExcelToMariaDbLoader->dumpFields() );

		$msg = "STOP ExecuteRunXlsToMariaDbCommand";
		$objLogger->LogInfoMsg( "$msg" );

		return ( $ScriptExitCode, $ModuleExitMsg ) unless $ScriptExitCode == 0 ; 




		return ( $ScriptExitCode, $ModuleExitMsg )  ; 

	}
	#eof main
	

	#
	# ---------------------------------------------------------
	# Initializes the minimum amount of vars to be able to fetch
	# the default settings from the default ini files if not passed
	# ---------------------------------------------------------
	sub doInitialize {

		# a default paranoia by having failed initialization and msg vars 
		my $msg 						= 'unknown application initialization error !!!' ; 
		my $debug_msg 				= '' ; 
		my $ret 						= 1 ; 

		my $objInitiator 			= 'isg_pub::Control::Utils::Initiator'->new();	
		$confHolder					= {} ;
		$ProductBaseDir 			= $objInitiator->doResolveMyProductBaseDir();
		$ProductDir 				= $objInitiator->doResolveMyProductDir();
		$ProductVersionDir 		= $objInitiator->doResolveMyProductVersionDir();
		$EnvironmentName 			= $objInitiator->doResolveMyEnvironmentName();
		$ProductName 				= $objInitiator->doResolveMyProductName();
		$ProductVersion 			= $objInitiator->doResolveMyProductVersion();
		$ProductType 				= $objInitiator->doResolveMyProductType();
		$ProductOwner 				= $objInitiator->doResolveMyProductOwner();
		$IniFile 					= $objInitiator->doResolveMyIniFile();
		$HostName					= $objInitiator->doResolveMyHostName();
		$confHolder					= $objInitiator->get ('confHolder'); 


		# if the ini file does not exist try with the default settigns 
		unless ( -f $IniFile && -T $IniFile ) {
			$msg .= " [ERROR] The ini configuration file: \n" ;
			$msg .= "$IniFile" ; 
			$msg .= "DOES NOT EXIST !!! USING DEFAULT SETTINGS ..." ; 
		}
		else {
			$objConfigurator 		= 'isg_pub::Control::Utils::Configurator'->new ( 
				$IniFile, \$confHolder ) ; 


			# pring the hash vars
			if ( $ModuleDebug == 1 ) {
				$debug_msg 	.= $objConfigurator->dumpIni(); 
				$msg .= $objConfigurator->DumpEnvVars();
			}
		} 
		#eof else
		
		# this loader operates on the shell always ... 
		$confHolder->{'PrintConsoleMsgs'} = 1 ; 
	
		# create the utility objects 
		$objLogger 			 = 'isg_pub::Control::Utils::Logger'->new( \$confHolder );
		
		# set all ok
		$ret = 0 ; 
		$msg = '' ; 


		return ( $ret , $msg , $debug_msg ) ; 

	}
	#eof sub doInitialize


	#Action !!!	
	main();


1;

__END__


