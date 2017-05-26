package DocPub::Model::MariaDbHandler ; 

   use strict ; use warnings ; use utf8 ; 

   require Exporter; 
   use AutoLoader ; 
	use Encode qw( encode_utf8 is_utf8 );
   use POSIX qw(strftime);
   use DBI ; 
	use DBD::mysql;
	use Data::Printer ; 
	use Carp ; 


   our $module_trace	                                    = 1 ; 
   our $IsUnitTest                                    	= 0 ; 
	our $app_config 													= q{} ; 
	our $objLogger 													= q{} ; 
	our $objController 												= {} ; 

	our $db      														= q{} ; 
	our $db_host 														= q{} ; 
	our $db_port 														= q{} ;
	our $db_user 														= q{} ; 
	our $db_user_pw	 												= q{} ; 
	our $web_host 														= q{} ; 

	#
   # ------------------------------------------------------
   # the backend func for saving the content of the paragrapth
	# after the edit from the view post
	# inspired by : http://mikehillyer.com/articles/managing-hierarchical-data-in-mysql/
   # ------------------------------------------------------
	sub do_reshuffle {

		my $self 					= shift;
		my $db 						= shift ; 
		my $table 					= shift ; 
		my $draggable_id			= shift ; 
		my $droppable_id 			= shift ; 

		my $ret						= 0 ; # assume error 
		

		my $sql_get_ids = 'SELECT ' . $table . 'Id , Level , SeqId from ' . $db . '.' . $table ; 
		my $meta_id					= $table . 'Id' ; 

		#debug print "sql:: " . $sql . "\n\n" ; 
		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw 
		, { 
			  'RaiseError' => 1 
			, 'PrintError' => 1 
		  }
		);

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;


      my $sth = $dbh->prepare( $sql_get_ids );
		$sth->execute() 
				or $objLogger->error ( "$DBI::errstr" ) ; 

		my $ref_ids = $sth->fetchall_hashref( $meta_id )  ; 
		#debug p($ref_ids ) ; 
		my $ref_reshuffled_ids = {} ; 

		my $parent_id	= 0 ; 
		my $prev_key = 0 ; 
		my $ref_levels = {} ; 
		my $level_up	= 0 ; 
		$ref_levels->{ 0 } ->{ 'ParentItemId' } = 1 ; 
		$ref_levels->{ -1 } ->{ 'ParentItemId' } = 1 ; 
		my $ref_cids = {} ; # the copy of the ids to contained the rearranged 
		
		# get the seq id of the droppable
		my $droppable_seq_id = $ref_ids->{ $droppable_id }->{ 'SeqId' } ; 
		# set the seq id of the draggable as one bellow
		$ref_cids->{ $droppable_seq_id + 1 }->{ $meta_id } = $draggable_id ; 
		$ref_cids->{ $droppable_seq_id + 1 }->{ 'Level' } = $ref_ids->{$draggable_id}->{'Level'} ; 
		$ref_cids->{ $droppable_seq_id + 1 }->{ 'SeqId' } = $droppable_seq_id + 1 ; 
		

		# build the resuffled hash of hashes but keys will be the sequences
		foreach my $key ( keys ( %$ref_ids ) ) {
			my $c_seq_id = $ref_ids->{ "$key" }->{ 'SeqId' } ; 
			# if the current element is bellow the draggable , but not the draggable
			if ( $c_seq_id >=$droppable_seq_id + 1 && $key != $draggable_id ) {
				# do move with one 
				$c_seq_id = $c_seq_id + 1 ; 
				$ref_ids->{ "$key" }->{ 'SeqId' } = $c_seq_id ; 
			}
			$ref_cids->{ $c_seq_id } = $ref_ids->{ "$key" } ; 
			# and add the meta id  key val
			$ref_cids->{ $c_seq_id }-> { $meta_id } = $key ;
			$ref_cids->{ $c_seq_id }-> { 'Level' } = $ref_ids->{ $key }-> { 'Level' } ; 
		} #eof foreach 

		$ref_cids->{1}->{'ParentItemId'} = 1 ; 
		$ref_cids->{1}->{'LeftRank'} = 1 ; 
		$ref_cids->{1}->{'RightRank'} = 2 ; 
		$ref_cids->{1}->{$meta_id} = 0 ; 
		$ref_reshuffled_ids->{1}->{'ParentItemId'} = 1 ; 
		$ref_reshuffled_ids->{1}->{'LeftRank'} = 1 ; 
		$ref_reshuffled_ids->{1}->{'RightRank'} = 2 ; 
		$ref_reshuffled_ids->{1}->{'Level'} = 0 ; 
		$ref_reshuffled_ids->{1}->{'SeqId'} = 1 ; 
		
		#debug reshuffling p( $ref_cids ) ; return ; 
		
		my %cids = %$ref_cids ; 
		my @keys = sort { $cids{$a} <=> $cids{$b} } keys %cids;
		my @skeys = sort { $a <=> $b } @keys;
		
		# debug ok p(@skeys ) ; 
		# debug return ; 
		my $counter = 1 ; 

		foreach my $key ( @skeys ) {
			#debug p($ref_reshuffled_ids->{$key} ) if $key == 1 ; 
			next if $key == 1 ; 
			#debug next if $counter > 3 ; 
			my $current_level = $ref_cids->{ "$key" }->{'Level'} || 0 ; 
			
			$level_up = $current_level - 1 if $current_level >= 1 ; 
			$parent_id = $ref_levels->{ $level_up }->{ 'ParentItemId'} || 1 ; 
			
			
			unless ( exists ( $ref_levels->{ $current_level }->{ 'SiblingId'} ) )
			{
				$ref_reshuffled_ids = $self->doAddItemToParentWithoutChildren ( 
						$key , $ref_cids , $ref_reshuffled_ids , $parent_id ) ; 
			}
			else {
				my $sibling_id = $ref_levels->{ $current_level }->{ 'SiblingId'} ; 
				$ref_reshuffled_ids = $self->doAddItemNextToSibling ( 
						$key , $ref_cids , $ref_reshuffled_ids , $sibling_id ) ; 
			}
			
			#debug p($ref_reshuffled_ids );
			$ref_levels->{ $current_level }->{ 'SiblingId'} = $key ; 
			$ref_levels->{ $current_level }->{ 'ParentItemId'} = $key ; 
		
			$ref_reshuffled_ids->{ $key }->{ 'Level' } = $ref_cids->{ $key }->{ 'Level'} ; 
			$ref_reshuffled_ids->{ $key }->{ 'SeqId' } = $ref_cids->{ $key }->{ 'SeqId'} ; 
			$ref_reshuffled_ids->{ $key }->{ $meta_id } = $ref_cids->{ $key }->{ $meta_id } ; 
			
			$counter ++ ; 
		}
		#eof foreach
		#
	
		#debug p ( $ref_reshuffled_ids ) ; 
		my $sql = 'LOCK TABLE ' . $db . "." . $table . " WRITE ;"  ; 
      	$sth = $dbh->prepare( $sql );
			$sth->execute()  ; 
		foreach my $key ( keys ( %$ref_reshuffled_ids ) ) {
			my $id = $ref_reshuffled_ids->{ $key }->{ $meta_id } ; 
			my $seq_id = $ref_reshuffled_ids->{ $key }->{ 'SeqId' } ; 
			my $left_rank = $ref_reshuffled_ids->{ $key }->{ 'LeftRank' } ; 
			my $right_rank = $ref_reshuffled_ids->{ $key }->{ 'RightRank' } ; 
			my $level = $ref_reshuffled_ids->{ $key }->{ 'Level' } ; 
			$sql = 'UPDATE ' . $db . '.' . $table . ' SET ' ; 
			$sql .= " Level = '" . $level . "' , " ; 
			$sql .= " SeqId = '" . $seq_id . "' , " ; 
			$sql .= " LeftRank = '" . $left_rank . "' , " ; 
			$sql .= " RightRank = '" . $right_rank . "' " ; 
			$sql .= " WHERE " ; 
			$sql .= $meta_id . " = '" . $id . "'; " ; 

			#debug p($sql ) ; 
      	$sth = $dbh->prepare( $sql );
			$sth->execute()  ; 
		} 
		#eof foreach
		#debug
		#debug return ; 
		$sql = 'UNLOCK TABLES ;' ;
      $sth = $dbh->prepare( $sql );
		$sth->execute()  ; 

		$dbh->disconnect();
	}
	#eof sub do_reshuffle




	sub doAddItemToParentWithoutChildren {

		my $self 					= shift ; 
		my $cur_key  				= shift ; 
		my $ref_cids 				= shift ; 
		my $ref_reshuffled_ids  = shift ; 
		my $parent_id				= shift ; 
		my $p_left 					= $ref_reshuffled_ids->{ "$parent_id" }->{ 'LeftRank' } ; 
		$ref_reshuffled_ids->{ $cur_key }->{ 'LeftRank' } = $p_left + 1 ; 
		$ref_reshuffled_ids->{ $cur_key }->{ 'RightRank' } = $p_left + 2 ; 

		#debug print "cur_key is $cur_key \n" ; 
		#debug print "parent_id is $parent_id \n" ; 
	
		my %reshuffled_ids = %$ref_cids ; 
		my @keys = sort { $reshuffled_ids{$a} <=> $reshuffled_ids{$b} } keys %reshuffled_ids ; 
		my @skeys = sort { $a <=> $b } @keys;
		foreach my $key ( @skeys ) {
			next if $cur_key == $key ; 
			my $c_left = $ref_reshuffled_ids->{ $key }->{ 'LeftRank' } ;
			my $c_right = $ref_reshuffled_ids->{ $key }->{ 'RightRank' } ;
			next unless ( $c_left or $c_right ) ; 

			if ( $c_left > $p_left ) {
 				$ref_reshuffled_ids->{ $key }->{ 'LeftRank' } = $c_left + 2 ; 
				#debug print " doAddItemToParentWithoutChildren:: c_left > p_left \n" ; 
			} #eof if

			if ( $c_right > $p_left ) {
 				$ref_reshuffled_ids->{ $key }->{ 'RightRank' } = $c_right + 2 ; 
				#debug print " doAddItemToParentWithoutChildren:: c_right > p_left \n" ; 
			} #eof if

		} #eof foreach
		return $ref_reshuffled_ids ; 
	}
	
	
	
	
	sub doAddItemNextToSibling {

		my $self 					= shift ; 
		my $cur_key  				= shift ; 
		my $ref_cids 				= shift ; 
		my $ref_reshuffled_ids  = shift ; 
		my $sibling_id				= shift ; 
		# get the right rank from the sibling
		my $p_right = $ref_reshuffled_ids->{ "$sibling_id" }->{ 'RightRank' } ; 
		$ref_reshuffled_ids->{ $cur_key }->{ 'LeftRank' } = $p_right + 1 ; 
		$ref_reshuffled_ids->{ $cur_key }->{ 'RightRank' } = $p_right + 2 ; 
		
		
		my %reshuffled_ids = %$ref_cids ; 
		my @keys = sort { $reshuffled_ids{$a} <=> $reshuffled_ids{$b} } keys %reshuffled_ids ; 
		my @skeys = sort { $a <=> $b } @keys;
		foreach my $key ( @skeys ) {
			next if $cur_key == $key ; 
			my $c_left = $ref_reshuffled_ids->{ $key }->{ 'LeftRank' } ; 
			my $c_right = $ref_reshuffled_ids->{ $key }->{ 'RightRank' } ; 
			next unless ( $c_left or $c_right ) ; 

			if ( $c_left > $p_right ) {
 				$ref_reshuffled_ids->{ $key }->{ 'LeftRank' } = $c_left + 2 ; 
				#debug print " doAddItemNextToSibling c_left > p_right \n" ; 
			} #eof if

			if ( $c_right > $p_right ) {
 				$ref_reshuffled_ids->{ $key }->{ 'RightRank' } = $c_right + 2 ; 
				#debug print " doAddItemNextToSibling c_left > p_right \n" ; 
			} #eof if

		} #eof foreach

		return $ref_reshuffled_ids ; 
	}
	#eof sub doAddItemNextToSibling

	#
   # -----------------------------------------------------------------------------
   # gets all from an item table ( has to have the LogicalOrder attribute
   # -----------------------------------------------------------------------------
	sub doFetchDocumentInlineTables {

      my $self 		= shift ; 
		my $db			= shift ; 
		my $book 		= shift ; 

		my $ret			= () ; 
		my $msg 			= () ;
		
		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw 
		, { 
			  'RaiseError' => 1 
			, 'PrintError' => 1 
		  }
		);

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		

		# the hook is as follows: <<book>>_<<item_id>> i.e. issue_718
		my $sql_inline_tables = '' ; 	
		$sql_inline_tables = " 
			SELECT 
				  CellValueId 
				, BookItemId
				, SUBSTRING_INDEX(BookItemId, '_', -1) as ItemId
				, RowId
				, ColumnName
				, CellValue
				, UpdateTime 
			from " . $db . ".CellValue 
			WHERE 1=1
			and BookItemId like '" . $book . "_%'
			ORDER BY 1 ASC" ; 
							 

      my $sth = $dbh->prepare( $sql_inline_tables );

		$sth->execute() 
				or $objLogger->error ( "$DBI::errstr" ) ; 

		my $ref_inline_tables = $sth->fetchall_hashref('CellValueId') 
				or $objLogger->error ( "$DBI::errstr" ) ;

      $objLogger->debug ("MARIA DB " .  p($ref_inline_tables) ) 
			if ( $module_trace == 1 ) ; 

		#debug p($ref_inline_tables);

		$objController->stash('FetchedDocumentInlineTables' , $ref_inline_tables ) ; 
		$dbh->disconnect() ; 
	}
	#eof sub doFetchDocumentInlineTables


	#
   # ------------------------------------------------------
   # the backend func for saving the content of the paragrapth
	# after the edit from the view post
   # ------------------------------------------------------
	sub get_field_content_for_edit {

		my $self 					= shift;
		my $db 						= $objController->param('db') ; 
		my $table 					= $objController->param('item');
		my $field_value			= $objController->param('value');
		my $id						= $objController->param('id') ; 
		my $ret						= 0 ; # assume error 
		my $field					= '' ; 
		
		my $sql 						= '' ; 
		my $sth			= {} ; 

		#trim the meta data from the control id
		$id	=~ s/dp_([a-zA-Z]*)\-(\d{1,100})/$2/g ; 
		my $field_name = $1 ; 
		print " edit_item_field field_name is $field_name \n" ; 
		$field_value	=~ s/'/''/g ; 
	
		#print "MariaDbHandler::get_field_content_for_edit" ; 
		#print "table: $table \n" ; 
		#print "id: $id \n" ; 
		#print "desc: $field \n" ; 
		#print "db: $db \n" ; 

		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw 
		, { 
			  'RaiseError' => 1 
			, 'PrintError' => 1 
		  }
		);

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		
		$sql = 'SELECT * FROM ' . 	'`' . $db . '`.`' . $table . '` ' ; 
		$sql .= ' WHERE 1=1 AND `' . $table . "Id` = '" . $id . "'" ; 
		
		#debug print "sql:: " . $sql . "\n\n" ; 
		$sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () or $ret = 1 ; 
		

		# LOOP THROUGH RESULTS
		my $data_hash = {} ; 

		$ret = 0 unless ( $sth->err ) ;
		$ret = 1 if ( $sth->err ) ;


		if ( $ret == 1 ) {
			#debug p( $data_hash ) ; 
			my $error_msg = '' ; 
			$error_msg .= " " . $sth->err();
			$error_msg .= " " . $sth->errstr();
			$error_msg .= " " . $sth->state();
			$data_hash->{'error'} = $error_msg ; 
			p($data_hash);	
			return ( $data_hash , $field_name ) ; 
		}
		
		my $hash = {} ; 
		my @query_output = () ;
		use utf8 ; 
		while (my $row = $sth->fetchrow_hashref ){
			 $hash = $row ;
		} 
		#eof while
		
		#print "MariaDbHandler::get_field_content_for_edit" ; 
		#p($hash);

		# close the db connection
		$dbh->disconnect();

		return ( $hash , $field_name )  ;

	}
	#eof sub get_field_content_for_edit

   
	#
   # ------------------------------------------------------
   # the backend func for saving the content of the paragrapth
	# after the edit from the view post
   # ------------------------------------------------------
	sub save_field_content_from_edit {

		my $self 					= shift;
		my $db 						= $objController->param('db') ; 
		my $table 					= $objController->param('item');
		my $field_value			= $objController->param('value');
		my $id						= $objController->param('id') ; 
		my $ret						= 0 ; # assume error 
		
		# otherwise the backslash just disappears !!!
		$field_value	=~ s/\\/\\\\/g ; 
		#trim the meta data from the control id
		$id	=~ s/dp_([a-zA-Z]*)\-(\d{1,100})/$2/g ; 
		my $field_name = $1 ; 
		#debug print 'MariaDbHandler::save_field_content_from_edit' . "field_name is $field_name \n" ; 
		$field_value	=~ s/'/''/g ; 
		
		#print "table: $table \n" ; 
		#print "id: $id \n" ; 
		#print "desc: $field_value \n" ; 
		#print "db: $db \n" ; 

		my $sql = '' ; 
		$sql 	.= 'UPDATE ' . '`' . $db . '`.`' . $table . '` SET ' ; 
		$sql 	.= "`" . $field_name . "`='" . $field_value . "' "; 
		$sql 	.= "WHERE 1=1 AND `" . $table . 'Id`' . "='" . $id . "' ; " ; 

		#debug print "sql:: " . $sql . "\n\n" ; 
		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw 
		, { 
			  'RaiseError' => 1 
			, 'PrintError' => 1 
		  }
		);

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;

		$objLogger->debug("MariaDbHandler::edit_item :::\n $sql" ) if $module_trace == 1 ; 

		#debug print 'MariaDbHandler::save_field_content_from_edit for update  : ' . $sql . "\n" ; 
		
		#print "\n\n sql:: $sql \n\n" ; 
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 
		
		$sth->execute () or $ret = 1 ; 
		
		$sql = 'SELECT * FROM ' . 	'`' . $db . '`.`' . $table . '` ' ; 
		$sql .= ' WHERE 1=1 AND `' . $table . "Id` = '" . $id . "'" ; 
		
		#debug print "sql:: " . $sql . "\n\n" ; 
		$sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () or $ret = 1 ; 
		

		# LOOP THROUGH RESULTS
		my $data_hash = {} ; 

		$ret = 0 unless ( $sth->err ) ;
		$ret = 1 if ( $sth->err ) ;


		if ( $ret == 1 ) {
			#debug p( $data_hash ) ; 
			my $error_msg = '' ; 
			$error_msg .= " " . $sth->err();
			$error_msg .= " " . $sth->errstr();
			$error_msg .= " " . $sth->state();
			$data_hash->{'error'} = $error_msg ; 
			p($data_hash);	
			return $data_hash ; 
		}
		
		my $hash = {} ; 
		use utf8 ; 
		while (my $row = $sth->fetchrow_hashref ){
			 $hash = $row ;
		} 
		#eof while
		
		#debug p($hash ) ; 

		# close the db connection
		$dbh->disconnect();

		#return \@query_outt ; 
		return ( $hash , $field_name ) ; 

	}
	#eof sub save_field_content_from_edit



   #
   # ------------------------------------------------------
   # get the item's view data 
   # ------------------------------------------------------
   sub do_get_item_views {
      
      my $self 		= shift ; 

		my $ret  		= 1 ; 
		my $msg  		= "" ; 
		my $debug_msg  = "" ; 
      my $ref  		= {} ;		# hash reference with hash refs as values and the LogicalOrder as keys
		# debug my $term = 'search' ;     
		my $db	 		= $objController->param('db') || $app_config->{'database'} ; 

      my $dbh 			= DBI->connect("dbi:mysql:database=$db;host=$db_host",
               "$db_user","$db_user_pw",{AutoCommit=>1,RaiseError=>1,PrintError=>1});

		
      my $sql = ' 
		SELECT 
		   ItemView.ItemViewId       
		 , ItemView.Level
		 , ItemView.SeqId
		 , ItemView.doGenerateUi      
		 , ItemView.Name             
		 , ItemView.Description      	as ItemViewDescription
		 , ItemView.doGenerateUi
		 , ItemView.doGeneratePdf
		 , ItemView.doGenerateLeftMenu
		 , ItemView.FileType
		 , ItemView.ItemControllerId 

		 , ItemController.ItemControllerId  
		 , ItemController.doTruncTable      
		 , ItemController.doLoadData        
		 , ItemController.Sheet             
		 , ItemController.Description       
		 , ItemController.IsBook

		 , ItemModel.ItemModelId      
		 , ItemModel.TableNameLC      
		 , ItemModel.TableName        
		 , ItemModel.ItemControllerId 



		FROM ' . "$db" . '.' . 'ItemView
		INNER JOIN ItemController 	ON ( ItemView.ItemControllerId = ItemController.ItemControllerId  ) 
		INNER JOIN ItemModel 		ON ( ItemController.ItemControllerId = ItemModel.ItemControllerId ) 
		WHERE 1=1
		AND ItemView.doGenerateUi = 1
		AND ItemController.IsBook = 1
		ORDER BY ItemView.SeqId ASC
		' ;


		if ( $IsUnitTest == 1 or $module_trace == 1) {	
			$msg 		= "running the following sql: " ; 
			$objLogger->debug ( "$msg" )  ; 
			$msg 		= $sql ; 
			$objLogger->debug ( "$msg" ) ; 
		}

      my $sth  = $dbh->prepare("$sql" )   ; 

      $sth->execute() or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ; 

		# the keys for the hash refs are the values in the SeqId field
      $ref = $sth->fetchall_hashref('ItemViewId') or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ; 
      
      if ( $IsUnitTest == 1 ) { 
         $objLogger->debug ( " using the following db :         $db_host " ) ; 
         $objLogger->debug ( " using the following project_db : $db " ) ; 
         $objLogger->debug ( " using the following db_user : $db_user " ) ; 
      }

      $dbh->disconnect;
		
		$objController->stash ({ 'RefItemViews' , $ref });
      return ( $ret , $msg , $debug_msg , $ref ) ; 
                
   } 
   #eof sub doGetItemViews


   #
   # -----------------------------------------------------------------------------
	# search for tables matching the passed string to search 
	# return an array ref to the caller
   # -----------------------------------------------------------------------------
	sub search_table_items_autocomplete {
		
		my $self 			= shift ;
		my $str_to_srch	= shift ; 

		my $sql 				= '' ; 
		my $db				= '' ; 
		my $dsn 				= '' ; 
		my $dbh			= '' ; 
		my @query_output 	= () ; 
		my $sth 	= {} ; 
		my $gen_sql 		= q{} ;


		# debug my $term = 'search' ;     
		$db = $objController->param('db') || $app_config->{'database'} ; 

		# DATA SOURCE NAME
		$dsn 				= "dbi:mysql:$db:$db_host:$db_port";
		$dbh 		= DBI->connect($dsn, $db_user, $db_user_pw);
		$dbh->{'mysql_enable_utf8'} = 1;

		$str_to_srch		= '%' . $str_to_srch . '%' ; 
		# obs as value !!!
		$sql .= "
			SELECT TABLE_NAME AS value FROM INFORMATION_SCHEMA.TABLES
			WHERE 1=1 
			AND TABLE_SCHEMA = ?
			AND TABLE_NAME LIKE ?
		 " ; 
		
		$sth = $dbh->prepare($sql);
		$sth->execute ( $db, $str_to_srch ) ; 

		 
		# LOOP THROUGH RESULTS
		while ( my $row = $sth->fetchrow_hashref ){
			 push @query_output, $row 
		} #eof while

		# CLOSE THE DATABASE CONNECTION
		$dbh->disconnect();

		return \@query_output ; 
	}
	#eof sub search_items_autocomplete

	
   #
   # -----------------------------------------------------------------------------
	# search for any string from the Name and Descriptions of the Items
   # -----------------------------------------------------------------------------
	sub search_items_names_and_descs_autocomplete {
		
		my $self 			= shift ;
		my $term 			= shift ; 

		my $sql 				= '' ; 
		my $db				= '' ; 
		my $dsn 				= '' ; 
		my $dbh			= '' ; 
		my @query_output 	= () ; 
		my $sth 	= {} ; 
		my $gen_sql 		= q{} ;


		# debug my $term = 'search' ;     
		$db					= $objController->param('db') || $app_config->{'database'} ; 

		# DATA SOURCE NAME
      $dbh 			= DBI->connect("dbi:mysql:database=$db;host=$db_host",
               "$db_user","$db_user_pw",{AutoCommit=>1,RaiseError=>1,PrintError=>1});

		$dbh->{'mysql_enable_utf8'} = 1;
		# obs ! as value !!!
		$sql .= "
				SELECT TABLE_NAME 
				FROM INFORMATION_SCHEMA.COLUMNS 
				WHERE 1=1 
				AND COLUMN_NAME='Name' 
				AND TABLE_SCHEMA=?;
		" ; 
		#debug print 'MariaDbHandler::search_items_names_and_descs_autocomplete ' . "sql: $sql" ; 
	

      $sth  = $dbh->prepare("$sql" )   ; 
		$sth->execute ( $db ) or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ;

		while ( my $row = $sth->fetchrow_hashref ){
			 $gen_sql .= 
			 'SELECT CONCAT(' ."'".  $row->{'TABLE_NAME'} . ": '" 
			 . ' , Name )  as value  FROM ' . $row->{'TABLE_NAME'} . 
			 " WHERE 1=1 AND Name like '%" . $term . "%'  UNION ALL "
		} #eof while


		$gen_sql =~ s/UNION ALL $/;/g ; 
		#print $gen_sql ; 
		#debug print "gen_sql: $gen_sql" ; 

		#old $sth = $dbh->prepare(qq{SELECT Name as value  FROM Issue where Name like ?;});
		$sth= $dbh->prepare ( "$gen_sql" ) ; 
				
		# EXECUTE THE QUERY
		$sth->execute();
				 
		# LOOP THROUGH RESULTS
		while ( my $row = $sth->fetchrow_hashref ){
			 my %hash = %$row ; 
			 #say "UTF8 flag is turned on in the STRING $key" if is_utf8( $hash{$key} );
			 push @query_output, $row 
			 #if is_utf8( $hash{$key} );
		} #eof while

		# CLOSE THE DATABASE CONNECTION
		$dbh->disconnect();
	
		#debug p(@query_output);
		return \@query_output ; 
	}
	#eof sub search_items_autocomplete


	
   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub list_items_meta {

		my $self 				= shift;
		my $db 			      = shift || 'isg_pub_en' ; 
		my $table				= shift || 'Issue' ; 
		my $ret					= 1 ; 


		
		# build the data source name
		my $dsn 				= "dbi:mysql:$db:$db_host:$db_port";
		# perl dbi connect
		my $dbh 		= DBI->connect($dsn, $db_user, $db_user_pw);
			  
		my $sql = "
			SELECT 
			    TABLE_SCHEMA 
			  , COLUMN_NAME 
			  , ORDINAL_POSITION 
			  , IS_NULLABLE 
			  , DATA_TYPE 
			  , CHARACTER_MAXIMUM_LENGTH
			  , NUMERIC_PRECISION 
			  , NUMERIC_SCALE
		  FROM INFORMATION_SCHEMA.COLUMNS 
		  WHERE 1=1
		  AND TABLE_SCHEMA = '" . $db . "'
		  AND TABLE_NAME ='" . $table . "'
		" ; 
		
		my $sth = () ; 
		$sth = $dbh->prepare( "$sql" ) or $ret = 1 ; 

		if ( $ret == 1 ) {
			$objController->stash({'DebugMsg' => $sth->errstr}); 
			$objController->stash({'Msg' => $sth->errstr}); 
		}

		my $res = $sth->execute() or die $sth->errstr ; 
		my $refArr = $sth->fetchall_hashref ( 'ORDINAL_POSITION' );

		$res = $sth->finish();

		# close the db connection
		$dbh->disconnect();

		$objController->stash({'Ret' => 0 });
		
		return $refArr ; 
	}
	#eof sub list_items_meta


   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub list_query_data {

		my $self 		= shift;
		my $sql			= shift ; 

		#debug $objLogger->debug( "from list_items the database is : " . $app_config->{'database'} );
		#debug $objLogger->debug( "from list_items the db_user is : " . $app_config->{'db_user'} );
		#debug $objLogger->debug( "from list_items the db_user_pw is : " . $app_config->{'db_user_pw'} );
		
		# params

		# DATA SOURCE NAME connect to the mysql db
		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw , { 'RaiseError' => 1 } );

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		# ensure utf-8 is in use
		#my $dbh = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1}); my $sql = '' ; 
		
		#debug print "\n\n sql:: $sql \n\n" ; 
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 
		
		my $res_meta = {}  ;
		my $i = 1 ; 
		my $rfArrHeaders = $sth->{'NAME'} ; 
		foreach my $header ( @$rfArrHeaders ) {
			my $tmp = {} ; 
			$tmp->{"COLUMN_NAME"} = $header ; 
			$tmp->{'ORDINAL_POSITION'} = $i ;
			$res_meta->{$i} = $tmp ; 
			$i++ ; 
		}
		$self->set('ResMeta' , $res_meta );

		# populate the array references with hash references 
		my @query_output = () ; 
		while ( my $row = $sth->fetchrow_hashref ){
			
			 #my %hash = %$row ; 
			 #for my $key ( sort keys %hash ) {
				# say "UTF8 flag is turned on in the STRING $key" if is_utf8( $hash{$key} );
				#say "UTF8 flag is NOT turned on in the STRING $key" if not is_utf8( $hash{$key} );
			 # }
			 push @query_output, $row;
		} #eof while


		# close the db connection
		$dbh->disconnect();

		return \@query_output ; 	
	}
	#eof sub list_query_data



   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub add_new_item {

		my $self 					= shift;
		my $db 						= shift ; 
		my $table 					= shift ; 
		my $dt_post_hs				= shift ; #the post hash
		my $ret						= 0 ; # assume error 
		my $columns_part			= '' ; 
		my $values_part			= '' ; 
		my $sql = '' ; 
		
		#debug print "add_new_item hash \n" ; 
		#debug p($dt_post_hs) ; 
		 
		# DATA SOURCE NAME connect to the mysql db
		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw 
		, { 
			  'RaiseError' => 1 
			, 'PrintError' => 1 
		  }
		);

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;

		$sql = 'SELECT MAX(' . $table . 'Id) AS ' . $table . 'Id
		FROM ' . 	'`' . $db . '`.`' . $table . '` ' ; 
		
		#debug print "sql:: " . $sql . "\n\n" ; 
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () or $ret = 1 ; 
		

		# LOOP THROUGH RESULTS
		my $data_hash = {} ; 

		$ret = 0 unless ( $sth->err ) ;
		$ret = 1 if ( $sth->err ) ;


		if ( $ret == 1 ) {
			#debug p( $data_hash ) ; 
			my $error_msg = '' ; 
			$error_msg .= " " . $sth->err();
			$error_msg .= " " . $sth->errstr();
			$error_msg .= " " . $sth->state();
			$data_hash->{'error'} = $error_msg ; 
			p($data_hash);	
			return $data_hash ; 
		}
		
		my $h = {} ; 
		use utf8 ; 
		while (my $row = $sth->fetchrow_hashref ){
			 $h = $row ;
		} 
		#eof while
		
		$sql = '' ; 
		my $id_name = $table . 'Id' ; 
		my $id_value = $h->{ $id_name } ; 
		$id_value = $id_value + 1 ; # autoincrement by one

		#traverse the hash
		foreach my $key ( keys ( %{$dt_post_hs} ) ) {
			my $column = $key ; 
			my $value		 =$dt_post_hs->{$key} ; 

			$column			 =~ s/data\[([0-9a-zA-Z_]*)]\[([0-9a-zA-Z_]*)\]/$2/g ; 
			$value 			 =~ s/\'/\'\'/g ;			
			
			# the hashed passed from the data types has the following syntax
			# data[0][Name]            "nAME",
			# action                   "create",
			next if ( 
				( $column eq 'action' and $value eq 'edit') 
			or	( $column eq 'action' and $value eq 'create') 
			or ( $column eq 'ActionButtons' )
			) ;

			$columns_part 	.= '`' . $column . '` , ' ; 

			$values_part	.= "'" . $value . "' , " unless $column eq $id_name ; 
			$values_part	.= "'" . $id_value . "' , " if $column eq $id_name ; 
		}
	
		for (1..3) { chop ( $values_part ) } ; 
		for (1..3) { chop ( $columns_part ) } ; 
		
		$sql 	.= 'INSERT INTO ' . '`' . $db . '`.`' . $table . '` ' ; 
		$sql  .= '(' . $columns_part . ') VALUES ( ' . $values_part . ')' ; 


		#debug print "add_new insert sql : " . $sql . "\n" ; 
		$objLogger->debug("MariaDbHandler::new_item :::\n $sql" );
		
		#print "\n\n sql:: $sql \n\n" ; 
		$sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 
		
		$sql = '' ; 

		$sql = 'SELECT * FROM ' . 	'`' . $db . '`.`' . $table . '` ' ; 
		$sql .= ' WHERE 1=1 AND `' . $table . "Id` = '" . $id_value . "'" ; 
		
		#debug print "sql:: " . $sql . "\n\n" ; 
		$sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () or $ret = 1 ; 
		

		# LOOP THROUGH RESULTS
		$data_hash = {} ; 

		$ret = 0 unless ( $sth->err ) ;
		$ret = 1 if ( $sth->err ) ;

		if ( $ret == 1 ) {
			#debug p( $data_hash ) ; 
			my $error_msg = '' ; 
			$error_msg .= " " . $sth->err();
			$error_msg .= " " . $sth->errstr();
			$error_msg .= " " . $sth->state();
			$data_hash->{'error'} = $error_msg ; 
			p($data_hash);	
			return $data_hash ; 
		}

		my @query_output = () ;
		use utf8 ; 
		while (my $row = $sth->fetchrow_hashref ){
			 $h = $row ;
			 $row->{'ActionButtons'} = ' ' ; 
			 push @query_output, $row;
		} 
		#eof while
		
		#p(@query_output);

		$data_hash->{'data'} = [ $h ]  ; 
		#debug p( $data_hash ) ; 

		# close the db connection
		$dbh->disconnect();

		#return \@query_outt ; 
		return $data_hash ; 
	}
	#eof sub add_new_item

   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub remove_item {

		my $self 					= shift;
		my $db 						= shift ; 
		my $table 					= shift ; 
		my $post_hash				= shift ; 
		my $ret						= 0 ; # assume error 
		
		my $sql = '' ; 
		$sql 	.= 'DELETE FROM ' . '`' . $db . '`.`' . $table . '` ' ; 
		my $id_value ; 
		#traverse the hash
		foreach my $key ( keys ( %{$post_hash} ) ) {
			my $column = $key ; 
			my $value		 =$post_hash->{$key} ; 

			$column			 =~ s/data\[([0-9a-zA-Z_]*)]\[([0-9a-zA-Z_]*)\]/$2/g ; 
			next if ( 
				( $column eq 'action' and $value eq 'edit') 
			or ( $column eq 'ActionButtons' )
			) ;

			$id_value = $1 ; 
		}
	
		$sql .= " WHERE $table" . "Id='" . $id_value . "'" ; 
		#debug print "MariaDbHandler::remove_item sql:: " . $sql . "\n\n" ; 

		# DATA SOURCE NAME connect to the mysql db
		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw 
		, { 
			  'RaiseError' => 1 
			, 'PrintError' => 1 
		  }
		);

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;

		# ensure utf-8 is in use
		#my $dbh = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1}); my $sql = '' ; 

		$objLogger->debug("MariaDbHandler::edit_item :::\n $sql" );
		
		#print "\n\n sql:: $sql \n\n" ; 
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 

		return ; 

	}
	#eof sub remove_item

   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub edit_item {

		my $self 					= shift;
		my $db 				= shift ; 
		my $table 					= shift ; 
		my $post_hash				= shift ; 
		my $ret						= 0 ; # assume error 
		
		my $sql = '' ; 
		$sql 	.= 'UPDATE ' . '`' . $db . '`.`' . $table . '` SET ' ; 
		my $id_value ; 
		#traverse the hash
		foreach my $key ( keys ( %{$post_hash} ) ) {
			my $column = $key ; 
			my $value		 =$post_hash->{$key} ; 

			$column			 =~ s/data\[([0-9a-zA-Z_]*)]\[([0-9a-zA-Z_]*)\]/$2/g ; 
			next if ( 
				( $column eq 'action' and $value eq 'edit') 
			or ( $column eq 'ActionButtons' )
			) ;

			$sql 				.= '`' . $column . '`' . "='" ; 
			$value 			 =~ s/\'/\'\'/g ;			

			$sql 				.= $value . "' , " ; 	
			$id_value = $1  ;
		}
	
		for (1..3) { chop ( $sql) } ; 
		$sql .= " WHERE $table" . "Id='" . $id_value . "'" ; 
		#debug print "MariaDbHandler::edit_item sql:: " . $sql . "\n\n" ; 

		# DATA SOURCE NAME connect to the mysql db
		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw 
		, { 
			  'RaiseError' => 1 
			, 'PrintError' => 1 
		  }
		);

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;

		# ensure utf-8 is in use
		#my $dbh = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1}); my $sql = '' ; 

		$objLogger->debug("MariaDbHandler::edit_item :::\n $sql" );
		
		#print "\n\n sql:: $sql \n\n" ; 
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 
		

		$sql = 'SELECT * FROM ' . 	'`' . $db . '`.`' . $table . '` ' ; 
		$sql .= ' WHERE 1=1 AND `' . $table . "Id` = '" . $id_value . "'" ; 
		
		#debug print "sql:: " . $sql . "\n\n" ; 
		$sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () or $ret = 1 ; 
		

		# LOOP THROUGH RESULTS
		my $data_hash = {} ; 

		$ret = 0 unless ( $sth->err ) ;
		$ret = 1 if ( $sth->err ) ;


		if ( $ret == 1 ) {
			#debug p( $data_hash ) ; 
			my $error_msg = '' ; 
			$error_msg .= " " . $sth->err();
			$error_msg .= " " . $sth->errstr();
			$error_msg .= " " . $sth->state();
			$data_hash->{'error'} = $error_msg ; 
			p($data_hash);	
			return $data_hash ; 
		}
		my $out_hash = {} ; 
		my @query_output = () ;
		use utf8 ; 
		while (my $row = $sth->fetchrow_hashref ){
			 $out_hash = $row ;
			 $row->{'ActionButtons'} = ' ' ; 
			 push @query_output, $row;
		} 
		#eof while
		
		p(@query_output);

		#debug p( $data_hash ) ; 

		# close the db connection
		$dbh->disconnect();

		return \@query_output ; 
	}
	#eof sub edit_item
   
	#
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub list_doc_items_bottom_up {

		my $self = shift;

		#debug $objLogger->debug( "from list_items the database is : " . $app_config->{'database'} );
		#debug $objLogger->debug( "from list_items the db_user is : " . $app_config->{'db_user'} );
		#debug $objLogger->debug( "from list_items the db_user_pw is : " . $app_config->{'db_user_pw'} );
		
		# params
		my $table 					= $objController->param('item') 	|| 'Issue' ;
		my $db 				= $objController->param('db') 	|| $app_config->{'database'} ; 
		
		my $filter_name 			= '' ; 
		my $filter_value 			= '' ; 
		my $like_name 				= '' ; 
		my $like_value 			= '' ; 

		my $ref_filter_names 	= $objController->every_param('filter-by')  ;
		my $ref_filter_values 	= $objController->every_param('filter-value')  ;
		my $ref_like_names 		= $objController->every_param('like-by')  ;
		my $ref_like_values 		= $objController->every_param('like-value')  ;
		# this is the single path id
		my $path_id					= $objController->param('path-id')  || 1 ; 
		my $order_by 				= $objController->param('order-by')  || 4 ; 
		my $order_type 			= $objController->param('order-type')  || ' ASC ' ; 
		
		#debug print "\@list: filter_values\n" ; 
		#debug p($ref_filter_values) ;
		#debug print "\@list: filter_names\n" ; 
		#debug p($ref_filter_names) ;

		my $optional_url_params = ' ' ; 

		$optional_url_params .= ' , "db": "' . $db . '"' 
		if ( defined ( $db ) ) ; 

		if ( @$ref_filter_names and @$ref_filter_values ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

				$filter_value = $ref_filter_names->["$i"] ; 	
				$filter_name  = $ref_filter_names->["$i"] ; 	
			}
		}


		if ( @$ref_like_names and @$ref_like_values ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_like_names ) ; $i++ ) {

				$like_name 	= $ref_like_names->["$i"] ; 	
				$like_value = $ref_like_values->["$i"] ; 	
			}
		}

		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw);
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		# ensure utf-8 is in use
		#my $dbh = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1}); my $sql = '' ; 
		
		#my $sql .= "SELECT * FROM $db" . '.' . "$table " if $table ; 
		return unless $table ; 

		# get the branch_id from the path_id
		#courtesy of: http://mikehillyer.com/articles/managing-hierarchical-data-in-mysql/
		# when you walk bottou up in the hierarchy there is always one and only one document
		# on the first level, which is exactly the one we want 
		my $branch_id = " SELECT Bigger." . $table . "Id FROM " . $db . '.' . $table . " AS Bigger
		INNER JOIN  ( 
			SELECT parent." . $table . "Id
			FROM " . $db . '.' . $table . " AS node,
			" . $db . '.' . $table . " AS parent
			WHERE node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
			AND node." . $table . "Id = '" . $path_id . "'
			ORDER BY node.LeftRank ASC
			) SINGLE_PATH_RESULT_SET
			ON Bigger." . $table . "Id = SINGLE_PATH_RESULT_SET." . $table . "Id 
			WHERE 1=1 
			AND Level = 1
		" ; 

		
		my $sql = "" ; 
		$sql .= " SELECT dyn_sql.* " ; 
		# http://stackoverflow.com/a/6809925/65706
		# start add tags 
		$sql .= ", GROUP_CONCAT(Tag.Name SEPARATOR ' ') TagName " ; 
		# stop add tags 
		
		# stop add tags 
		
		$sql .= " FROM ( SELECT node.*
			FROM " . $db . '.' . $table . " AS node,
			" . $db . '.' . $table . " AS parent 
			WHERE 1=1 
			AND node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
			AND parent." . $table . "Id IN (" . $branch_id . ")
				) AS dyn_sql " ; 

		# start add tags 
			$sql .= ' LEFT JOIN TagMap ON (  ' ; 
			$sql .= " TagMap.ItemId = dyn_sql." . $table . 'Id AND'  ; 
			$sql .= " TagMap.ItemName = '" . $table . "' )" ; 
			$sql .= ' LEFT JOIN Tag ON (  ' ; 
			$sql .= " TagMap.TagId = Tag.TagId )" ; 
		# stop add tags 
	
		$sql .= "
			WHERE 1=1 
		" ; 
		
		# build the dynamic filtering for the the in clause
		if ( @$ref_filter_names and @$ref_filter_values  ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

				$filter_value = $ref_filter_values->["$i"] ; 	
				$filter_name = $ref_filter_names->["$i"] ; 	
				
				#debug $objLogger->debug ( "List::list filter_name: $filter_name ");
				#debug $objLogger->debug ( "List::list filter_value: $filter_value ");
			
				my @filter_values_list = split (',' , $filter_value ) ; 
				my $str = '(' ; 
				foreach my $item ( @filter_values_list ) {
					$str .= " '" . $item . "' ," ; 
				}
				chop ( $str ) ; $str .= ') ' ; 

				$sql .= "AND dyn_sql." . "$filter_name  in $str "
					if ( defined ( $filter_value ) and defined ( $filter_name ) );
			}
		}
		
		
		# build the dynamic filtering for the the "LIKE" clause
		if ( @$ref_like_names and @$ref_like_values  ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_like_names ) ; $i++ ) {

				$like_name = $ref_like_names->["$i"] ; 	
				$like_value = $ref_like_values->["$i"] ; 	
				
				#debug $objLogger->debug ( "List::list filter_name: $filter_name ");
				#debug $objLogger->debug ( "List::list filter_value: $filter_value ");
				#$filter_name =~ s/(^|_)./uc($&)/ge;s/_//g ;
				$like_value = lc ( $like_value ) ; 
				
				if ( defined ( $like_value ) and defined ( $like_name ) ) {
					$sql .= "AND lower(dyn_sql." . "$like_name) LIKE '%" . $like_value . "%' \n"  ; 
				}
			
			}
		}
		
		$sql .= " GROUP BY dyn_sql." . $table . "Id" ; 
		$sql .= ' ORDER BY ' . $order_by . ' ' . $order_type ; 


		$objLogger->info("MariaDbHandler::list_doc_items_bottom_up search SQL:\n $sql" );
	
		#debug print "doc_pub/lib/DocPub/Model/MariaDbHandler.pm sub list_doc_items_from_bottom" ;
		#debug print "\n\n sql:: $sql \n\n" ; 
		
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 

		# populate the array references with hash references 
		my @query_output = () ; 
		while ( my $row = $sth->fetchrow_hashref ){
			 #my %hash = %$row ; 
			 #for my $key ( sort keys %hash ) {
				# say "UTF8 flag is turned on in the STRING $key" if is_utf8( $hash{$key} );
				#say "UTF8 flag is NOT turned on in the STRING $key" if not is_utf8( $hash{$key} );
			 # }
			 push @query_output, $row;
		} #eof while

		# close the db connection
		$dbh->disconnect();

		$self->doFetchDocumentInlineTables($db , $table )  ; 
			#if $objController->isa( 'DocView' ) ; 

		return \@query_output ; 	
	}
	#eof sub list_doc_items_from_bottom
	
	#
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub list_doc_items {

		my $self = shift;

		#debug $objLogger->debug( "from list_items the database is : " . $app_config->{'database'} );
		#debug $objLogger->debug( "from list_items the db_user is : " . $app_config->{'db_user'} );
		#debug $objLogger->debug( "from list_items the db_user_pw is : " . $app_config->{'db_user_pw'} );
		
		# params
		my $table 					= $objController->param('item') 	|| 'Issue' ;
		return unless $table ; 
		my $db 						= $objController->param('db') 	|| $app_config->{'database'} ; 
		
		my $filter_name 			= '' ; 
		my $filter_value 			= '' ; 
		my $like_name 				= '' ; 
		my $like_value 			= '' ; 

		my $ref_filter_names 	= $objController->every_param('filter-by')  ;
		my $ref_filter_values 	= $objController->every_param('filter-value')  ;
		my $ref_like_names 		= $objController->every_param('like-by')  ;
		my $ref_like_values 		= $objController->every_param('like-value')  ;
		my $branch_node_id		= $objController->param('branch-id')  || 1 ; 
		my $order_by 				= $objController->param('order-by')  || 3 ; 
		my $order_type 			= $objController->param('order-type')  || ' ASC ' ; 
		
		#debug print "\@list: filter_values\n" ; 
		#debug p($ref_filter_values) ;
		#debug print "\@list: filter_names\n" ; 
		#debug p($ref_filter_names) ;

		my $optional_url_params = ' ' ; 

		$optional_url_params .= ' , "db": "' . $db . '"' 
		if ( defined ( $db ) ) ; 

		if ( @$ref_filter_names and @$ref_filter_values ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

				$filter_value = $ref_filter_names->["$i"] ; 	
				$filter_name  = $ref_filter_names->["$i"] ; 	
			}
		}


		if ( @$ref_like_names and @$ref_like_values ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_like_names ) ; $i++ ) {

				$like_name 	= $ref_like_names->["$i"] ; 	
				$like_value = $ref_like_values->["$i"] ; 	
			}
		}

		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw);
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		# ensure utf-8 is in use
		#my $dbh = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1}); my $sql = '' ; 
		
		#my $sql .= "SELECT * FROM $db" . '.' . "$table " if $table ; 


		#courtesy of: http://mikehillyer.com/articles/managing-hierarchical-data-in-mysql/
		my $sql = '' ; 
#		$sql .= "
#			SELECT " . $db . '.' . $table . ".* , Tag.Name as TagName , TagMap.TagMapId as TagMapId
#			FROM " . $db . '.' . $table . " 
#		" if $branch_node_id == 1 ; 

		$sql .= " SELECT dyn_sql.* " ; 

		# start add tags 
		$sql .= ", GROUP_CONCAT(Tag.Name SEPARATOR ' ') TagName " ; 
		# stop add tags 
		$sql .= " FROM (SELECT node.* " ; 
		$sql .= " FROM " . $db . '.' . $table . " AS node,
			" . $db . '.' . $table . " AS parent " ; 


		$sql .= " WHERE 1=1 " ;
		$sql .= "
			AND node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
			AND parent." . $table . "Id = '" . $branch_node_id . "') AS dyn_sql "  ;


		# start add tags 
			$sql .= ' LEFT JOIN TagMap ON (  ' ; 
			$sql .= " TagMap.ItemId = dyn_sql." . $table . 'Id AND'  ; 
			$sql .= " TagMap.ItemName = '" . $table . "' )" ; 
			$sql .= ' LEFT JOIN Tag ON (  ' ; 
			$sql .= " TagMap.TagId = Tag.TagId )" ; 
		# stop add tags 
		
		$sql .= " WHERE 1=1 " ; 


		#$sql = 'SELECT * FROM ( ' . $sql . ') WHERE 1=1 ' ; 
		
		# build the dynamic filtering for the the in clause
		if ( @$ref_filter_names and @$ref_filter_values  ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

				$filter_value = $ref_filter_values->["$i"] ; 	
				$filter_name = $ref_filter_names->["$i"] ; 	
				
				#debug $objLogger->debug ( "List::list filter_name: $filter_name ");
				#debug $objLogger->debug ( "List::list filter_value: $filter_value ");
			
				my @filter_values_list = split (',' , $filter_value ) ; 
				my $str = '(' ; 
				foreach my $item ( @filter_values_list ) {
					$str .= " '" . $item . "' ," ; 
				}
				chop ( $str ) ; $str .= ') ' ; 

				$sql .= "AND dyn_sql." . "$filter_name  in $str "
					if ( defined ( $filter_value ) and defined ( $filter_name ) );
			}
		}
		
		
		# build the dynamic filtering for the the "LIKE" clause
		if ( @$ref_like_names and @$ref_like_values  ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_like_names ) ; $i++ ) {

				$like_name = $ref_like_names->["$i"] ; 	
				$like_value = $ref_like_values->["$i"] ; 	
				
				#debug $objLogger->debug ( "List::list filter_name: $filter_name ");
				#debug $objLogger->debug ( "List::list filter_value: $filter_value ");
				#$filter_name =~ s/(^|_)./uc($&)/ge;s/_//g ;
				$like_value = lc ( $like_value ) ; 
				
				if ( defined ( $like_value ) and defined ( $like_name ) ) {
					$sql .= "AND lower(dyn_sql." . $like_name . ") LIKE '%" . $like_value . "%' \n"  ; 
				}
			
			}
		}
		
		# debug print "MariaDbHandler sub list_doc_items \n\n" ; 
		# debug print "\n\n sql:: $sql \n\n" ; 
		
		$sql .= " GROUP BY dyn_sql." . $table . "Id" ; 
		
		# if the caller is the doc view
		$sql .= ' ORDER BY ' . $order_by . ' ' . $order_type ; 


		$objLogger->debug("MariaDbHandler::list_items search SQL:\n $sql" );
		
		#debug print "MariaDbHandler::list_doc_items \n" ; 
		#debug print "\n\n sql:: $sql \n\n" ; 
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 

		
		# populate the array references with hash references 
		my @query_output = () ; 
		while ( my $row = $sth->fetchrow_hashref ){
			 #my %hash = %$row ; 
			 #for my $key ( sort keys %hash ) {
				# say "UTF8 flag is turned on in the STRING $key" if is_utf8( $hash{$key} );
				#say "UTF8 flag is NOT turned on in the STRING $key" if not is_utf8( $hash{$key} );
			 # }
			 push @query_output, $row;
		} #eof while

		# close the db connection
		$dbh->disconnect();


		$self->doFetchDocumentInlineTables($db , $table ) ; 
		return \@query_output ; 	
	}
	#eof sub list_doc_items
	
   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub list_images_data {

		my $self = shift;
		my $for_table 				= shift ; 
		my $db 						= $objController->param('db') 	|| $app_config->{'database'} ; 
		
		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw);
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		# ensure utf-8 is in use
		#my $dbh = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1}); my $sql = '' ; 
		
		#my $sql .= "SELECT * FROM $db" . '.' . "$table " if $table ; 


		my $sql = "
		SELECT 
		   ItemId		 	as ImageItemId
		 , Name 				as ImageTitle
		 , Description		as ImageDescription
		 , RelativePath 	as ImageRelativePath
		 , ItemName		 	as ImageItemName
		 , Width 			as Width
		 , Height 			as Height 
		 , HttpPath 		as ImageHttpPath
			FROM Image
			WHERE 1=1
			AND ItemName = '" . $for_table . "'
		 
		 "
		 ; 
		#debug $objLogger->debug("MariaDbHandler::list_images_data search SQL:\n $sql" );
		
		#print "\n\n sql:: $sql \n\n" ; 
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 

		
		# populate the array references with hash references 
		my @query_output = () ; 
		while ( my $row = $sth->fetchrow_hashref ){
			push @query_output, $row;
		} 

		# close the db connection
		$dbh->disconnect();

		return \@query_output ; 	
	}
	#eof sub list_items


   #
   # -----------------------------------------------------------------------------
	# get the result set for a table
   # -----------------------------------------------------------------------------
	sub list_items {

		my $self 	= shift;

		#debug $objLogger->debug( "from list_items the database is : " . $app_config->{'database'} );
		#debug $objLogger->debug( "from list_items the db_user is : " . $app_config->{'db_user'} );
		#debug $objLogger->debug( "from list_items the db_user_pw is : " . $app_config->{'db_user_pw'} );
		
		# params
		my $table 					= $objController->param('item') 	|| 'Issue' ;
		my $db 						= $objController->param('db') 	|| $app_config->{'database'} ; 
		
		my $filter_name 			= '' ; 
		my $filter_value 			= '' ; 
		my $like_name 				= '' ; 
		my $like_value 			= '' ; 

		my $ref_filter_names 	= $objController->every_param('filter-by')  ;
		my $ref_filter_values 	= $objController->every_param('filter-value')  ;
		my $ref_like_names 		= $objController->every_param('like-by')  ;
		my $ref_like_values 		= $objController->every_param('like-value')  ;
		my $branch_node_id		= $objController->param('branch-id')  || 1 ; 
		my $order_by 				= $objController->param('order-by')  || 1 ; 
		my $order_type 			= $objController->param('order-type')  || ' ASC ' ; 
		
		#debug print "\@list: filter_values\n" ; 
		#debug p($ref_filter_values) ;
		#debug print "\@list: filter_names\n" ; 
		#debug p($ref_filter_names) ;

		my $optional_url_params = ' ' ; 

		$optional_url_params .= ' , "db": "' . $db . '"' 
		if ( defined ( $db ) ) ; 

		if ( @$ref_filter_names and @$ref_filter_values ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

				$filter_value = $ref_filter_names->["$i"] ; 	
				$filter_name  = $ref_filter_names->["$i"] ; 	
			}
		}


		if ( @$ref_like_names and @$ref_like_values ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_like_names ) ; $i++ ) {

				$like_name 	= $ref_like_names->["$i"] ; 	
				$like_value = $ref_like_values->["$i"] ; 	
			}
		}

		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw);
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		# ensure utf-8 is in use
		#my $dbh = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1}); my $sql = '' ; 
		
		#my $sql .= "SELECT * FROM $db" . '.' . "$table " if $table ; 
		return unless $table ; 


		my $sql = '' ; 
		$sql .= "
			SELECT " . $db . '.' . $table . ".* 
			FROM " . $db . '.' . $table . " 
		" if $branch_node_id == 1 ; 

		$sql .= " SELECT * FROM (SELECT node.*
			FROM " . $db . '.' . $table . " AS node,
			" . $db . '.' . $table . " AS parent 
		" if $branch_node_id != 1 ; 

		$sql .= " WHERE 1=1 " ;
		$sql .= "
			AND node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
			AND parent." . $table . "Id = '" . $branch_node_id . "') AS dyn_sql WHERE 1=1 
		" if $branch_node_id != 1 ; 


		#$sql = 'SELECT * FROM ( ' . $sql . ') WHERE 1=1 ' ; 
		
		# build the dynamic filtering for the the in clause
		if ( @$ref_filter_names and @$ref_filter_values  ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

				$filter_value = $ref_filter_values->["$i"] ; 	
				$filter_name = $ref_filter_names->["$i"] ; 	
				
				#debug $objLogger->debug ( "List::list filter_name: $filter_name ");
				#debug $objLogger->debug ( "List::list filter_value: $filter_value ");
			
				my @filter_values_list = split (',' , $filter_value ) ; 
				my $str = '(' ; 
				foreach my $item ( @filter_values_list ) {
					$str .= " '" . $item . "' ," ; 
				}
				chop ( $str ) ; $str .= ') ' ; 

				$sql .= "AND $filter_name  in $str "
					if ( defined ( $filter_value ) and defined ( $filter_name ) );
			}
		}
		
		
		# build the dynamic filtering for the the "LIKE" clause
		if ( @$ref_like_names and @$ref_like_values  ) {

			for ( my $i = 0 ; $i < scalar ( @$ref_like_names ) ; $i++ ) {

				$like_name = $ref_like_names->["$i"] ; 	
				$like_value = $ref_like_values->["$i"] ; 	
				
				#debug $objLogger->debug ( "List::list filter_name: $filter_name ");
				#debug $objLogger->debug ( "List::list filter_value: $filter_value ");
				#$filter_name =~ s/(^|_)./uc($&)/ge;s/_//g ;
				$like_value = lc ( $like_value ) ; 
				
				if ( defined ( $like_value ) and defined ( $like_name ) ) {
					$sql .= "AND lower($like_name) LIKE '%" . $like_value . "%' \n"  ; 
				}
			
			}
		}
	
		
		#$sql .= ' ORDER BY ' . $order_by . ' ' . $order_type ; 
		#


		$objLogger->debug("MariaDbHandler::list_items search SQL:\n $sql" );
		


		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 

		# populate the array references with hash references 
		my @query_output = () ; 
		while ( my $row = $sth->fetchrow_hashref ){
			 #my %hash = %$row ; 
			 #for my $key ( sort keys %hash ) {
				# say "UTF8 flag is turned on in the STRING $key" if is_utf8( $hash{$key} );
				#say "UTF8 flag is NOT turned on in the STRING $key" if not is_utf8( $hash{$key} );
			 # }
			 push @query_output, $row;
		} #eof while

		# close the db connection
		$dbh->disconnect();

		return \@query_output ; 	
	}
	#eof sub list_items
   

   #
   # ------------------------------------------------------
   #  loads the data needed to construct the left menu 
   #  and the whole app pages structure of the app
   # ------------------------------------------------------
   sub doLoadAppPagesData {
      
      my $self 		= shift ; 

      my $ref  = {} ;		# hash reference with hash refs as values and the LogicalOrder as keys
		my $ret  = 1 ; 
		my $msg  = "" ; 

		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw , 
			{AutoCommit=>1,RaiseError=>1,PrintError=>1});
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;

		
      my $sql = ' 
		SELECT 
		   ItemView.ItemViewId       
		 , ItemView.Level
		 , ItemView.SeqId
		 , ItemView.doGenerateUi      
		 , ItemView.Name             
		 , ItemView.Description      
		 , ItemView.BranchId
		 , ItemView.doGenerateUi
		 , ItemView.doGeneratePdf
		 , ItemView.doGenerateLeftMenu
		 , ItemView.ItemControllerId 
		 , ItemView.Type

		 , ItemController.ItemControllerId  
		 , ItemController.doTruncTable      
		 , ItemController.doLoadData        
		 , ItemController.Sheet             
		 , ItemController.Description       
		 , ItemController.IsBook

		 , ItemModel.ItemModelId      
		 , ItemModel.TableNameLC      
		 , ItemModel.TableName        
		 , ItemModel.IsItem
		 , ItemModel.ItemControllerId 


		FROM ' . "$db" . '.' . 'ItemView
		INNER JOIN ItemController 	ON ( ItemView.ItemControllerId = ItemController.ItemControllerId  ) 
		INNER JOIN ItemModel 		ON ( ItemController.ItemControllerId = ItemModel.ItemControllerId ) 
		WHERE 1=1
		AND ItemView.doGenerateUi = 1
		AND ItemController.IsBook = 1
		ORDER BY ItemView.SeqId ASC
		' ;


		if ( $IsUnitTest == 1 or $module_trace == 1) {	
			$msg 		= "running the following sql: " ; 
			$objLogger->debug ( "$msg" )  ; 
			$msg 		= $sql ; 
			$objLogger->debug ( "$msg" ) ; 
		}

      my $sth  = $dbh->prepare("$sql" )   ; 

      $sth->execute() or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ; 

		# the keys for the hash refs are the values in the SeqId field
      $ref = $sth->fetchall_hashref('ItemViewId') or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ; 
      
      $dbh->disconnect;
		
      return $ref ; 
                
   } 
   #eof sub doLoadAppPagesData

   #
   # ------------------------------------------------------
   # get the item's view data 
   # ------------------------------------------------------
   sub doGetItemViews {
      
      my $self 		= shift ; 

		my $db 			= $objController->param('db') 	|| $app_config->{'database'} ; 
		$db = $self->get('Db') if $self->get('Db') ; 

      my $ref  = {} ;		# hash reference with hash refs as values and the LogicalOrder as keys
		my $ret  = 1 ; 
		my $msg  = "" ; 

		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw , 
			{AutoCommit=>1,RaiseError=>1,PrintError=>1});
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;

		
      my $sql = ' 
		SELECT 
		   ItemView.ItemViewId       
		 , ItemView.Level
		 , ItemView.SeqId
		 , ItemView.doGenerateUi      
		 , ItemView.Name             
		 , ItemView.Description      
		 , ItemView.BranchId
		 , ItemView.doGenerateUi
		 , ItemView.doGeneratePdf
		 , ItemView.doGenerateLeftMenu
		 , ItemView.ItemControllerId 
		 , ItemView.Type

		 , ItemController.ItemControllerId  
		 , ItemController.doTruncTable      
		 , ItemController.doLoadData        
		 , ItemController.Sheet             
		 , ItemController.Description       
		 , ItemController.IsBook

		 , ItemModel.ItemModelId      
		 , ItemModel.TableNameLC      
		 , ItemModel.TableName        
		 , ItemModel.IsItem
		 , ItemModel.ItemControllerId 


		FROM ' . "$db" . '.' . 'ItemView
		INNER JOIN ItemController 	ON ( ItemView.ItemControllerId = ItemController.ItemControllerId  ) 
		INNER JOIN ItemModel 		ON ( ItemController.ItemControllerId = ItemModel.ItemControllerId ) 
		WHERE 1=1
		AND ItemView.doGenerateUi = 1
		ORDER BY ItemView.SeqId ASC
		' ;

		# AND ItemController.IsBook = 1

		if ( $IsUnitTest == 1 or $module_trace == 1) {	
			$msg 		= "running the following sql: " ; 
			$objLogger->debug ( "$msg" )  ; 
			$msg 		= $sql ; 
			$objLogger->debug ( "$msg" ) ; 
		}

      my $sth  = $dbh->prepare("$sql" )   ; 

      $sth->execute() or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ; 

		# the keys for the hash refs are the values in the SeqId field
      $ref = $sth->fetchall_hashref('ItemViewId') or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ; 
      
      $dbh->disconnect;
		
		#ok print "MariaDbHanlder:: objItem->Page " . $objItem->get('Page' ) ; 	
		#ok sleep 4 ; 
		#
#		if ( $module_trace == 1 ) {
#			use Data::Printer ; 
#			p($ref)  ; 
#			print "MariaDbHandler::" . $objItem->dumpFields();
#		}
		$objController->stash ('RefItemViews' , $ref);
      return $ref ; 
                
   } 
   #eof sub doGetItemViews
   
	
	#
   # -----------------------------------------------------------------------------
   # gets all from an item table ( has to have the LogicalOrder attribute
   # -----------------------------------------------------------------------------
	sub doSearchNamesAndDescriptions {

      my $self 		      = shift ; 
      my $str_to_srch      = shift ; 
		# params
		my $db 					= $objController->param('db') 	|| $app_config->{'database'} ; 
		my $refItemViews     = $objController->app->getAppStructureData ( \$objController, $db ) ; 

		my $ret			      = () ; 
		my $msg 			      = () ;

		$str_to_srch      =~ s/\s+/%/g ; 
		$str_to_srch		=~ s/^\s+//;
		$str_to_srch		=~ s/\s+$//;
		$str_to_srch      =~ s/\'/\'\'/g ; 
		$str_to_srch      =~ s/\'/\'\'/g ; 
		# set to search for anything redicilous if the user just hits enter ... 
		$str_to_srch 		= '¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤' unless $str_to_srch ; 
		$str_to_srch 		= '¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤' unless length ($str_to_srch) > 0 ; 
		#debug print "\n mariadbhandler str_to_srch: " . $str_to_srch . "\n" ; 
		
		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw , 
			{AutoCommit=>1,RaiseError=>1,PrintError=>1});
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		my $ran_tables = {} ; 
		my $sql = '' ; 	

      foreach my $key ( sort ( keys(%{$refItemViews}) ) ) {
         #$refItemViews->{"$key"}->{'TableName'} ; 
         my $TableName = $refItemViews->{"$key"}->{'TableName'} ; 
         my $page = $refItemViews->{"$key"}->{'Name'} ; 
			$page =~ s/'/''/g ; 
         my $TableNameLC= $refItemViews->{"$key"}->{'TableNameLC'} ; 
			my $Level 		= $refItemViews->{"$key"}->{'Level' } ; 
			#obsolete ?!
			my $title		= $refItemViews->{"$key"}->{'Name' } ; 
			my $item_view_type		= $refItemViews->{"$key"}->{'Type' } ; 

			$title =~ s/'/''/g ; 

			# the 0 level are not really items ...
			#next if $Level == 0 ; 
			# some bug in the data ... skip the table names with spaces 
			next unless $TableName ; 
			next if ( $TableName =~ m/ /g );
			next if ( exists ( $ran_tables->{ "$TableName"} ) ) ; 
			next if ( $item_view_type eq 'folder' ) ; 
			# we search only item tables 
			# otherwise Left menu gets broken and breaks the whole site after search
			next unless $refItemViews->{"$key"}->{'IsItem' } ; 

         $sql .= 'SELECT ' ; 
			$sql .= "CONCAT ('" . $TableName . "' , CAST( " . $TableName . "Id  AS CHAR ) ) AS SearchId" ; 
         $sql .= ' , ' . "'" . $page . "' AS Page" ; # add the page name
         $sql .= ' , ' . "'" . $title . "' AS Name" ; # add the page name
         $sql .= ' , ' . "'" . $db . "' AS Db" ; # add the page name
         $sql .= ' , ' . "'" . $TableNameLC . "' AS TableNameLC" ; # add the page name
         $sql .= ' , ' . "'" . $TableName . "' AS TableName" ; # add the book name
         $sql .= " , " . $TableName . "Id AS Id" ; # add the doc id
         $sql .= ' , Name AS Name' ; # add the doc id
         $sql .= ' , Description AS Description ' ; # add the doc id
         $sql .= ' , Level AS Level ' ; 
			$sql .= 'FROM ' . $TableName  . ' ' ; 
         $sql .= "WHERE 1=1 " ; 
			$sql .= "AND ( Name LIKE '%" . $str_to_srch . "%' " ; 
			$sql .= "OR Description LIKE '%" . $str_to_srch . "%') " ; 
			# deprecated from the old document model => do not use !!!
			# otherwise a result not found bug occurs
         # $sql .= "AND DocId='" . $doc_id . "' " ;  
         $sql .= 'UNION ALL ' ; 
			$ran_tables->{ "$TableName"} = 1 ; 

		}
		#eof foreach key
      
      $sql =~ s/(.*) UNION ALL/$1/g ; 
		
		$self->doPrintNiceSql ( $sql ) ; 

      #$objLogger->debug ( "search sql : " . $sql ) if $module_trace == 1 ; 

      # foreach Item table do build the union sql
      my $sth = $dbh->prepare( $sql );

		$sth->execute() or $objLogger->error ( "$DBI::errstr" ) ; 
		my $ref = {} ; 
		$ref = $sth->fetchall_hashref('SearchId') or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ;
      #debug $objLogger->debug ("MARIA DB " .  p($ref) ) ; 
		unless ( $sth->rows ) {
			my $hr_in = {
				# Whether or not to print messages to STDOUT and / or STDERR
				  Description =>  'No results found'
				, Id => 1
				, Name => 'ideas'
				, Name => 'No results found'
				, Page => 'idea'
				, SearchId => "Idea9"
				, TableNameLC => "idea"
	  		}; 

	  	$ref->{'Idea9'} = $hr_in ; 

		}
		#eof unless 
		#debug print './doc_pub/lib/DocPub/Model/MariaDbHandler.pm sub doSearchNamesAndDescriptions' . "\n" ; 
		#debug p($ref);
		$objController->stash('doSearchNamesAndDescriptions' , $ref ) ; 

	}
	#eof sub doSearchNamesAndDescriptions


	#
	# ------------------------------------------------------	
	# just a debugging sub to print nicer sql strings in the 
	# ------------------------------------------------------	
	sub doPrintNiceSql {
		my $self = shift ; 
		my $sql 	= shift ; 


		my $nice_sql = $sql ; 
		$nice_sql =~ s/WHERE 1=1 /\nWHERE 1=1 \n/g ; 
		$nice_sql =~ s/FROM /\nFROM /g ; 
		$nice_sql =~ s/ , /\n , /g ; 
		$nice_sql =~ s/UNION ALL /\nUNION ALL \n/g ; 

		my ( $package, $filename, $line ) = caller();
		print "file name: $filename , " . "package: $package" , "line: $line " . "\n\n" ; 
		p( $nice_sql ); 
		print "\n\n" ; 



	}
	#eof sub doTurnIntoNiceSql



	#
   # -----------------------------------------------------------------------------
   # gets all from an item table ( has to have the LogicalOrder attribute
   # -----------------------------------------------------------------------------
	sub doSearchForTag {

      my $self 		      = shift ; 
      my $tag_to_srch      = shift ; 
		# params
		my $db 					= $objController->param('db') 	|| $app_config->{'database'} ; 
		my $refItemViews     = $objController->app->getAppStructureData ( \$objController, $db ) ; 

		my $ret			      = () ; 
		my $msg 			      = () ;

		$tag_to_srch      =~ s/\s+/%/g ; 
		$tag_to_srch		=~ s/^\s+//;
		$tag_to_srch		=~ s/\s+$//;
		$tag_to_srch      =~ s/\'/\'\'/g ; 
		$tag_to_srch      =~ s/\'/\'\'/g ; 
		# set to search for anything redicilous if the user just hits enter ... 
		$tag_to_srch 		= '¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤' unless $tag_to_srch ; 
		$tag_to_srch 		= '¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤' unless length ($tag_to_srch) > 0 ; 
		#debug print "\n mariadbhandler tag_to_srch: " . $tag_to_srch . "\n" ; 
		
		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw , 
			{AutoCommit=>1,RaiseError=>1,PrintError=>1});
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;
		my $ran_tables = {} ; 
		my $sql = '' ; 	

      foreach my $key ( sort ( keys(%{$refItemViews}) ) ) {
         #$refItemViews->{"$key"}->{'TableName'} ; 
         my $TableName = $refItemViews->{"$key"}->{'TableName'} ; 
         my $page = $refItemViews->{"$key"}->{'Name'} ; 
			$page =~ s/'/''/g ; 
         my $TableNameLC= $refItemViews->{"$key"}->{'TableNameLC'} ; 
			my $Level 		= $refItemViews->{"$key"}->{'Level' } ; 
			#obsolete ?!
			my $title		= $refItemViews->{"$key"}->{'Name' } ; 
			my $item_view_type		= $refItemViews->{"$key"}->{'Type' } ; 

			$title =~ s/'/''/g ; 

			# the 0 level are not really items ...
			#next if $Level == 0 ; 
			# some bug in the data ... skip the table names with spaces 
			next unless $TableName ; 
			next if $TableName eq 'Tag' ; 
			next if ( $TableName =~ m/ /g );
			next if ( exists ( $ran_tables->{ "$TableName"} ) ) ; 
			next if ( $item_view_type eq 'folder' ) ; 
			# we search only item tables 
			# otherwise Left menu gets broken and breaks the whole site after search
			next unless $refItemViews->{"$key"}->{'IsItem' } ; 

         $sql .= 'SELECT ' ; 
			$sql .= "CONCAT ('" . $TableName . "' , CAST(" . $TableName . "Id  AS CHAR) ) AS SearchId" ; 
         $sql .= ' , ' . "'" . $page . "' as Page" ; # add the page name
         $sql .= ' , ' . "'" . $title . "' as Name" ; # add the page name
         $sql .= ' , ' . "'" . $db . "' as Db" ; # add the page name
         $sql .= ' , ' . "'" . $TableNameLC . "' as TableNameLC" ; # add the page name
         $sql .= ' , ' . "'" . $TableName . "' as TableName" ; # add the book name
         $sql .= " , TagMap.ItemId as Id" ; # add the doc id
         $sql .= ' , ' . $TableName . '.Name as Name' ; # add the doc id
         $sql .= ' , ' . $TableName . '.Description as Description ' ; # add the doc id
         $sql .= ' , ' . $TableName . '.Level as Level ' ; 

			$sql .= ' FROM Tag ' ; 
			$sql .= " INNER JOIN TagMap ON ( " ; 
			$sql .= " Tag.TagId= TagMap.TagId )" ; 
			$sql .= " INNER JOIN " . $TableName . " ON ( " ; 
			$sql .= " TagMap.ItemName = '" . $TableName . "' AND " ; 
			$sql .= " TagMap.ItemId = " . $TableName . "Id )" ; 

         $sql .= " WHERE 1=1 " ; 
			$sql .= " AND Tag.Name ='" . $tag_to_srch . "' " ; 
			# deprecated from the old document model => do not use !!!
			# otherwise a result not found bug occurs
         # $sql .= "AND DocId='" . $doc_id . "' " ;  
         $sql .= 'UNION ALL ' ; 
			$ran_tables->{ "$TableName"} = 1 ; 

		}
		#eof foreach key
      
      $sql =~ s/(.*) UNION ALL/$1/g ; 
     	
		#debug print 'doc_pub/lib/DocPub/Model/MariaDbHandler.pm sql: ' . "\n" . "$sql" . "\n\n" ; 
      #$objLogger->debug ( "search sql : " . $sql ) if $module_trace == 1 ; 

      # foreach Item table do build the union sql
      my $sth = $dbh->prepare( $sql );

		$sth->execute() or $objLogger->error ( "$DBI::errstr" ) ; 
		my $ref = {} ; 
		$ref = $sth->fetchall_hashref('SearchId') or $objLogger->LogFatalMsg ( "$DBI::errstr" ) ;
      #debug $objLogger->debug ("MARIA DB " .  p($ref) ) ; 
		unless ( $sth->rows ) {
			my $hr_in = {
				# Whether or not to print messages to STDOUT and / or STDERR
				  Description =>  'No results found'
				, Id => 1
				, Name => 'ideas'
				, Name => 'No results found'
				, Page => 'idea'
				, SearchId => "Idea9"
				, TableNameLC => "idea"
	  		}; 

	  	$ref->{'Idea9'} = $hr_in ; 

		}
		#eof unless 

		#debug print './doc_pub/lib/DocPub/Model/MariaDbHandler.pm sub doSearchNamesAndDescriptions' . "\n" ; 
		#debug p($ref);
		$objController->stash('doSearchNamesAndDescriptions' , $ref ) ; 

	}
	#eof sub doSearchForTag


	#
   # -----------------------------------------------------------------------------
   # gets all from an item table ( has to have the LogicalOrder attribute
   # -----------------------------------------------------------------------------
	sub doListFoldersAndDocsTitles {

      my $self 		      = shift ; 
		# params
		my $db 					= $objController->param('db') 	|| $app_config->{'database'} ; 
		my $refItemViews     = $objController->stash('RefItemViews');

		my $ret			      = () ; 
		my $msg 			      = () ;

		# DATA SOURCE NAME
		my $dsn = "dbi:mysql:$db:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw , 
			{AutoCommit=>1,RaiseError=>1,PrintError=>1});
		#debug DBI->trace(2, "debug-mariadb.log");

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;

		#debug print "./doc_pub/lib/DocPub/Model/MariaDbHandler.pm sub doListFoldersTitles \n\n" ; 
		#debug p($refItemViews ); 

		my $sql = '' ; 	

		# note the sorting is performed according the SeqId of the ItemView table
		my @sorted_data_keys = 
			sort { $refItemViews->{$a}{'SeqId'} <=> $refItemViews->{$b}{'SeqId'} } keys %$refItemViews;
      my $TableName = '' ; 

		#debug print "doc_pub/lib/DocPub/Model/MariaDbHandler.pm sub doListFoldersAndDocsTitles \n" ; 
      foreach my $key ( @sorted_data_keys ) {
         #$refItemViews->{"$key"}->{'TableName'} ; 
         $TableName = $refItemViews->{"$key"}->{'TableName'} ; 
         my $page = $refItemViews->{"$key"}->{'Name'} ; 
			my $left_menu_level = $refItemViews->{"$key"}->{'Level'} ; 

			#next unless $left_menu_level == 2 ; 

			$page =~ s/'/''/g ; 
         my $TableNameLC= $refItemViews->{"$key"}->{'TableNameLC'} ; 
			my $Level 		= $refItemViews->{"$key"}->{'Level' } ; 
			my $folder_key	= $key*1000 ; 
			my $itm_ctn_id	= $refItemViews->{"$key"}->{'ItemControllerId' } ;
			#obsolete ?!
			#my $doc_id 		= $refItemViews->{"$key"}->{'doc_id' } ; 

			# some bug in the data ... skip the table names with spaces 
			next if ( $TableName =~ m/ /g );
			next unless ( $TableName ) ; 

         $sql .= 'SELECT ' ; 
			$sql .= "CONCAT ('" . $TableName . "' , CAST(" . $TableName . "Id  AS CHAR) ) AS SearchId" ; 
         #$sql .= ' , DocId ' ; # add the doc id
         $sql .= ' , ' . "'" . $page . "' as Page" ; # add the page name
         $sql .= ' , ' . "'" . $db . "' as Db" ; # add the page name
         $sql .= ' , ' . "'" . $TableNameLC . "' as TableNameLC" ; # add the page name
         $sql .= ' , ' . "'" . $TableName . "' as TableName" ; # add the book name
         $sql .= " , " . $TableName . "Id as Id" ; # add the doc id
         $sql .= ' , Name as Name' ; # add the doc id
         $sql .= ' ,  (' . $folder_key . ' + SeqId) as SeqId' ; # add the sequence id
         $sql .= ' , Level as Level ' ; 
         $sql .= ' , ' . "'" . $itm_ctn_id . "' as ItemControllerId " ; # add the book name
			$sql .= 'FROM ' . $TableName  . ' ' ; 
         $sql .= "WHERE 1=1 " ; 
         $sql .= "AND Level in (0,1) " ; 
         $sql .= "AND " . $TableName . "Id NOT IN ( 0 ) " ; 
         $sql .= 'UNION ALL ' ; 

		}
		#eof foreach key
      
      $sql =~ s/(.*) UNION ALL/$1/g ; 
      $sql 		.= "ORDER BY SeqId " ; 
     	
		#debug print 'doc_pub/lib/DocPub/Model/MariaDbHandler.pm doListFoldersAndTitles sql: ' . "\n $sql" . "\n\n" ; 
	   $objLogger->debug ( "search sql : " . $sql ) if $module_trace == 1 ; 
		

      # foreach Item table do build the union sql
      my $sth = $dbh->prepare( $sql );

		$sth->execute() or $objLogger->error ( "$DBI::errstr" ) ; 

		# populate the array references with hash references 
		my @query_output = () ; 
		while ( my $row = $sth->fetchrow_hashref ){
			 push @query_output, $row;
		} 
		#eof while
		
		#debug print "doc_pub/lib/DocPub/Model/MariaDbHandler.pm sub doListFoldersAndDocsTitles \n" ; 
		#debug p( @query_output );

		#$objController->stash('doListFoldersAndDocsTitles' , $ref ) ; 


		return \@query_output ; 
	}
	#eof sub doListFoldersAndDocsTitles

	#
   # ------------------------------------------------------
   # the backend func for saving the content of the paragrapth
	# after the edit from the view post
   # ------------------------------------------------------
	sub doUpdateItemLevel {

		my $self 					= shift;
		my $promote_id				= shift ; 
		my $demote_id				= shift ; 
		my $db 						= $objController->param('db') ; 
		my $table 					= $objController->param('item');
		my $ret						= 0 ; # assume error 
	
		#return unless ( $promote_id and $demote_id ) ; 
		
		#print "table: $table \n" ; 
		#print "id: $id \n" ; 
		#print "desc: $field_value \n" ; 
		#print "db: $db \n" ; 

		my $sql = '' ; 
		$sql 	.= 'UPDATE ' . '`' . $db . '`.`' . $table . '` SET ' ; 
		
		$sql 	.= "`Level`=(Level -1) "  if ( $promote_id ) ; 
		$sql 	.= "`Level`=(Level +1) "  if ( $demote_id ) ; 
		$sql 	.= "WHERE 1=1 " ; 
		$sql  .= "AND `" . $table . 'Id`' . "='" . $demote_id . "' ; " if ( $demote_id ) ;
		$sql  .= "AND `" . $table . 'Id`' . "='" . $promote_id . "' ; " if ( $promote_id ) ;

		#debug print "sql:: " . $sql . "\n\n" ; 
		my $dsn = "dbi:mysql:mysql:$db_host:$db_port";

		# PERL DBI CONNECT
		my $dbh = DBI->connect($dsn, $db_user, $db_user_pw 
		, { 
			  'RaiseError' => 1 
			, 'PrintError' => 1 
		  }
		);

		# obs 1 the db handle MUST be utf8 aware 
		$dbh->{'mysql_enable_utf8'} = 1;

		$objLogger->debug("MariaDbHandler::doUpdateItemLevel :::\n $sql" );
		#debug print "MariaDbHandler::doUpdateItemLevel sql : $sql \n" ; 
		
		#print "\n\n sql:: $sql \n\n" ; 
		my $sth = $dbh->prepare( "$sql" ) ; 
		$sth->execute () ; 
	
		$dbh->disconnect();	

	}
	#eof sub


   #
   # -----------------------------------------------------------------------------
   # doInitialize the object with the minimum data it will need to operate 
   # -----------------------------------------------------------------------------
   sub doInitialize {

      my $self = shift ; 

		# get the application configuration hash
		$app_config 	= $objController->app->get('AppConfig') ; 
		#debug print "MariaDbHandler::doInitialize app_config : " . p($app_config );

		$objLogger 		= $objController->app->get('ObjLogger');
	   
      $db               = $objController->param( 'db' )  || 'isg_pub_en' ; 	
		$db_host 			= $app_config->{'db_host'} 		|| 'localhost' ;
		$db_port 			= $app_config->{'db_port'} 		|| '13306' ; 
		$db_user 			= $app_config->{'db_user'} 		|| 'doc_pub_app_user' ; 
		$db_user_pw 		= $app_config->{'db_user_pw'} 	|| 'no_pass_provided!!!' ; 
		$web_host 			= $app_config->{'web_host'} 		|| 'localhost' ;

   }
   #eof sub doInitialize


   #
   # -----------------------------------------------------------------------------
   # the constructor 
   # source:http://www.netalive.org/tinkering/serious-perl/#oop_constructors
   # -----------------------------------------------------------------------------
   sub new {

      my $class            = shift ;    # Class name is in the first parameter
		$objController			= ${ ( shift @_ ) } ; 

		my @args 				= ( @_ ); 

      # Anonymous hash reference holds instance attributes
      my $self = { }; 
      bless($self, $class);     # Say: $self is a $class

      $self->doInitialize() ; 
      return $self;
   } 
   #eof const 
	

	# -----------------------------------------------------------------------------
	# return a field's value
	# -----------------------------------------------------------------------------
	sub get {

		my $self = shift;
		my $name = shift;

		return $self->{ $name };
	}    #eof sub get


	# -----------------------------------------------------------------------------
	# set a field's value
	# -----------------------------------------------------------------------------
	sub set {

		my $self  = shift;
		my $name  = shift;
		my $value = shift;
		$self->{ "$name" } = $value;
	}
	# eof sub set
	
1;


__END__


=head1 NAME

MariaDbHandler

=head1 SYNOPSIS

use DocPub::Model::MariaDbHandler
  
=head1 DESCRIPTION


=head2 EXPORT


=head1 SEE ALSO

  perldoc perlvars

  No mailing list for this module


=head1 AUTHOR

  yordan.georgiev@gmail.com

=head1 COPYRIGHT LICENSE

  Copyright (C) 2015 Yordan Georgiev

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.8.1 or,
  at your option, any later version of Perl 5 you may have available.

=cut


# 
# -----------------------------------------------------------------------------
# --  VersionHistory
# -----------------------------------------------------------------------------
#
#
# 1.0.1 -- 2015-08-28 14-22-24 -- ysg -- refactoring , mod init
# 1.0.0 -- 2015-08-24 13-22-44 -- ysg -- initial version 
#
#
# eof file: doc_pub/lib/DocPub/Model/MariaDbHandler.pm
