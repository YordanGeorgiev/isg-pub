package isg_pub::Control::Utils::ETL::ExcelToMariaDbLoader ; 
	use strict ; use warnings ; 
	use utf8 ; 
	my $VERSION = '1.0.0';

	require Exporter; 
	use AutoLoader ; 
	use base "isg_pub::Control::Utils::ETL::Loader"  ; 

	use File::Find ; 
	use Cwd ; 
	use Sys::Hostname ; 
	use Env ; 

	my @EXPORT = qw(main);

	use Spreadsheet::XLSX;
	use Text::Iconv;
	use DBI ; 
	use Data::Printer ; 

	use isg_pub::Control::Utils::Initiator ; 
	use isg_pub::Control::Utils::Configurator ; 
	use isg_pub::Control::Utils::Logger ; 
	use isg_pub::Control::Utils::FileHandler ; 



	### START setting package vars
	# start vars	
	#  anonymous hash !!!
	our   $ModuleDebug 												= 0 ; 
	our 	$LoadModel													= 'upsert' ; 
	our   $do_use_threads											= 0 ; 
	our 	$do_use_files_conf										= 0 ; 
	our 	$hsLevelsTree												= {} ; 
	our 	$hsIdsTree													= {} ; 
	
	our ( $confHolder , $confHolderOfObj , $FileConfig , $MyBareName )= () ; 
	our ( $objFileHandler , $objLogger , $objProcessHandler  ) = () ; 
	our ( $SqlInstallDir , $NewSqlFilesInstallDir , $TokenDelimiterAsciiNumber ) = () ; 
	our ( $RowEnd , $InputExcelFile , $VersionDir ,  ) 	= () ; 

	our ( $ModuleFileConfig ) 										= () ; 
	our 	$mysql_host													= () ;  
	our 	$mysql_port													= () ; 
	our ( $mysql_user , $mysql_user_pw ) 						= () ; 
	our ( $EnvironmentName ) 										= () ; 
	our ( $html_index_file ) 										= () ; 
	our ( $listing_html_index_file ) 							= () ; 
	our   $hsFiles 													= {} ; 	
	our ( $Project ) 													= () ; 
	our ( $ProjectBaseDir , $ProjectDir  , $ProductDir) 	= () ; 
	our $ProductVersionDir 											= q{} ; 
	our ( $ProjectDataDir , $ProjectDbDataDir )				= () ;	
	our ( $dbh , $sth ) 												= () ; 
	our $hSheetTables													= {} ; 
	our $HostName														= () ;  
	our $project_db 													= '' ; 
	our $lang_code 													= 'en' ; 
	our $refItems 														= q{} ; 
	our $sheets 														= () ;
	our @sheets 														= () ; 
	our @Tables 														= () ; 
	our $LoadTables 													= q{} ; 
	our $CurrentItemId												= q{} ; 
	our $PreviousItemId												= q{} ; 
	our $PreviousLevel 												= q{} ; 
	our $ParentHasChildren											= q{} ; 
	our $ParentLevel													= q{} ; 
	our $PrevSeqId														= 0 ; 
	our $CmdArgLoadXlsFile											= q{} ; 

	my $num0 = 0 ; 
	my $num1 = 0 ; 
	my $num2 = 0 ; 
	my $num3 = 0 ; 
	my $num4 = 0 ; 
	my $num5 = 0 ; 
	my $Num 	= '' ; 
	### stop vars




	# -----------------------------------------------------------------------------
	# main entry point of the module
	# -----------------------------------------------------------------------------
	sub main {
		
		my $self = shift ; 
		my $ret = 1 ; 
		my $msg = "unknown error occured !!!" ; 
		
		$msg = "START MAIN = ExcelToMariaDbLoader" ; 
		$msg .= '@main:: LoadModel: ' . "$LoadModel" ; 
		$objLogger->LogInfoMsg ( "$msg" ) ;  
		
		
		if ( $LoadModel eq 'denormalized' ) {

			my @sheets = () ; 
			my $hsXls = $self->doXlsToHashOfHashes();
			#debug p($hsXls ) ; 
			push ( @sheets , split(',',$LoadTables) ) ; 

			foreach my $sheet ( @sheets )  {
				chomp($sheet);
				my $hsWorkSheet = $hsXls->{ "$sheet" } ; 
				my $hsTWorkSheet = 
						$self->doDeNormalizeHsWorkSheetToHsCellValue ( $sheet , $hsWorkSheet ) ; 
				p ( $hsTWorkSheet ) ; 
				#debug sleep 100 ; 
				$self->doRunDeNormalizedUpsertSql ( $sheet , $hsTWorkSheet ) ; 
			}
			$ret = 0 ; $msg = "denormalized" ; 
			return  ( $ret , $msg  ) ; 
		} #eof if

	
		# if we want to load only 1 table ( override from cmd line ) 
		if ( $LoadTables ) {
			$refItems 				= {} ;

			$refItems->{'1'}->{'doTruncTable'} = '1' ; 

			@sheets = () ; 
			@Tables = () ; 
			my $key_counter = 1 ; 
			push ( @sheets , split(',',$LoadTables) ) ; 
			foreach my $sheet ( @sheets )  {
				chomp($sheet);
				$refItems->{"$key_counter"}->{'Sheet'} = $sheet ; 
				#debug print "sheet: $sheet \n" ; 
				#debug sleep 1 ; 
				$key_counter++ ; 
			}
			#old push ( @sheets , $LoadTables ) ; 
			push ( @Tables , split(',',$LoadTables) ) ; 
			$key_counter = 1 ; 
			foreach my $table ( @Tables ) {
				chomp($table ) ; 
				$refItems->{"$key_counter"}->{'TableName'} = $table ; 
				# debug print "table: $table \n" ; 
				$key_counter++ ; 
				#debug sleep 1 ; 
			}

			#$old refItems->{"1"}->{'TableName'} = $LoadTables ; 
			#old push ( @Tables , $LoadTables ) ; 
		}
		else {
			$refItems = $self->doGetItems();
		}
		$objLogger->LogHashRef ( $refItems ) if ( $ModuleDebug == 1 ) ; 

		unless ( %{$refItems} ) {
			$msg = "trying to load an EMPTY list of tables " ; 
			$objLogger->LogErrorMsg ( "$msg" ) ; 
			$msg = "changing automatically to conf files based loading" ; 
			$objLogger->LogInfoMsg ( "$msg" ) ; 
			$msg = "foreach line in sheets.lst to each line in Tables.lst" ; 
			$objLogger->LogInfoMsg ( "$msg" ) ; 
			$do_use_files_conf = 1 ; 
			$refItems = {} ; 
		}


		# if no data in db fetch the list to load from the conf files	
		unless ( $do_use_files_conf == 1 ) {	
			$msg = "loading the xls data from the ItemController db table" ; 
			$objLogger->LogInfoMsg (  "$msg" ) ; 
			
			@sheets = () ; 
			@Tables = () ; 

			# populate the list of the sheets to parse into the list of tables to load to
			foreach my $key ( sort ( keys(%{$refItems}) ) ) {
				push ( @sheets ,  		$refItems->{"$key"}->{'Sheet'} ) ; 
				push ( @Tables ,  		$refItems->{"$key"}->{'TableName'} ) ; 
			}

			chomp(@sheets) ;		# just in case 
			chomp(@Tables )  ; 	# just in case 

			} else {

				$msg = "loading the xls data from the sheets.lst configuration file " ; 
				$objLogger->LogInfoMsg ( "$msg" ) ; 
				$msg = "$ProjectDir/conf/hosts/$HostName/lst/$Project/sheets.lst" ;
				$objLogger->LogInfoMsg ( "$msg" ) ; 

				my $sheets = $objFileHandler->ReadFileReturnArrayRef ( 
					"$ProjectDir/conf/hosts/$HostName/lst/$Project/sheets.lst" ) ; 
				@sheets = @$sheets ;  
				my $Tables = $objFileHandler->ReadFileReturnArrayRef ( 
					"$ProjectDir/conf/hosts/$HostName/lst/$Project/Tables.lst" ) ; 
				@Tables = @$Tables ;  
				chomp(@Tables ) ; 
				chomp(@sheets ) ; 

				$refItems = {} ; # just in case create a hash ref
				my $i = 0 ; 
				foreach my $sheet ( @sheets ) {
					$refItems->{"$i"} = {} ; 
					$refItems->{"$i"}->{'Sheet'} 			= "$sheet" ; 
					$refItems->{"$i"}->{'TableName'} 	= $Tables[$i] ; 
					$refItems->{"$i"}->{'doTruncTable'} = 1 ; 
					$i++ ; 
				}
				#eof foreach
		} 
		#eof else using do_use_file_conf


		$objLogger->LogInfoMsg ( "going to parse the following sheets:" ) ; 
		$objLogger->LogArray (\@sheets  , 'INFO')  ;
		$objLogger->LogInfoMsg ( "and load them into the following tables:" ) ;
		$objLogger->LogArray (\@Tables  , 'INFO')  ;
	
		# if the number of the sheets to load does not match the num of the tables to load
		# do exit with error 
		if ( $#sheets != $#Tables ) {
			$msg = " MISMATCH BETWEEN THE NUMBER OF SHEETS TO LOAD TO THE NUMBER OF TABLES" ; 
			$objLogger->LogFatalMsg ( $msg ) ; 
			$msg = " check the sheets.lst and Tables.lst files or the ItemController table" ; 
			$objLogger->LogFatalMsg ( $msg ) ; 
			return ( 2 , " failed to laod the data from xls " ) ; 
		}
		#eof if

		#check whether we can use threads 
 		my $can_use_threads = eval 'use threads; 1';
  		if ($can_use_threads && $do_use_threads == 1 ) {

			my $msg = 'using parallel threaded loading ' ; 	
			$objLogger->LogInfoMsg ( "$msg \n" ) ; 

			
			my @threads = () ; 
			
			# iterate over the keys of the hash reference of hash references 
			foreach my $key ( sort(keys( %{$refItems} ) ) ) {
				my $sheet_to_parse 	= $refItems->{"$key"}->{'Sheet'} ; 
				my $table_to_load 	= $refItems->{"$key"}->{'TableName'} ; 

				my $refHashItem 		= $refItems->{"$key"} ; 
				$objLogger->LogInfoMsg ( "parsing sheet: $sheet_to_parse " ) ; 
				$objLogger->LogInfoMsg ( "loading table: $table_to_load " ) ; 
				
				#http://perldoc.perl.org/threads.html
				# threads must be implicitly created in list context
				my ( $thr) = 
					threads->create(\&doParseExcelSheet
						, $self , $sheet_to_parse , $table_to_load , $refHashItem) ; 
				# and store it 
				push ( @threads , $thr )  ;
			} 
			#eof foreach key

			#issue-290
			# wait for this thread to finnish
			foreach my $thread ( @threads ) {
            ( $ret , $msg ) = $thread->join();
				my $out_msg = '' ; 
				$out_msg = 'joing data loading thread with the following outcome:' ; 
				$objLogger->LogDebugMsg ( "$out_msg" ) ; 
				$out_msg = "$msg , return value : $ret" ; 
				$objLogger->LogDebugMsg ( "$out_msg" ) ; 
				return ( $ret , $msg ) unless ( defined ( $ret ) or $ret == 0 ) ;
			}

			threads->yield();

			# my $hsXls = $self->doXlsToHashOfHashes();
			# p($hsXls) ; 

		} else {

			my $msg = 'using sequential non-threaded loading ' ; 	
			$objLogger->LogInfoMsg ( "$msg \n" ) ; 

			my $table_counter = 0 ; 

			foreach my $sheet_to_parse ( @sheets ) {
				chomp ( $sheet_to_parse ) ; 
				my $table_to_load = $Tables [ $table_counter ] ; 
				chomp ( $table_to_load ) ; 
				$objLogger->LogInfoMsg ( "Table to load : $table_to_load " ) ; 

				my $refHashItem->{'doTruncTable'} = 1 ; 
				$table_counter++ ; 

				( $ret , $msg ) = 
						$self->doParseExcelSheet ( $sheet_to_parse , $table_to_load , $refHashItem ) ; 
			return $ret , $msg unless ( $ret == 0 ) ; 

			}
			#eof foreach
		}
		#eof else we can use threads


		return $ret , $msg unless ( defined ( $ret ) or $ret == 0 ) ; 

		$msg = "STOP  MAIN = ExcelToMariaDbLoader" ; 
		$objLogger->LogInfoMsg ( "$msg" ) ;  

	} 
	#eof sub main 

	#
	# ------------------------------------------------------
	# get the meta data for menus building and control
	# ------------------------------------------------------
	sub doGetItems {
		
		my $self = shift ; 
		my $ref 	= () ; 

      # debug print "usging the following db $project_db \n" ; 

      
		my $dbh = DBI->connect("dbi:mysql:database=$project_db;host=$mysql_host",
					"$mysql_user","$mysql_user_pw",{AutoCommit=>1,RaiseError=>1,PrintError=>1});
		
		my $sql   = () ; 
		$sql 		.= " SELECT ItemController.* , ItemModel.* FROM ItemController " ; 
		$sql 		.= " INNER JOIN ItemModel on ( ItemController.ItemControllerId = ItemModel.ItemControllerId ) " ; 
		$sql 		.= " WHERE 1=1 AND doLoadData = 1 order by 2 ASC"  ; 

		my $sth 	= $dbh->prepare("$sql" );
		$sth->execute() or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ; 

      $ref = $sth->fetchall_hashref('SeqId') or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ; 
		
		$dbh->disconnect;

		return $ref ; 
				    
	} 
	#eof sub GetItems
	
	#
	# -----------------------------------------------------------------------------
	# opens mariadb connection 
	# -----------------------------------------------------------------------------
	sub OpenConnection {
		my $self = shift ; 
		my $msg 	= "" ; 

      # debug print "usging the following db $project_db \n" ; 
      # debug sleep 2 ; 

		$dbh = DBI->connect("dbi:mysql:database=$project_db;host=$mysql_host",
			"$mysql_user","$mysql_user_pw",{AutoCommit=>1,RaiseError=>1,PrintError=>1});


		$msg = $DBI::errstr if ( $DBI::errstr );
		$objLogger->LogFatalMsg ( $msg ) if ( $msg) ; 

		return 1 , $msg if ( $msg ) ; 
		return 0 ; 

		$objLogger->LogDebugMsg (  " == START == db connection" ) 
				if $ModuleDebug == 1 ; 
	}
	#eof sub OpenConnection

	#
	# -----------------------------------------------------------------------------
	# close the mariadb connection to prevent memory leackage
	# -----------------------------------------------------------------------------
	sub CloseConnection {
		$dbh->disconnect;
		$objLogger->LogTraceMsg (  " == STOP  == db connection" ) 
				if $ModuleDebug == 1 ; 
	}
	#eof sub CloseConnection


	#
	# -----------------------------------------------------------------------------
	# adds an item in the nested-set model which parent does have children
	#
	# -----------------------------------------------------------------------------
	sub doAddItemToParentWithChildren {

			my $self  				= shift ; 
			my $table_name			= shift ; 
			my $sibling_id		 	= shift ; 
			
			my $ret 					= 0 ; 
			my $msg					= q{} ; 
			my $pLeftRank			= 0 ; 
			my $pRightRank			= 0 ; 
			my $LeftRank			= 1 ; 
			my $RightRank			= 2 ; 
			my $sql_str 			= q{} ; 
			
			$sql_str 				= '
				SELECT RightRank 
				FROM ' . $table_name . '
				where ' . $table_name . 'Id = ? '
			; 
			$sth = $dbh->prepare( $sql_str ) ; 

			#todo how-to find out generically my sibling ?!
			$sth->execute ( $sibling_id ) or $ret = 1  ;
			$msg = $DBI::errstr if ( $ret == 1 ) ; 
			$objLogger->LogFatalMsg ( $msg ) if $ret == 1 ; 

			my @row = $sth->fetchrow_array ; 
			#debug $objLogger->LogDebugMsg ( "row " . @row);
			if ( @row ) {
			   ( $pRightRank ) =  @row   ; 
         } else {
            $pRightRank = 0 ; 
         }

			#$objLogger->LogDebugMsg ( "pRightRank: \"" . $pRightRank . "\"" );
			$sth->finish;


			$LeftRank 				= $pRightRank + 1 ; 
			$RightRank 				= $pRightRank + 2 ; 
			#debug $objLogger->LogDebugMsg ( "LeftRank: \"" . $LeftRank  . "\"");
			#debug $objLogger->LogDebugMsg ( "RightRank: \"" . $RightRank . "\"" );

			
			# shift the left rank to the right 
			$sql_str = '
				UPDATE ' . $table_name . '
				set LeftRank = ( LeftRank + 2 ) 
				WHERE 1=1 
				AND LeftRank > ? ' 
			; 
			$sth = $dbh->prepare( $sql_str ) ; 
			#$sth = $dbh->prepare(qq( 
			#	UPDATE Item 
			#	set LeftRank = ( LeftRank + 2 ) 
			#	WHERE 1=1 
			#	AND LeftRank > ? 
			#));
			$sth->execute( $pRightRank ) or $ret = 1  ;
			$msg = $DBI::errstr if ( $ret == 1 ) ; 
			$objLogger->LogFatalMsg ( $msg ) if $ret == 1 ; 
			$sth->finish;
	

			# shift the right rank to the right 
			$sql_str = '
				UPDATE ' . $table_name . '
				set RightRank = ( RightRank + 2 ) 
				WHERE 1=1 
				AND RightRank > ? 
			';
			$sth = $dbh->prepare( $sql_str ) ; 
			#$sth = $dbh->prepare( qq(
			#	UPDATE Item 
			#	set RightRank = ( RightRank + 2 ) 
			#	WHERE 1=1 
			#	AND RightRank > ? 
			#));
			$sth->execute( $pRightRank ) or $ret = 1  ;
			$sth->finish;
			$msg = $DBI::errstr if ( $ret == 1 ) ; 
			$objLogger->LogFatalMsg ( $msg ) if $ret == 1 ; 
			$ret = 0 ; $msg = 'subordinate shifting ok' ; 

			return ( $LeftRank , $RightRank ) ; 

	}
	#eof sub doAddItemToParentWithChildren


	#
	# -----------------------------------------------------------------------------
	# just a debugger to see WTF is going on ...
	# -----------------------------------------------------------------------------
	sub doListTable {

			my $self  				= shift  ;
			my $table_name 		= shift ; 
			my $msg 					= q{} ; 
			my $ret 					= 0 ; 

			$self->OpenConnection();
			my $sql_str = "
				SELECT 
				node.*

				FROM " . $table_name . " AS node,
				" . $table_name . " AS parent

				WHERE 1=1
				AND node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
				AND parent." . $table_name . "Id = '0'

				ORDER BY node.SeqId" 
			; 
			
			$objLogger->LogDebugMsg ( $sql_str ) ; 
			# retrieve the full hierarchy
			$sth = $dbh->prepare( 
				$sql_str
			);

			$sth->execute ( ) or $ret = 1  ;
			$msg = $DBI::errstr if ( $ret == 1 ) ; 
			$objLogger->LogFatalMsg ( $msg ) if $ret == 1 ; 

			#debug			while ( my @row = $sth->fetchrow_array  ) {
			#debug				p(@row);
			#debug			}
			#eof while

			$self->CloseConnection();

	}
	#eof sub doListTable
	
	#
	# -----------------------------------------------------------------------------
	# just a debugger to see WTF is going on ...
	# -----------------------------------------------------------------------------
	sub doListTableHierarchy {

			my $self  				= shift  ;
			my $table_name 		= shift ; 
			my $msg 					= q{} ; 
			my $ret 					= 0 ; 

			$self->OpenConnection();
				
			# retrieve the full hierarchy
			my $sql_str = "
				SELECT CONCAT( REPEAT('  ', COUNT(parent.Name) - 1), node.name) AS name
				FROM " . $table_name . " AS node,
				" . $table_name . " AS parent
				WHERE node.LeftRank 
				BETWEEN parent.LeftRank AND parent.RightRank
				GROUP BY node.name
				ORDER BY node.LeftRank"
				;
			$objLogger->LogDebugMsg ( $sql_str ) ; 
			$sth = $dbh->prepare( $sql_str ) ; 
#			$sth = $dbh->prepare( qq (
#				SELECT CONCAT( REPEAT('  ', COUNT(parent.Name) - 1), node.name) AS name
#				FROM Item AS node,
#				Item AS parent
#				WHERE node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
#				GROUP BY node.name
#				ORDER BY node.LeftRank;
#			));

			$sth->execute ( ) or $ret = 1  ;
			$msg = $DBI::errstr if ( $ret == 1 ) ; 
			$objLogger->LogFatalMsg ( $msg ) if $ret == 1 ; 

			#debug			while ( my @row = $sth->fetchrow_array  ) {
			#debug				print (join ('\t' , @row) );
			#debug				print "\n" ; 
			#debug			}
						#eof while

			$self->CloseConnection();

	}
	#eof sub doListTableHierarchy 
	#
	#
	#
	# -----------------------------------------------------------------------------
	# added when item's parent does not have children
	# needs the parent id as parameter
	# -----------------------------------------------------------------------------
	sub doAddItemToParentWithoutChildren {

			my $self 					= shift ; 
			my $table_name 			= shift ; 
			my $parent_item_id 		= shift ; 

			my $ret 						= 0 ; 
			my $msg 						= q{}  ;

			my $pLeftRank				= 0 ; 
			my $pRightRank				= 0 ; 
			my $LeftRank				= q{} ; 
			my $RightRank				= q{} ; 

			my $sql_str = 
				'SELECT LeftRank from ' . $table_name . ' WHERE ' . $table_name . 'Id = ?' 
			; 
			$sth = $dbh->prepare( $sql_str ) ; 
			#$sth = $dbh->prepare( qq (
			#	SELECT LeftRank from Item where ItemId = ?
			#));
			$sth->execute ( $parent_item_id ) or $ret = 1  ;
			$msg = $DBI::errstr if ( $ret == 1 ) ; 
			$objLogger->LogFatalMsg ( $msg ) if $ret == 1 ; 


			my @row = $sth->fetchrow_array ; 
			#debug $objLogger->LogDebugMsg ( "row " . @row);
			( $pLeftRank ) =  @row  ; 
			$objLogger->LogDebugMsg ( "pLeftRank: \"" . $pLeftRank . "\"" );
			$sth->finish;

			$LeftRank = $pLeftRank + 1 ; 
			$RightRank = $pLeftRank + 2 ; 

			$objLogger->LogDebugMsg ( "LeftRank: \"" . $LeftRank  . "\"");
			$objLogger->LogDebugMsg ( "RightRank: \"" . $RightRank . "\"" );

			# shift the right rank to the right 
			$sql_str = '
				UPDATE ' . $table_name . '
				set RightRank = ( RightRank + 2 ) 
				WHERE 1=1 
				AND RightRank > ?'
			;
			$sth = $dbh->prepare( $sql_str ) ; 
			#$sth = $dbh->prepare( qq(
			#	UPDATE Item 
			#	set RightRank = ( RightRank + 2 ) 
			#	WHERE 1=1 
			#	AND RightRank > ? 
			#));

			$sth->execute( $pLeftRank ) or $ret = 1  ;
			$sth->finish;
			$msg = $DBI::errstr if ( $ret == 1 ) ; 
			$objLogger->LogFatalMsg ( $msg ) if $ret == 1 ; 
			
			# shift the left rank to the right 
			$sql_str = '
				UPDATE ' . $table_name . '
				set LeftRank = ( LeftRank + 2 ) 
				WHERE 1=1 
				AND LeftRank > ?'
			;
			$sth = $dbh->prepare( $sql_str ) ; 
			#$sth = $dbh->prepare( qq( 
			#	UPDATE Item 
			#	set LeftRank = ( LeftRank + 2 ) 
			#	WHERE 1=1 
			#	AND LeftRank > ? 
			#));

			$sth->execute( $pLeftRank ) or $ret = 1  ;
			$msg = $DBI::errstr if ( $ret == 1 ) ; 
			$objLogger->LogFatalMsg ( $msg ) if $ret == 1 ; 
			$sth->finish;
		
			$ret = 0 ; $msg = 'subordinate shifting ok' ; 

			return ( $LeftRank , $RightRank ) ; 
	}
	#eof sub doAddItemToParentWithoutChildren


	#
	# -----------------------------------------------------------------------------
	# runs the insert sql by passed data part 
	# by convention is assumed that the first column is unique and update could 
	# be performed on it ... should there be duplicates the update should fail
	# -----------------------------------------------------------------------------
	sub doRunNestedSetSql {

		my $self 			= shift ; 
		my $table_name 	= shift ; 
		my $refHeaders 	= shift ; 
		my $refData 		= shift ; 
      # use Data::Printer ; 
      #p $refData ; 
		my $rowCount		= shift ; 

		my $data_str 		= '' ; 
		my @headers 		= @$refHeaders ; 
		my @data 			= @$refData ; 
		my $ret 				= 1 ; 
		my $msg 				= "undefined error during Upsert to maria db" ; 
		
		# the god's item the initial values
		my $LeftRank		= 1 ; 
		my $RightRank		= 2 ; 
		my $pLeftRank 		= $LeftRank || 1 ; 
		my $pRightRank 	= $RightRank || 2 ; 
		my $CurrentLevel 	= 0 ; 
		my $parent_item_id= 0 ;

		$objLogger->LogDebugMsg ( "\@data : @data" ) if $ModuleDebug == 1 ; 
		$objLogger->LogDebugMsg ( "\@headers: @headers" ) if $ModuleDebug == 1 ; 
		

		
		if ( $rowCount == 1 ) {
			
			$CurrentItemId	 									= 0 ; 
			$parent_item_id 									= 0 ; 
			my $current_level 								= 0 ; 

			# set the paretn item id of the siblings
			$hsLevelsTree->{0}->{'ParentItemId'} 		= 0 ; 

			$hsLevelsTree->{0}->{'CurrentItemId'} 		= 0 ; 


			# se the parent item id of the children
			$hsLevelsTree->{1}->{'ParentItemId'} 		= 0 ; 

			# set the number of children at this point
			$hsIdsTree->{0}->{'ChildrenCount'} 			= 0 ; 
			#delete ?! $hsLevelsTree->{0}->{'Opened'} = 0 ; 
			
			# to which level the current Item belongs to
			$hsIdsTree->{1}->{'Level'} 					= 0 ;
			$PreviousLevel	 = $CurrentLevel = 0 ; 

		}
		#eof if
		
		( $ret , $msg ) = $self->OpenConnection();
		return $ret , $msg unless ( $ret == 0 ) ; 





		my $sql_str = " INSERT INTO $table_name " ; 
		$sql_str	.= '(' ; 
		for (my $i=0; $i<scalar (@headers);$i++ ) {
			$sql_str .= " $headers[$i] " . ' , ' ; 

		} #eof for
		
		for (1..3) { chop ( $sql_str) } ; 
		$sql_str	.= ')' ; 
		
		my $i = 0 ; 
		# get the ParentItemId
		foreach my $cell_value( @data ) {
			unless ( defined ( $cell_value )) {
				$cell_value = '' ; 
			}
		
			#issue-201		
			$cell_value =~ s#&gt;#\>#g ; 
			$cell_value =~ s#&lt;#\<#g ; 



			# set the parent item id 
			if ( $headers[$i] eq "$table_name" . "Id" ) {
				$CurrentItemId = $cell_value ; 
			}
			
			if ( $headers[$i] eq 'Level' ) {
				$CurrentLevel = $cell_value ; 

				$num1++ if ( $cell_value == 2 ) ;		
				$num1=0 if ( $cell_value == 1 ) ;		
				$num2=0 if ( $cell_value == 1 ) ;		
				$num3=0 if ( $cell_value == 1 ) ;		
				$num4=0 if ( $cell_value == 1 ) ;		
				$num5=0 if ( $cell_value == 1 ) ;		


				$num2++ if ( $cell_value == 3 ) ;		
				$num2=0 if ( $cell_value == 2 ) ;		
				$num3=0 if ( $cell_value == 2 ) ;		
				$num4=0 if ( $cell_value == 2 ) ;		
				$num5=0 if ( $cell_value == 2 ) ;		

				$num3++ if ( $cell_value == 4 ) ;		
				$num3=0 if ( $cell_value == 3 ) ;		
				$num4=0 if ( $cell_value == 3 ) ;		
				$num5=0 if ( $cell_value == 3 ) ;		

				$num4++ if ( $cell_value == 5 ) ;		
				$num4=0 if ( $cell_value == 4 ) ;		
				$num5=0 if ( $cell_value == 4 ) ;		

				$num5++ if ( $cell_value == 5 ) ;		
				$num5=0 if ( $cell_value == 4 ) ;		


				$Num	= $num1 . '.' . $num2. '.' . $num3 ;
				$Num	.= '.' . $num4 if ( $num4 > 0 ) ; 
				$Num	.= '.' . $num5 if ( $num5 > 0 ) ; 
				
				$Num = "  " . $Num . "  " ; 
				#$Num = '"=""' . $Num . '"' ; 

			}
			if ( $headers[$i] eq 'SeqId' ) {

				$PrevSeqId = $cell_value ; 
				if ( $rowCount < $PrevSeqId ) {

					$msg = "DANGEROUS RESHOUFFLING for the following table:: $table_name !!!" ; 
					$msg .= "YOU SHOULD HAVE THE XLS SHEET SORTED BY SeqId ALWAYS BEFORE LOAD!!!" ;
					$objLogger->LogFatalMsg ( $msg ) ; 
					exit ( 2 ) ; 
				}
				# the Sequence is rebuilt
				$cell_value=$rowCount ; 
				

			   # WE ARE IN THE COLS LOOP STILL !!!
				# case when adding to parent whithout children 



				if ( $CurrentLevel == $PreviousLevel ) {
					#delete ?! $hsLevelsTree->{$PreviousLevel}->{'Opened'} = 1 ; 
					# which is our parent
					my $parent_id = $hsIdsTree->{$PreviousItemId}->{'ParentItemId'} ; 
					my $sibling_id = $PreviousItemId ; 
					$hsLevelsTree->{"$CurrentLevel"}->{'ParentItemId'} = $parent_id ; 
					( $LeftRank , $RightRank ) = 
							$self->doAddItemToParentWithChildren( $table_name , $sibling_id ) ;
					$hsLevelsTree->{"$CurrentLevel"}->{'LastSiblingItemId'} = $CurrentItemId ; 
					# does the parent have childred
					# yes - always
					 
				}
				#eof if ( $CurrentLevel == $PreviousLevel ) 


				#
				# are we going level down
				if ( $CurrentLevel > $PreviousLevel ) {
					# which is our parent
					my $parent_id = $PreviousItemId ; 
					$hsIdsTree->{$CurrentItemId}->{'ParentItemId'} = $parent_id ; 
					# does the parent have childred ?!
					# if no
					( $LeftRank , $RightRank ) = 
						$self->doAddItemToParentWithoutChildren( $table_name , $parent_id ) ; 
					# if yes
					
#					if ( $rowCount == 2 ) {
#						( $LeftRank , $RightRank ) = 
#								$self->doAddItemToParentWithoutChildren( 0 ) ; 
#					}
					#eof if 2 xls row
					$hsLevelsTree->{"$CurrentLevel"}->{'LastSiblingItemId'} = $CurrentItemId ; 
				}
				#eof if ( $CurrentLevel < $PreviousLevel ) 
				#

				# if we are going level up
				if ( $CurrentLevel < $PreviousLevel ) {
					# which is our parent
					# does the parent have childred
					# yes
					# no
					
					my $parent_id = $hsLevelsTree->{"$CurrentLevel"}->{'ParentItemId'} ;
					# get the point to right shift
					my $sibling_id = $hsLevelsTree->{"$CurrentLevel"}->{'LastSiblingItemId'} ; 
					#debug $objLogger->LogDebugMsg ( 'sibling_id: "' . $parent_id . '"' );
					( $LeftRank , $RightRank ) = 
							$self->doAddItemToParentWithChildren( $table_name , $sibling_id ) ;
					$hsLevelsTree->{"$CurrentLevel"}->{'LastSiblingItemId'} = $CurrentItemId ; 
					# close the previous level
					# does the parent have childred
					# yes - always
					 
					# case when adding to parent WITH children 
					#if ( $rowCount == 3 ) {
					#	( $LeftRank , $RightRank ) = $self->doAddItemToParentWithChildren( 0 ) ;
					#}
					#eof if 3 xls row
					$hsLevelsTree->{"$CurrentLevel"}->{'LastSiblingItemId'} = $CurrentItemId ; 
				}
				#eof if ( $CurrentLevel == $PreviousLevel ) 

				
			}
			#eof if Seqid

			if ( $headers[$i] eq 'LeftRank' ) {
				#the root node starts always with 1 in the beginning of the load
				$cell_value = $LeftRank ; 
			}

			if ( $headers[$i] eq 'RightRank' ) {

				#the root node should stop always with 1 in the beginning of the load
				$cell_value = $RightRank ; 
			}
			if ( $headers[$i] eq 'LogicalOrder' ) {

				$cell_value = $Num ; 
			}
			#$cell_value = q{} ; 
			$cell_value =~ s|\\|\\\\|g ; 
			# replace the ' chars with \'
			$cell_value 		=~ s|\'|\\\'|g ; 
			$data_str .= "'" . "$cell_value" . "' , " ; 
			$i++ ; 
		}
		#eof foreach my $cell_value( @data ) 
		
		# remove the " , " at the end 
		for (1..3) { chop ( $data_str ) } ; 
		
		$sql_str	.=  " VALUES (" . "$data_str" . ')' ; 
		$sql_str	.= ' ON DUPLICATE KEY UPDATE ' ; 
		
		for ( my $i=0; $i<scalar(@headers);$i++ ) {
			$sql_str .= "$headers[$i]" . ' = ' . "'" . "$data[$i]" . "' , " ; 
		} #eof for

		for (1..3) { chop ( $sql_str) } ; 

		$objLogger->LogDebugMsg ( "sql_str : $sql_str " );
		#if $ModuleDebug == 1 ; 

		$sth = $dbh->prepare($sql_str ) ; 
		
		$ret = 0 ; $msg = 'upsert ok' ; 
		$sth->execute() or $ret = 1  ;
		$msg = $DBI::errstr if ( $ret == 1 ) ; 
		$objLogger->LogErrorMsg ( " \n\n\n DBI upsert error on table: $table_name: \n\n" . $msg ) 
			if ( $ret == 1 ) ;  
		exit ( 1 ) if ( $ret == 1 ) ; 
		
		$objLogger->LogDebugMsg ( "ret is $ret " ) if $ModuleDebug == 1 ; 
		$objLogger->LogDebugMsg ( "rowCount is $rowCount " ) if $ModuleDebug == 1 ; 
	
		$self->CloseConnection();
		
		$PreviousItemId = $CurrentItemId ; 
		$PreviousLevel	 = $CurrentLevel ; 

		return ( $ret , $msg ) ; 
	}
	#eof sub doRunNestedSetSql



	#
	# -----------------------------------------------------------------------------
	# runs the insert sql by passed data part 
	# by convention is assumed that the first column is unique and update could 
	# be performed on it ... should there be duplicates the update should fail
	# -----------------------------------------------------------------------------
	sub doRunDeNormalizedUpsertSql {

		my $self 			= shift ; 
		my $table_name 	= shift ; 
		my $hsTWorkSheet  = shift ; 
		
		#debug print '@doRunDeNormalizedUpsertSql:: ' ; 
		#debug sleep 2 ; 
		p ( $hsTWorkSheet )  ; 


		my $ret 				= 1 ; 
		my $msg 				= "undefined error during denormalized Upsert to maria db" ; 

		( $ret , $msg ) = $self->OpenConnection();
		return $ret , $msg unless ( $ret == 0 ) ; 
		
		#todo: 
		my $cell_value_id = 0 ; 
		
		my $sql_str 		= '' ; 
		$sql_str .= " DELETE FROM CellValue WHERE BookItemId='" . "$table_name" . "' ;"  ; 
		$ret = 0 ; $msg = 'upsert ok' ; 
		$sth = $dbh->prepare ( $sql_str ) ; 
		$sth->execute( ) or $ret = 1  ;
		$msg = $DBI::errstr if ( $ret == 1 ) ; 
		$objLogger->LogDebugMsg ( "ret is $ret " ) if $ModuleDebug == 1 ; 
		$objLogger->LogErrorMsg ( " DBI upsert error on table: $table_name: " . $msg ) 
			if ( $ret == 1 ) ;  
		return ( $ret , $msg ) if ( $ret == 1 ) ;  

		foreach my $row_num ( sort ( keys ( %$hsTWorkSheet ) ) ) { 	
			
			$sql_str 		= '' ; 
			my $hsTRow = $hsTWorkSheet->{"$row_num"} ; 
			next unless ( defined ( $hsTRow ) ) ; 
			
			
			# foreach my $column_name ( sort ( keys ( $hsTRow ) ) ) { 	

				my $table_name = $hsTRow->{'BookItemId'} ; 
				

				#my $cell_value_id 				= $hsTRow->{'CellValueId'} ; 
 				#next unless ( length ( $cell_value_id //= '' ))  ; 

				my $WorkSheetName					= $hsTRow->{'BookItemId'} ; 
 				next unless ( length ( $WorkSheetName //= '' ))  ; 

				my $RowId 							= $hsTRow->{'RowId'} ; 
 				next unless ( length ( $RowId //= '' ))  ; 

				my $ColumnName 					= $hsTRow->{'ColumnName'} ; 
 				next unless ( length ( $ColumnName //= '' ))  ; 

				my $CellValue						= $hsTRow->{'CellValue'} ; 
 				next unless ( length ( $CellValue //= '' ))  ; 

				$CellValue =~ s|\\|\\\\|g ; 
				# replace the ' chars with \'
				$CellValue 		=~ s|\'|\\\'|g ; 

#				CellValue.CellValueId
#				CellValue.TableName
#				CellValue.RowId
#				CellValue.ColumnName
#				CellValue.CellValue
#				CellValue.UpdateTime

				
				$sql_str .= " INSERT INTO CellValue " ; 
				$sql_str	.= '( BookItemId , RowId , ColumnName , CellValue ) ' ; 
				$sql_str	.= ' VALUES ( ' ; 
				$sql_str	.= "'" . "$WorkSheetName" . "' , " ;  
				$sql_str	.= "'" . "$RowId" . "' , " ;  
				$sql_str	.= "'" . "$ColumnName" . "' , " ; 
				$sql_str	.= "'" . "$CellValue" . "' " ; 
				$sql_str	.= " ) \n " ; 

#				$sql_str	.= ' ON DUPLICATE KEY UPDATE ' ; 
#				$sql_str	.= ' BookItemId = ' . "'" . "$WorkSheetName" . "' , " ; 
#				$sql_str	.= ' RowId = ' . "'" . "$RowId" . "' , " ; 
#				$sql_str	.= ' ColumnName= ' . "'" . "$ColumnName" . "' , " ; 
#				$sql_str	.= ' CellValue = ' . "'" . "$CellValue" . "' , " ; 
#			
#				
#				for (1..3) { chop ( $sql_str) } ; 
#				$sql_str	.= ' ; ' ; 


				$objLogger->LogDebugMsg ( 'sql_str:: doRunDeNormalizedUpsertSql' . "$sql_str" ) ; 
				#debug sleep 2 ; 

				$sth = $dbh->prepare ( $sql_str ) ; 
				
				$ret = 0 ; $msg = 'upsert ok' ; 
				$sth->execute( ) or $ret = 1  ;
				$msg = $DBI::errstr if ( $ret == 1 ) ; 
				$objLogger->LogDebugMsg ( "ret is $ret " ) if $ModuleDebug == 1 ; 
				$objLogger->LogErrorMsg ( " DBI upsert error on table: $table_name: " . $msg ) 
					if ( $ret == 1 ) ;  
				return ( $ret , $msg ) if ( $ret == 1 ) ;  
				$cell_value_id = $cell_value_id + 1 ; 

			# }
			#eof foreach col

		}
		#eof foreach row
		#
	

		$self->CloseConnection();

		$msg .= " for table : $table_name" ; 
		
		return ( $ret , $msg ) ; 
	}
	#eof sub doRunDeNormalizedUpsertSql



	#
	# -----------------------------------------------------------------------------
	# runs the insert sql by passed data part 
	# by convention is assumed that the first column is unique and update could 
	# be performed on it ... should there be duplicates the update should fail
	# -----------------------------------------------------------------------------
	sub doRunUpsertSql {

		my $self 			= shift ; 
		my $table_name 	= shift ; 
		my $refHeaders 	= shift ; 
		my $refData 		= shift ; 
		my $data_str 		= '' ; 
		my @headers 		= @$refHeaders ; 
		my @data 			= @$refData ; 
		my $ret 				= 1 ; 
		my $msg 				= "undefined error during Upsert to maria db" ; 

		( $ret , $msg ) = $self->OpenConnection();
		return $ret , $msg unless ( $ret == 0 ) ; 

		$objLogger->LogDebugMsg ( "\@data : @data" ) if $ModuleDebug == 1 ; 
		$objLogger->LogDebugMsg ( "\@headers: @headers" ) if $ModuleDebug == 1 ; 

		my $sql_str = " INSERT INTO $table_name " ; 
		$sql_str	.= '(' ; 
		for (my $i=0; $i<scalar (@headers);$i++ ) {
			$sql_str .= " $headers[$i] " . ' , ' ; 

		} #eof for
		
		for (1..3) { chop ( $sql_str) } ; 
		$sql_str	.= ')' ; 
		
		foreach my $cell_value( @data ) {
			unless ( defined ( $cell_value )) {
				$cell_value = '' ; 
			}
			#$cell_value = q{} ; 
			$cell_value =~ s|\\|\\\\|g ; 
			# replace the ' chars with \'
			$cell_value 		=~ s|\'|\\\'|g ; 
			$data_str .= "'" . "$cell_value" . "' , " ; 
		}
		#eof foreach
		
		# remove the " , " at the end 
		for (1..3) { chop ( $data_str ) } ; 
		
		$sql_str	.=  " VALUES (" . "$data_str" . ')' ; 
					$sql_str	.= ' ON DUPLICATE KEY UPDATE ' ; 
		
		for ( my $i=0; $i<scalar(@headers);$i++ ) {
			$sql_str .= "$headers[$i]" . ' = ' . "'" . "$data[$i]" . "' , " ; 
		} #eof for

		for (1..3) { chop ( $sql_str) } ; 

		$objLogger->LogDebugMsg ( "sql_str : $sql_str " ) if $ModuleDebug == 1 ; 

		$sth = $dbh->prepare($sql_str ) ; 
		
		$ret = 0 ; $msg = 'upsert ok' ; 
		$sth->execute( ) or $ret = 1  ;
		$msg = $DBI::errstr if ( $ret == 1 ) ; 
		$objLogger->LogErrorMsg ( " DBI upsert error on table: $table_name: " . $msg ) 
			if ( $ret == 1 ) ;  
		
		$objLogger->LogDebugMsg ( "ret is $ret " ) if $ModuleDebug == 1 ; 
		$self->CloseConnection();

		$msg .= " for table : $table_name" ; 
		
		return ( $ret , $msg ) ; 
	}
	#eof sub doRunUpsertSql



	#
	# -----------------------------------------------------------------------------
	# just truncates a table
	# -----------------------------------------------------------------------------
	sub doRunTruncateTableSql {

		my $self 			= shift ; 
		my $table_name 	= shift ; 
		my $ret 				= 1 ; 
		my $msg 				= "undefined error during Upsert to maria db" ; 

		( $ret , $msg ) = $self->OpenConnection();
		return $ret , $msg unless ( $ret == 0 ) ; 


		my $sql_str = "TRUNCATE TABLE $table_name " ; 
		$objLogger->LogDebugMsg ( "RUNNING TRUNCATE sql: $sql_str " ) 
			if $ModuleDebug == 1 ; 

		$sth = $dbh->prepare($sql_str ) ; 
		
		$ret = 0 ; $msg = '=== OK === TRUNCATE TABLE ' . $table_name ; 
		$sth->execute( ) or $ret = 1  ;
		$msg = $DBI::errstr if ( $ret == 1 ) ; 
		$objLogger->LogErrorMsg ( " DBI TRUNCATE TABLE error : " . $msg ) 
			if ( $ret == 1 ) ;  
		
		$objLogger->LogDebugMsg ( "ret is $ret " ) if $ModuleDebug == 1 ; 
		$self->CloseConnection();
		
		return ( $ret , $msg ) ; 
	}
	#eof sub doRunUpsertSql


	#
	# -----------------------------------------------------------------------------
	# walk trough the Excel and build the data part of the insert sql
	# -----------------------------------------------------------------------------
	sub doParseExcelSheet {

		my $self 					= shift ; 
		my $sheet_to_parse 		= shift ; 
		my $table_to_upsert 		= shift ; 
		my $refHashItem			= shift ; 


		my $ret 	 = 1 ; 
		my $msg 	 = "undefined error during xls parsing" ; 

		# not sure if it could work without the next line
		# for utf8 strings - slavic , japanese etc. 
		my $objStrFormatConverter = Text::Iconv -> new ("utf-8", "utf-8");

		if ( $ModuleDebug == 1 ) {
		 	$msg = "Using the following Project : " ;  
			$objLogger->LogDebugMsg ( $msg ) ; 
			$msg = "$Project" ; 
			$objLogger->LogDebugMsg ( $msg ) ; 
		 	$msg = "Using the following ProjectDir : " ;  
			$objLogger->LogDebugMsg ( $msg ) ; 
			$msg = "$ProjectDir" ; 
			$objLogger->LogDebugMsg ( $msg ) ; 
		 	$msg = "Using the following InputExcelFile : " ;  
			$objLogger->LogDebugMsg ( $msg ) ; 
		 	$msg = "$InputExcelFile" ; 
			$objLogger->LogDebugMsg ( $msg ) ; 
			#sleep 2 ; 
		} 

		# http://search.cpan.org/~dmow/Spreadsheet-XLSX-0.13-withoutworldwriteables/lib/Spreadsheet/XLSX.pm
		my $objExcelParser = Spreadsheet::XLSX -> new ("$InputExcelFile", $objStrFormatConverter);


		# iterate the sheets
		foreach my $objSheet (@{$objExcelParser-> {Worksheet}}) {

			$objLogger->LogDebugMsg("xls sheet: " . $objSheet->{'Name'})
				if $ModuleDebug == 1 ; 
         $objLogger->LogDebugMsg("sheet to parse : " . "$sheet_to_parse" ) 
				if $ModuleDebug == 1 ; 

			next unless ( lc ( $objSheet->{'Name'} ) eq lc ( "$sheet_to_parse" )  ) ; 

			# if some sheet is causing troubles start super debug on it only
			#$ModuleDebug = 1 if ( lc ( $Table ) eq 'itemcontroller' ) ; 
			
			$self->doRunTruncateTableSql($table_to_upsert ) 
				if ( defined ( $refHashItem->{'doTruncTable'} ) && $refHashItem->{'doTruncTable'} == 1 ) ; 

			$msg = "START == LOADING : Sheet: " . $objSheet->{'Name'} ; 
         $objLogger->LogInfoMsg("$msg");

			# if you want to troubleshoot only specific sheet set its name here ...
			#debug sleep 5 
			#debug if ( lc ( $objSheet->{'Name'} ) eq lc ( 'Installation' )) ; 
			
			my $rowCount = 0 ; 
			# iterate the rows 
			my @headerData 					= ();
			foreach my $row ($objSheet -> {'MinRow'} .. $objSheet -> {'MaxRow'}) {
				my @rowData 					= (); 
				$objSheet -> {'MaxCol'} ||= $objSheet -> {'MinCol'};

				# iterate the coloumns
				foreach my $col ($objSheet -> {'MinCol'} ..  $objSheet -> {'MaxCol'}) {
					my $cell = $objSheet -> {'Cells'} [$row] [$col];
					if ($cell) {

						push ( @rowData , $cell->value() ) 		if $rowCount != 0 ; 
						#old -> gives formatting errors use $cell->{'Val'} instead ?!
						#push ( @headerData , $cell->value() ) 	if $rowCount == 0 ; 
						my $cell_value	= sprintf("%s", $cell -> {'Val'});
						push ( @headerData , $cell_value ) 	if $rowCount == 0 ; 
						
						# issue-118
						#printf("( %s , %s ) => %s\n", $row, $col, $cell -> {'Val'});
						# the unformatted value
						#my $cellValue = $cell->{'Val'}  ; 
						my $cell_type = $cell->type();
						$objLogger->LogDebugMsg ( "cell_type: " . "$cell_type" )
							if ( $ModuleDebug == 1 ) ; 
							#print "sfw/perl/isg_pub/Control/Utils/ETL/ExcelToMariaDbLoader.pm \n" ; 
							#print "cell_type: " . $cell_type . "\n" ; 
							#print "cell->value: " . $cell->value() . "\n" ; 
							#print "call_value: " . $cell_value . "\n" ; 
						$objLogger->LogDebugMsg ( "\$cell->value : " . $cell->value() )  
							if ( $ModuleDebug == 1 ) ; 
						
						#debug $objLogger->LogDebugMsg ( "\$cell->{'Val'}: " . $cell->{'Val'} );
						#debug sleep 1 ;
						
					}  #eof if the cell is defined
					else {
						push ( @rowData , undef ) 		if $rowCount != 0 ; 
						if ( $rowCount == 0 ) { return 1 , "undefined headers in xls !!!" ; } 
					}
				} 
				#eof foreach col
			
				#perform the upsert if not currently at header row
				if ( $rowCount != 0 ) {

					# by convention the name of the xls sheet is the same as the table name

					( $ret , $msg ) = $self->doRunUpsertSql ( $table_to_upsert , \@headerData , \@rowData)  
						if ( $LoadModel eq 'upsert'  ) ; 

					( $ret , $msg ) = 
							$self->doRunNestedSetSql ( $table_to_upsert , \@headerData , \@rowData , $rowCount )
						if ( $LoadModel eq 'nested-set' ) ; 
					
					( $ret , $msg ) = 
							$self->doStoreTableDataToRam( $table_to_upsert , \@headerData , \@rowData , $rowCount )
						if ( $LoadModel eq 'inline-table' ) ; 
				

					if ( $LoadModel eq 'nested-set' and $ModuleDebug == 2 ) {
						$self->doListTable($table_to_upsert)  ; 
						$self->doListTableHierarchy($table_to_upsert)   ;
					}
					#debug sleep 2 ; 

					unless ( $ret == 0 ) {
						my $fatal_msg	 = '' ; 
						$fatal_msg 	 	.= "$msg" ; 
						$fatal_msg	.= "FAILED TO LOAD THE " . $sheet_to_parse. "Excel sheet" ; 
						$objLogger->LogFatalMsg ( "$fatal_msg" ) 	unless ( $ret == 0 ) ; 
						$fatal_msg	= "FAILED TO LOAD THE " . $table_to_upsert  . " table" ; 
						$objLogger->LogFatalMsg ( "$fatal_msg" ) 	unless ( $ret == 0 ) ; 
						die "$fatal_msg" unless ( $ret == 0 ) ; 
					}
				}

				$rowCount++ ; 
			}
			#eof foreach row

			my $msg = "STOP  == LOADING : Sheet: " . $objSheet->{'Name'};
         $objLogger->LogInfoMsg("$msg \n" ) ; 

			doLoadInLineTable()  
			if ( $LoadModel eq 'inline-table' ) ; 
		} 
		#eof foreach $objSheet

		#debug $objLogger->LogInfoMsg (  " == STOP  == EXCEL PARSING" ) ; 
		return ( 0 , "== OK == parsing of the sheet to parse: $sheet_to_parse" ) ; 
	} #eof sub doParseExcelSheet


	#
	# -----------------------------------------------------------------------------
	# trim white space characters before and after the passed string
	# -----------------------------------------------------------------------------
	sub trim    {
			my $self = shift ; 
		 $_[0]=~s/^\s+//;
		 $_[0]=~s/\s+$//;
		 return $_[0];
	} #eof sub trim 


	# ===============================================================
	# START OO

	# -----------------------------------------------------------------------------
	# the constructor 
	# source:http://www.netalive.org/tinkering/serious-perl/#oop_constructors
	# -----------------------------------------------------------------------------
	sub new {
	  
		my $class 				= shift ;    # Class name is in the first parameter
		$ProjectDir 			= shift ; 

		# debug print "ProjectDir is $ProjectDir " . "\n" ; 
		# debug sleep 10 ; 

		$ModuleFileConfig 	= shift @_ if ( @_ ) ; 
		$confHolder 			= ${ shift @_ } if ( @_ ) ; 
		$lang_code				= shift if ( @_ ) || 'en' ; 
		$LoadTables 				= shift if ( @_ ) ; 	
		$LoadModel				= shift if ( @_ ) ; 
		$CmdArgLoadXlsFile	= shift if ( @_ ) ; 
		#debug print "\$ModuleFileConfig : $ModuleFileConfig" ; sleep 3 ; 
		my $self = {}; # Anonymous hash reference holds instance attributes

		bless($self, $class);     # Say: $self is a $class
		$self->doInitialize() ; 
		return $self;
	} 
	#eof const 


	# -----------------------------------------------------------------------------
	# perldoc autoloader 
	# -----------------------------------------------------------------------------
	sub AUTOLOAD {

		my $self = shift ; 
		no strict 'refs'; 
		 my $name = our $AUTOLOAD;
		 *$AUTOLOAD = sub { 
		my $msg = "BOOM! BOOM! BOOM! \n RunTime Error !!!\nUndefined Function $name(@_)\n" ;
		print "$self , $msg";
		 };
		 goto &$AUTOLOAD;    # Restart the new routine.
	}  #eof sub AUTOLOAD


	# -----------------------------------------------------------------------------
	# return a field's value
	# -----------------------------------------------------------------------------
		sub get  {
		
			my $self = shift;
			my $name = shift;
			return $self->{$name};
		} #eof sub get 


	# -----------------------------------------------------------------------------
	# set a field's value 
	# -----------------------------------------------------------------------------
		sub set  {
		
			my $self = shift;
			my $name = shift;
			my $value = shift;
			$self->{$name}=$value;
		} #eof sub set 


	# -----------------------------------------------------------------------------
	# return the fields of this obj instance  
	# -----------------------------------------------------------------------------
		sub dumpFields    {
			my $self = shift ; 
			my $strFields = () ; 
			foreach my $key (keys %$self)    {
				$strFields .= "$key = $self->{$key}\n";
			}
			
			return $strFields ; 
		} #eof sub dumpFields 


	# -----------------------------------------------------------------------------
	# wrap any logic here on clean up for this class 
	# -----------------------------------------------------------------------------
	sub  RunBeforeExit {

			my $self = shift ; 
			#debug print "%$self RunBeforeExit ! \n";
	}


	# -----------------------------------------------------------------------------
	# called automatically by perl's garbage collector use to know when 
	# -----------------------------------------------------------------------------
	sub DESTROY {
		my $self = shift;
		#debug print "the DESTRUCTOR is called  \n" ; 
		$self->RunBeforeExit() ; 
		return ; 
	} #eof sub DESTROY



	#
	# -----------------------------------------------------------------------------
	# doInitialize this object with the minimum data it will need to operate 
	# -----------------------------------------------------------------------------
	sub doInitialize {

		my $self = shift ; 
		my $msg 			= q{} ; 

		# get the module configuration holder hash from the base class
		#debug print "sfw/perl/isg_pub/Control/Utils/ETL/ExcelToMariaDbLoader.pm sub doInitialize \n" ; 
		#debug p($confHolder); sleep 6 ; 
		$self->SUPER::doInitialize( $ModuleFileConfig, \$confHolder );
		$confHolderOfObj 	= $self->SUPER::get("confHolderOfObj");
		print "from sfw/perl/isg_pub/Control/Utils/ETL/ExcelToMariaDbLoader.pm 1469 \n" ; 
		p($confHolderOfObj);
		#sleep 2 ; 

		$Project 			= $confHolderOfObj->{'Project'}	 ; 

		#debug print "\$Project is $Project \n\n" ;
		# if not project is specified run myself
		unless ( length ( $Project //= '' )) { $Project = 'isg-pub' ; } ; 


		$objFileHandler						= 
			"isg_pub::Control::Utils::FileHandler"->new ( \$confHolder ) ; 
		$objLogger						= 
			"isg_pub::Control::Utils::Logger"->new ( \$confHolder ) ; 


		if ( $ModuleDebug == 1 ) {
			foreach my $key ( keys %$confHolderOfObj ) {
					$objLogger->LogDebugMsg(
					"VarName : $key --- VarValue : $confHolderOfObj->{$key}" ) ; 
			} #eof foreach
		}

		#build the local variables from the module configuration file

		$mysql_user						= $confHolderOfObj->{ 'mysql_user' } ; 
		$mysql_user_pw					= $confHolderOfObj->{ 'mysql_user_pw' } ; 
		$mysql_host						= $confHolderOfObj->{ 'mysql_host' } ; 
		$mysql_port						= $confHolderOfObj->{ 'mysql_port' } ; 

		$project_db						= $confHolderOfObj->{ 'project_db' } ; 

		$ProductVersionDir 			= $confHolder->{ 'ProductVersionDir' } ; 
		$HostName						= $confHolder->{ 'HostName' } ; 
		$Project							= $confHolder->{ 'Project'} ; 
		$do_use_files_conf			= $confHolderOfObj->{ 'do_use_files_conf'} ; 
		$ModuleDebug					= $confHolderOfObj->{ 'ModuleDebug'} 
				unless $ModuleDebug ; 
		$do_use_threads				= $confHolderOfObj->{ 'do_use_threads'} ; 

		# the default is the to the db 
		unless ( length ( $do_use_files_conf //= '' )) { $do_use_files_conf = 0 ; } ; 
		unless ( length ( $ModuleDebug //= '' )) { $ModuleDebug = 0 ; } ; 
		unless ( length ( $do_use_threads //= '' )) { $do_use_threads = 1 ; } ; 
		
		# now set the vals for the module
		$objLogger->LogDebugMsg ( "\$lang_code: $lang_code" ) ;
		


		# check are we running external project
		unless ( length ( $ProjectDir //= '' )) {
			$ProjectDir = $ProductVersionDir ; 
		}
		else {
			# we need to copy the formatting by css	
		}

		#$InputExcelFile						= $confHolderOfObj->{'InputExcelFile'}	 ; 
			
		$InputExcelFile	
				= "$ProjectDir/docs/xls/$Project/$lang_code/$Project" . '-' . "$lang_code.xlsx" ; 
		
		# override with the passed from the cmd arg 
		if ( $CmdArgLoadXlsFile ) {
			$InputExcelFile = $CmdArgLoadXlsFile ; 			
		}

		
		if ( $ModuleDebug == 1 ) {
		 	$msg = "Using the following Project : " ;  
			$objLogger->LogDebugMsg ( $msg ) ; 
			$msg = "$Project" ; 
			$objLogger->LogDebugMsg ( $msg ) ; 
		 	$msg = "Using the following ProjectDir : " ;  
			$objLogger->LogDebugMsg ( $msg ) ; 
			$msg = "$ProjectDir" ; 
			$objLogger->LogDebugMsg ( $msg ) ; 
		 	$msg = "Using the following InputExcelFile : " ;  
			$objLogger->LogDebugMsg ( $msg ) ; 
		 	$msg = "$InputExcelFile" ; 
			$objLogger->LogDebugMsg ( $msg ) ; 
			# debug  sleep 10 ; 
		} 

		$TokenDelimiterAsciiNumber = chr ( 44 ) ;
		if ( $confHolderOfObj->{'TokenDelimiterAsciiNumber'} ) {
			$TokenDelimiterAsciiNumber =  chr(  $confHolderOfObj->{'TokenDelimiterAsciiNumber'}) 
		}
		
		$RowEnd 	=	"\n" ;


		# dump some info if debugging 
		if ( $ModuleDebug == 1 ) { 

			$objLogger->LogDebugMsg( "START dumping the confHolder after doInitialize" )  ; 
			foreach my $key ( keys %$confHolder) {
				$objLogger->LogDebugMsg(
				"VarName : $key --- VarValue : $confHolder->{$key}" ) ; 
			} #eof foreach

			$objLogger->LogDebugMsg( "STOP  dumping the confHolder after doInitialize" ) ; 
			#debug sleep 2 ; 

		} #eof if debugging 
	}
	#eof sub doInitialize


	#
	# ------------------------------------------------------
	# convert an excel file into a hash ref of hash ref of hash refs
	# ------------------------------------------------------
	sub doXlsToHashOfHashes {

		my $msg = "ExcelToMariaDbLoader::doParseXlsSheet:: 
							opening the \$InputExcelFile:: $InputExcelFile" ; 
		$objLogger->LogDebugMsg( $msg ) ; 

		my $objParser= Spreadsheet::ParseExcel->new();
		my $Workbook = $objParser->Parse( $InputExcelFile );
		my $hsWorkBook = {} ; 

		# check if we are using Excel2007 open xml format 
		 if ( !defined $Workbook ) {
				  
			#works 
			#my $converter = () ; 
			#"utf-8", "windows-1251"
			my $converter = Text::Iconv -> new ( "utf-8" , "utf-8" );  
			$Workbook = Spreadsheet::XLSX -> new ($InputExcelFile, $converter);

			  # exit the whole application if there is no excel defined 
				if ( !defined $Workbook ) {
					my $msgError = "cannot parse \$InputExcelFile $InputExcelFile $! $objParser->error()" ; 
					print STDERR "$msgError" ; 
					$objLogger->LogErrorMsg (  "$msgError" ) ; 
					die $objParser->error(), ".\n\n\n\n"; 
				} #eof if 
				  
			 } #eof if not $Workbook
		
      foreach my $worksheet ( @{ $Workbook->{ Worksheet } } ) {
			my $hsWorkSheet = () ; 
         my $FileName = ();
         $objLogger->LogDebugMsg( "foreach my worksheet " )
           if ( $ModuleDebug == 1 );
         my $WorkSheetName = $worksheet->{ 'Name' };
			my $RowMin = $worksheet->{'MinRow'};
         my $RowMax = $worksheet->{'MaxRow'};
			my $hsHeaders = {} ; 
			
			# todo: remove


         #    my ( $RowMin, $RowMax) = $worksheet->row_range();
         #    my ( $MinCol, $MaxCold ) = $worksheet->col_range();
			
			my $row_num = 0 ; 
         for my $row ( ( $RowMin ) .. $RowMax ) {

				my $hsRow  = {} ; 
            my $MinCol = $worksheet->{'MinCol'};
            my $MaxCol = $worksheet->{'MaxCol'};
				#debug print "MinCol::$MinCol , MaxCol::$MaxCol \n" ; 
           	my $col_num = 0 ;  

				#print "row_num:: $row_num \n" ; 	
				for my $col ( ( $MinCol ) .. $MaxCol ) {

					#debug print "col_num:: $col_num \n" ; 	
               my $cell  = $worksheet->{'Cells'}[ $row ][ $col ];
               my $token = '';

               # to represent NULL in the sql
               unless ( $cell ) {
               	$token = 'NULL';
               }
               else {
						# this one seems to return the value ONLY if it is formateed properly with Ctrl + 1
               	# $token = $cell->Value(); 
						# this one seems to return the value as it has been typed into ...
						$token = $cell->unformatted() ; 
						# debug print "token is :: " . $token . "\n" ; 
               }

					if ( $row_num == 0 ) {
						#populate the header row
						$hsHeaders->{"$col_num"} = $token; 
						$hsRow = $hsHeaders ; 
					}
					else {
						#populate the data rows 
						my $ColumnName	= $hsHeaders->{"$col_num"} ; 	
				 		$hsRow->{ "$ColumnName" } = $token ; 			
					}
					$col_num++ ; 
				}
				#eof for col
				$hsWorkSheet->{ "$row_num" } = $hsRow ; 
				$row_num++ ; 
			}
			#eof foreach row
			#doPrintInsertTable ( $WorkSheetName , $hsWorkSheet ) ; 
			$hsWorkBook->{"$WorkSheetName" } = $hsWorkSheet ; 
			# p($hsWorkSheet );
		} 

		#eof foreach my worksheet
		# Action !!! for each hsWorkSheet

		return $hsWorkBook ; 	
	}
	#eof sub doXlsToHashOfHashes

	#
	# ------------------------------------------------------
	# prints a insert table sql script A
	# params: the worksheet name , the hash ref of hash refs 
	# containing the data of an excel sheet, which does store 
	# the headers in the row num 0 and the data > 0
	# ------------------------------------------------------
	sub doDeNormalizeHsWorkSheetToHsCellValue {
		
		my $self 			= shift ; 
		my $WorkSheetName = shift ;
		#todo: remove
		my $hsWorkSheet 	= shift ; 
		# p( $hsWorkSheet ) ; 
		# print "1654 END \n \n" ; 
		# sleep 100 ; 

		#todo: remove

		my $hsHeaders = $hsWorkSheet->{'0'} ; 	

		# the hash ref modelling the DeNormalized data for the worksheet
		my $hsTWorkSheet  = {} ; 
		my $cell_value_id = 0 ;
		my $str_file = q{} ; 

		#debug p($hsHeaders ) ; sleep 10 ; 
		foreach my $row_num ( sort(keys(%$hsWorkSheet))) {
			
			# the data starts from row 1	
			#next if $row_num == 0 ; 
	
			my $hsRow = $hsWorkSheet->{"$row_num"} ; 
			
			foreach my $col_num ( sort ( keys( %$hsHeaders ) ) ) {
				my $ColumnName = $hsHeaders->{"$col_num"} ; 
				$str_file .= '"' . $ColumnName . '" , ' ; 
				#debug print 'CoumnName:: ' . $ColumnName . "\n" ; 
			}

			foreach my $col_num ( sort ( keys( %$hsHeaders) ) ) {
				my $hsTRow = {} ; 
				#debug print '@doPrintInsertTable col_num:: ' . "$col_num \n" ; 
				my $ColumnName	= $hsHeaders->{"$col_num"} ; 
				my $TokenValue = $hsRow->{"$ColumnName"} ; 

				if ( $row_num == 0 ) {
					$TokenValue = $ColumnName ; 
					$ColumnName	= $col_num ; 
				}
				#eof if row_id == 0


				$TokenValue =~ s/\'/\'\'/g ; 
				$hsTRow->{'CellValueId'} 		= $cell_value_id ; 
				$hsTRow->{'BookItemId'} 		= $WorkSheetName ; 
				$hsTRow->{'RowId'} 				= $row_num; 
				$hsTRow->{'ColumnName'} 		= $ColumnName ; 
				$hsTRow->{'CellValue'} 			= $TokenValue ; 

				#	  `CellValueId` 		bigint 			NOT NULL UNIQUE	/* a technical id - OBLIGATORY */
				#	, `ItemName` 			varchar(200)	NOT NULL -- the item id where the document residues 
				#	, `InDocId` 			bigint 			NOT NULL -- the doc id where the document residues
				#	, `TableId` 			bigint 			NOT NULL -- the table id - one doc might have many inline tables
				#	, `BookItemId` 		varchar(200)	NOT NULL -- the name of the table as seen in the doc
				#	, `RowId` 				bigint 			NOT NULL -- the row num starting at 0
				#	, `ColumnName` 		varchar(200)	NOT NULL -- the name of the column / header 
				#	, `CellId` 				bigint 			NOT NULL -- the cell number starting at 0
				#	, `CellValue` 			varchar(4000)	NOT NULL -- the actual value of the cell 
				#	, `UpdateTime`			datetime			NOT NULL /* the update time for this record - OBLIGATORY */
				
				# store the DeNormalized row to the DeNormalized Sheet hash ref of hash refs
				$hsTWorkSheet->{"$cell_value_id"} = $hsTRow ; 

				$cell_value_id = $cell_value_id + 1 ; 
			}
			#eof foreach col_num
			$row_num = $row_num + 1 ; 
		}
		#eof foreach row_num

		# my $msg = ' printing the produced de-normalized sheet hash' ; 
		# $objLogger->LogDebugMsg ( $msg ) ; 
		# sleep 2 ; 
		p($hsTWorkSheet);
		#print "1718 END \n \n" ; # debug sleep 100 ; 


		return $hsTWorkSheet ; 
	}
	#eof sub doDeNormalizeHsWorkSheetToHsCellValue
	
	
	#
	# ------------------------------------------------------
	# prints a insert table sql script A
	# params: the worksheet name , the hash ref of hash refs 
	# containing the data of an excel sheet, which does store 
	# the headers in the row num 0 and the data > 0
	# ------------------------------------------------------
	sub doPrintInsertTable {

		my $WorkSheetName = shift ;
		my $hsWorkSheet 	= shift ; 

		my $str_file = q{} ; 
		my $hsHeaders = $hsWorkSheet->{'0'} ; 	

		#debug p($hsHeaders ) ; sleep 10 ; 
		foreach my $row_num ( sort(keys(%$hsWorkSheet))) {
			
			# the data starts from row 1	
			next if $row_num == 0 ; 
	
			my $hsRow = $hsWorkSheet->{"$row_num"} ; 
			
			$str_file .= 'INSERT INTO "' . $WorkSheetName . '" ( ' ; 		
			foreach my $col_num ( sort ( keys( %$hsHeaders ) ) ) {
				my $ColumnName = $hsHeaders->{"$col_num"} ; 
				$str_file .= '"' . $ColumnName . '" , ' ; 
				#debug print 'CoumnName:: ' . $ColumnName . "\n" ; 
			}
			for my $i (1..3) { chop $str_file ; } ; 	
			$str_file .= ' ) VALUES ( ' . "\n" ; 

			foreach my $col_num ( sort ( keys( %$hsHeaders) ) ) {
				#debug print '@doPrintInsertTable col_num:: ' . "$col_num \n" ; 
				my $ColumnName	= $hsHeaders->{"$col_num"} ; 
				my $TokenValue = $hsRow->{"$ColumnName"} ; 
				$TokenValue =~ s/\'/\'\'/g ; 
				$str_file .= '\'' . $TokenValue . '\' , ' ; 
			}
			for my $i (1..3) { chop $str_file ; } ; 	
			$str_file .= ' ) ;' . "\n" ; 

		}
		#eof foreach	

		#$objFileHandler->PrintToFile("$OutDir/" . 'insert-' . "$WorkSheetName" . '-table.sql' , $str_file );

	}
	#eof sub doPrintInsertTable	

	# STOP OO
	# =============================================================================


1 ; 

__END__



=head1 NAME

ExcelToMariaDbLoader - 

=head1 DESCRIPTION

This module scans recursively a predifined directory uses an excel file for input
takes the sheet name as a table name and generates sql inserts using the first column 
it finds the file to write the sql inserts by search for WorkSheetName.TableInsert.sql pattern 
in a predifned SqlInstallDir, where the sql install files are situated , if a TableName.TableInsert does not exist it creates it in a preconfigured  director. After each sql insert file is generated it is ran against a predified database and the output stored into a log file

=head1 README

for how-to use this script check the ReadMe.txt 

=head1 PREREQUISITES

Spreadsheet::XLSX
FileHandler
Logger

=head1 PREREQUISITES

=pod OSNAMES


=pod SCRIPT CATEGORIES

configurations 
=pod VersionHistory

VersionHistory: 
1.1.0 -- 2015-01-27 22:41:12 -- ysg -- nested-set model
1.0.1 -- 2014-12-09 20:13:59 -- ysg -- fixed bug with undef cell_value
1.0.0 -- 2014-06-21 15:53:20 -- ysg -- upsert ok
0.1.0 -- 2014-06-19 22:11:54 -- ysg -- insert ok



=cut
