#!/usr/bin/perl -w
package isg_pub::db2_to_nz_converter; 
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
	our $SqlScriptsDir						= 'sfw/sql/db2/GS_DB' ; 
	my @SchemaFilesList= () ; 

	# names	
	our $ProductName							= q{} ; 
	our $project 								= q{} ; 
	our $ProductVersion						= q{} ;
	our $ProductType							= q{} ; 
	our $ProductOwner							= q{} ; 
	our $EnvironmentName						= q{} ; 
	our $HostName								= q{} ; 

	# paths	
	our $ProductBaseDir						= q{} ; 
	our $ProductDir							= q{} ; 
	our $ProductVersionDir 					= q{} ; 
	our $ProjVersionDir 							= q{} ; 
	our $ConfDir								= q{} ; 
	our $IniFile								= q{} ;
	our $confHolder 							= q{} ;
	our $ModuleIniFile 						; 
	
	# objects
	our $objConfigurator 	 				= q{} ;
	our $objLogger								= q{} ; 
	our $objFileHandler						= q{} ; 
	our $objFilePathBuilder 				= q{} ; 
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
		
		GetOptions(	
					 	"debug:s"				=>\$ModuleDebug
					, 	"proj-ver-dir:s"		=>\$ProjVersionDir
					, 	"load-xls:s"			=>\$CmdArgLoadXlsFile

		);

		my ( $ret , $msg , $debug_msg ) = doInitialize();
		


		unless ( $ret == 0 ) { 
			croak $msg ; 
			exit ( $ret ) ; 
		}


		$msg = "START Convertion from Db2 to nz";
		$objLogger->LogInfoMsg( "$msg" );
		$objLogger->LogInfoMsg( "module ini file : $ModuleIniFile" );


			
		doGetCreateSchemaDdlFiles(); 
			
		$msg = "STOP  --- Convertion from Db2 to nz";
		$objLogger->LogInfoMsg( "$msg" );
	}
	#eof main
	

	sub wanted {
    my $file = $File::Find::name;

	     if ($file =~ /_TABLES\.SQL$/ ) {
		  			push ( @SchemaFilesList , $file ) ; 
		          print "$file \n";
			}
	}




	sub doGetCreateSchemaDdlFiles {
	
		

		#  find /var/oxit/mini-nz/mini-nz.0.3.0.dev.ysg/ -name '*TABLES.SQL'
		#  /var/oxit/mini-nz/mini-nz.0.3.0.dev.ysg/sfw/sql/db2/GS_DB/GOSALESDW_TABLES.SQL
		#  /var/oxit/mini-nz/mini-nz.0.3.0.dev.ysg/sfw/sql/db2/GS_DB/GOSALESRT_TABLES.SQL
		#  /var/oxit/mini-nz/mini-nz.0.3.0.dev.ysg/sfw/sql/db2/GS_DB/GOSALESMR_TABLES.SQL
		#  /var/oxit/mini-nz/mini-nz.0.3.0.dev.ysg/sfw/sql/db2/GS_DB/GOSALES_TABLES.SQL
		#  /var/oxit/mini-nz/mini-nz.0.3.0.dev.ysg/sfw/sql/db2/GS_DB/GOSALESHR_TABLES.SQL

		#1. Get the list of the ddl schema_create_tables files
		File::Find::find({ wanted => \&wanted, no_chdir=>1}, $SqlScriptsDir );
		#2. Foreach file
		foreach my $schema_file ( @SchemaFilesList ) {
			#2.1. Strip the schema name
			my $schema = $schema_file ; 
			$schema =~ s/(.*)\/(.*?)_(.*)/$2/g ; 
			
			#2.2. Build the output dir
			my $OutPutDir = "$ProjVersionDir/sfw/sql/nz/GS_DB/$schema" ; 
			
			#2.3. Do parse the schema create tables file
			doParseSchemaFile ( $schema_file ) ; 

		} #eof foreach schema file


	}
	#eof sub doGetCreateSchemaDdlFiles

	sub doParseSchemaFile {
		my $schema_file = shift ; 

		#2.3.1 Read file into string
		my $str_schema = $objFileHandler->ReadFileReturnString ( $schema_file ) ; 

		#2.3.3 Search and replace the echo "creatign tables "
		$str_schema =~ s/^.*echo .*$//mg ; 
		
		#2.3.3 Search and replace the obsolete '@' with ';' chars
		$str_schema =~ s/@/;/mg ; 
		#2.3.3 Search and replace the in table space
		$str_schema =~ s/^IN .*$//mg ; 
		#2.3.3 search and replace the ugly braces
		$str_schema =~ s/\)/\) /mg ; 
		$str_schema =~ s/\(/\( /mg ; 
		# fancy style commas in sql
		$str_schema =~ s/,\n/\n , /mg ; 
		# strip the line with comments 
		$str_schema =~ s/^\-\-.*$//mg ; 
		# close the bracker for the table 	
		$str_schema =~ s/NULL\)/NULL \n \) DISTRIBUTE ON RANDOM /mg ; 
		$str_schema =~ s/;\s+$//mg ; 
		#print $str_schema . "\n" ; 

		#2.3.2 Split file into different ddls per table 
		my @str_ddls = split ( ';' , $str_schema ) ; 
		my $c = 0 ; 
		foreach my $str_ddl ( @str_ddls ) { 
			if ( $c == 0 ) { $c++ ; next } ; 
			print "str_ddl : $str_ddl \n\n\n" ; 
			#2.3.2.1 Write the create statement file
			my $table = ( split /\n/, $str_ddl )[1] ; 
			my $schema = ( split /\n/, $str_ddl )[1] ; 
			$table =~ s/CREATE TABLE (.*?)\.(.*?)\s+\(/$2/g ; 
		 	$table =~ s/^\s+//; $table =~ s/\s+$//;
			$schema =~ s/CREATE TABLE (.*?)\.(.*?)\s+\(/$1/g ; 
		 	$schema =~ s/^\s+//; $schema =~ s/\s+$//;
			print "table is \"$table\" \n" ; 
			print "schema is \"$schema\" \n" ; 
			my $digits_count = length $c ; 
			$c = '0' . $c if ( $digits_count < 2 ) ; 
			my $ddl_file = "$ProjVersionDir/sfw/sql/nz/GS_DB/$schema/" ; 
			$ddl_file .= $c . '.' . $table . '.create-table.sql' ; 
			my $ddl_file_tst = "$ProjVersionDir/sfw/sql/nz/GS_DB/$schema/" ; 
			$ddl_file_tst .= $c . '.' . $table . '.create-table-test.sql' ; 
			
			my $str_ddl_file_tst = "
			SELECT TABLENAME,OWNER,CREATEDATE
			FROM _V_TABLE
			WHERE 1=1
			AND OBJTYPE='TABLE'
			AND TABLENAME = '" . $table . "'
			-- AND OWNER = 'GOSALESDW'
			;" ; 
			$objFileHandler->PrintToFile ( $ddl_file , $str_ddl ) ; 
			#2.3.2.3 Write the tesst create statement file
			$objFileHandler->PrintToFile ( $ddl_file_tst , $str_ddl_file_tst ) ; 
			$c++ ; 
		}
		




	}
	#eof sub doParseSchemaFiel


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
		
		# this loader operates on the shell always ... 
		$confHolder->{'PrintConsoleMsgs'} = 1 ; 
	
		# create the utility objects 
		$objLogger 			 = 'isg_pub::Control::Utils::Logger'->new( \$confHolder );
		$objFileHandler 	 = 'isg_pub::Control::Utils::FileHandler'->new( \$confHolder );
		
		# set all ok
		$ret = 0 ; 
		$msg = '' ; 

		# http://stackoverflow.com/a/1481979/65706
		unless ( -d $ProjVersionDir  ) {
			$ProjVersionDir=$ENV{'proj_version_dir'} ; 
			#debug print "1: ProjVersionDir is $ProjVersionDir " . "\n" ; sleep 10 ; 
			unless  ( -d $ProjVersionDir  ) {
				$ProjVersionDir=$ProductVersionDir
			}
		}

		#debug print "2 ProjVersionDir is $ProjVersionDir " . "\n" ; sleep 10 ; 

		$ModuleIniFile  = 
			"$ProjVersionDir/conf/hosts/$HostName/ini/Db2ToNzConverter.$HostName.ini"  ; 
		
		$SqlScriptsDir = "$ProjVersionDir/$SqlScriptsDir" ; 
		return ( $ret , $msg , $debug_msg ) ; 

	}
	#eof sub doInitialize


	#Action !!!	
	main();


1;

__END__


