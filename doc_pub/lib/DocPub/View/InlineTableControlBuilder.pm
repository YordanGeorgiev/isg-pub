package DocPub::View::InlineTableControlBuilder ; 

	use strict ; use diagnostics ; 
	use utf8 ; 

	our %EXPORT_TAGS = ( 'all' => [ qw() ] );
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
	our @EXPORT = qw() ; 
	use Data::Printer ; 

	use DocPub::View::HtmlHandler ; 
	use DocPub::View::LinkBuilder ; 


	#
	# ----------------------------------------------------------------------------
	# vars
	# -----------------------------------------------------------------------------
	our $ModuleDebug				= 0 ; 
	our $confHolder 				= {} ; 
	our $refObjItem				= {} ; 
	our $objController			= {} ; 
	our @langs 						= () ; 
	our $objLogger					= q{} ; 
	our $app_config				= () ; 
	

   #
   # ------------------------------------------------------
   # builds the html for the top menu
   # ------------------------------------------------------
   sub doBuildControl {

      my $self                 = shift ; 
      my $row				 		 = shift ; 
		my $refInlineTables 		 = shift ; 
		my $str_inline_table  	 = '' ; 

		#p($refInlineTables);

		$str_inline_table			.= '<div class="inline_table_holder">'  ;
		$str_inline_table			.= "\t" . '<table id="" class="inline_table" width="100%">' ; 
		$str_inline_table			.= "\t" . '<thead>' ; 
		# $str_inline_table			.= "start" ; 
		# debug $str_inline_table			.= p($refInlineTables); 	
		my $hsTInlineTable		 = $self->toRegularTable ( $refInlineTables ) ; 
		# $str_inline_table     .= p( $hsTInlineTable ) ; 

		my $c = 0 ; 
		my $hsHeaders = {} ; 
	   
      # obs what happens if the keys are not numerical ?!
      foreach my $row_id ( sort { $a <=> $b }  ( keys ( %$hsTInlineTable ) ) ) {
			
			my $css_class = 'even' ; 
			$css_class = ' class="odd"' if $row_id % 2 == 1 ; 
			$css_class = ' class="even"' if $row_id % 2 == 00 ; 

			my $hsTRow					 = $hsTInlineTable->{ $row_id } ; 
			# set the correct order of the columns 
			if ( $c == 0 ) {
				foreach my $column_name ( sort ( keys ( %$hsTRow) ) ) {
					$hsHeaders->{ $column_name } = $hsTRow->{ $column_name } ; 
				}
				$c = $c + 1 ; next ; 
			}
			next if ( $c == 0 ) ; 

			if ( $c == 1 ) {
				foreach my $col_id ( sort ( keys ( %$hsHeaders) ) ) {
					my $column_name 			 = $hsHeaders->{ $col_id } ; 
					$str_inline_table			.= "\t" . '<th>' ; 
					my $cell_value				 = $column_name ; 
					$str_inline_table			.= "$cell_value" ; 
					$str_inline_table			.= "\t" . '</th>' ; 
				}
			}
			$str_inline_table			.= "\t" . '</thead>' ; 

			$str_inline_table			.= "\t" . '<tr' . "$css_class" . '>' ; 
			foreach my $col_id ( sort ( keys ( %$hsHeaders ) ) ) {
				my $column_name 			 = $hsHeaders-> { $col_id } ; 
				$str_inline_table			.= "\t" . '<td>' ; 
				my $cell_value				 = $hsTRow->{ $column_name } || ' ' ; 
				$cell_value = ' ' if $cell_value eq 'NULL' ; 
				$cell_value = text2html( $cell_value ) ; 
				$str_inline_table			.= "$cell_value" ; 
				$str_inline_table			.= "\t" . '</td>' ; 
			}
			#eof foreach column_name 
			$str_inline_table			.= "\t" . '</tr>' ; 
			$c = $c+1 ; 
		} #eof foreach row_id

		# debug $str_inline_table			.= "stop" ; 
		$str_inline_table			.= "\t" . '</table>' ; 
		$str_inline_table			.= '</div><!-- eof id="inline_table" -->'  ;
		
      return $str_inline_table ; 

   }
   #eof sub doBuildControl

	
   #
   # -----------------------------------------------------------------------------
   # this will transpose the hash into a run-time table like hash
   # -----------------------------------------------------------------------------
	sub toRegularTable {

		my $self 					= shift ; 
		my $refInlineTables 		= shift ; 
		my $hsTInlineTable 		= {} ; 
		my $hsTRow				 	= {} ; 
		
		foreach my $cell_value_id ( sort ( keys ( %$refInlineTables ) ) ) {
			my $hsRow				 	= $refInlineTables->{$cell_value_id} ; 
			my $curr_row_id 		 	= $hsRow->{ 'RowId' } ; 
			$hsTRow					 	= $hsTInlineTable->{$curr_row_id} ; 
			$hsTRow = {} unless ( $hsRow ) ; 
			
			my $ColumnName			 	= $hsRow->{ 'ColumnName' } ; 
			my $CellValue			 	= $hsRow->{ 'CellValue' } ; 
			$hsTRow->{$ColumnName} 	= $CellValue ; 

			$hsTInlineTable->{$curr_row_id} = $hsTRow ; 

		}
		#eof foreach cell_value_id
		#
		
		return $hsTInlineTable ; 
	}
	#eof sub toRegularTable 


   #
   # -----------------------------------------------------------------------------
   # doInitialize the object with the minimum data it will need to operate 
   # -----------------------------------------------------------------------------
   sub doInitialize {

      my $self = shift ; 
		
		# get the application configuration hash
		# get the application configuration hash
		# global app config hash
		$app_config 	= $objController->app->get('AppConfig') ; 
		$objLogger 		= $objController->app->get('ObjLogger') ;

   }
   #eof sub doInitialize


   #
   # -----------------------------------------------------------------------------
   # the constructor 
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

	
	#
	# -----------------------------------------------------------------------------
	# return a field's value to a calling super class object
	# -----------------------------------------------------------------------------
	sub getSubClassVar {

		my $self 	= shift;
		my $name 	= shift;
		return $self->get($name);
	}    
	#eof sub get
	



1;
__END__
