package DocPub::Model::RsToXlsConverter; 

   use strict ; 
   use warnings ; 

   require Exporter; 
   use AutoLoader ; 

	use utf8 ; 
	use Encode ; 

	use Data::Printer ; 
	use Carp ; 
	use Spreadsheet::WriteExcel;
	use Spreadsheet::ParseExcel ; 
	use Spreadsheet::ParseExcel::Cell ; 


   our $ModuleDebug           = 0 ; 
   our $IsUnitTest            = 0 ; 
	our $objController 			= {} ; 
	our $objLogger					= q{} ;
	our $app_config				= q{} ;


   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub doConvert {

		my $self 			= shift ;
		my $db 				= shift ; 
		my $table 			= shift ;
		my $rs_meta 		= shift ; 
		my $rs				= shift ; 
		my $id				= $objController->param('branch-id') || $objController->param('path-id') || 1 ; 
		
		unless ( $rs_meta or $rs ) {
			return ; 
		}

		# Create a new Excel workbook
		my $project_version_dir 		= $app_config->{'ConfDir'} ; 
		$project_version_dir 			=~ s/(.*)(\/)(.*)/$1/g ; 
		my $xls_dir 						= $project_version_dir . "/doc_pub/public/data/xls/" . $db  ; 
		
		print "RsToXlsConverter:: doConvert xls_dir" . $xls_dir ; 
		
		$xls_dir = '/tmp' ; 
		my $file = "$xls_dir/" . $db . '.' . "$table" . '.' . $id . '.xls' ; 
		my $objWorkBook = Spreadsheet::WriteExcel->new( $file );
		

		$objWorkBook->set_properties(
				title    => 'Export from the ' . $db . ' db, ' . $table . ' table ' . ' id ' . $id ,
				subject  => 'Export from the ' . $db . ' db, ' . $table . ' table ' . ' id ' . $id ,
				author   => 'doc-pub export',
				comments => 'Created with Perl and Spreadsheet::WriteExcel',
		);

	
		# Add a worksheet
		my $objWorkSheet = $objWorkBook->add_worksheet( $table );
		
		# start -- building the header 
		my $col 					= 0 ; 
		my $row_num 			= 0 ; 
		my @char_datatypes 	= qw ( varchar char );
		my $i						= 1 ; 
		
		# build the header
		foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
			my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
			$column_name =~ s/ /_/g ; 
			my $data_type = $rs_meta->{$i}->{'DATA_TYPE'} ; 
			# use also the format
			#$worksheet->write($row, $col, 'Hi Excel!', $format);
			$objWorkSheet->write($row_num , $col, $column_name );
			
			$i++ ;
			$col++ ; 
		}
		# stop  -- building the header 
	

		# start -- building the body 
		#p($rs ) ; 
		$row_num 	= 1 ; 

		# Set a Unicode font.
		my $uni_font  = $objWorkBook->add_format(font => 'Arial Unicode MS');
		my $hs_seq_logical_order   = $self->doBuildLogicalOrderHash( $table , $rs )  ;
		my $hs_seq_hours           = $self->doBuildHoursSubTotals( $table , $rs )  ;


		foreach my $row ( @$rs )  {
			my $col_num = 0 ; 
			my $i = 1 ; 	
			foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
			
				my $column_name 	= $rs_meta->{$i}->{'COLUMN_NAME'} ; 
				my $data_type 		= $rs_meta->{$i}->{'DATA_TYPE'} ; 

				my $cell = '' ; 
				$cell = $row->{"$column_name"} ; 

		      $rs_meta->{$i}->{'MAX_WIDTH'} = 5 
               unless ( defined ( $rs_meta->{$i}->{'MAX_WIDTH'} )) ; 	

            my $cell_width = length $cell || 5 ; 
            $rs_meta->{$i}->{'MAX_WIDTH'} = $cell_width 
               if ( $cell_width > $rs_meta->{$i}->{'MAX_WIDTH'} ) ; 

				if ( $data_type eq 'datetime' ) {
		         my $str_date_format = 'yyyy-mm-dd hh:mm:ss' ; 
		         my $date_format =  
                  $objWorkBook->add_format( 
                     num_format => $str_date_format
                   , align  => 'left'
                   , font => 'Arial Unicode MS'
                  );
               $date_format->set_bg_color('silver') if $row_num % 2 == 0 ; 
               $date_format->set_bg_color('white') if $row_num % 2 != 0 ; 
					$objWorkSheet->write_date_time($row_num, $col_num , $cell , $date_format);
				}
				elsif ( $data_type eq 'int' or $data_type eq 'bigint' ) {
 		         my $whole_num_format = $objWorkBook->add_format(
                     align  => 'right'
                   , font => 'Arial Unicode MS'
               );
     		      $whole_num_format->set_align('right');
	            $whole_num_format->set_num_format('# ##0');
               $whole_num_format->set_bg_color('silver') if $row_num % 2 == 0 ; 
               $whole_num_format->set_bg_color('white') if $row_num % 2 != 0 ; 

					$objWorkSheet->write_number($row_num, $col_num , $cell , $whole_num_format );
				}
				elsif ( $data_type eq 'char' or $data_type eq 'varchar' or $data_type eq 'text') {
 		         my $txt_format = $objWorkBook->add_format(
                     align  => 'left'
                   , font => 'Arial Unicode MS'
               );
			      $txt_format->set_text_wrap();
					$cell =~ s/\r//gm ; 
               $txt_format->set_bg_color('silver') if $row_num % 2 == 0 ; 
               $txt_format->set_bg_color('white') if $row_num % 2 != 0 ; 

               # the logical order is actually generated during run-time
               if ( $column_name eq 'LogicalOrder' ) {
					   my $id				   = $row->{ $table . 'Id' } ; 
					   my $logical_order		= $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } || '' ; 
                  $logical_order =~ s/^\s+|\s+$//g ; 
                  $logical_order =~ s/^(.*)([\.0]{1,7})$/$1./g;
                  my $cell        = $logical_order ; 
               }
               # the logical order is actually generated during run-time
               if ( $column_name eq 'Hours' ) {
					   my $id				   = $row->{ $table . 'Id' } ; 
					   my $level_hours		= $hs_seq_logical_order->{ $id }->{ 'Hours' } || 0 ; 
                  my $cell        = $level_hours ; 
               }
					$objWorkSheet->write_string($row_num, $col_num , $cell , $txt_format );
				}
				else {
 		         my $default_format = $objWorkBook->add_format(
                     align  => 'left'
                   , font => 'Arial Unicode MS'
               );
					$cell =~ s/\r//gm ; 
               $default_format->set_bg_color('silver') if $row_num % 2 == 0 ; 
               $default_format->set_bg_color('white') if $row_num % 2 != 0 ; 
			      $default_format->set_text_wrap();
					$objWorkSheet->write($row_num , $col_num , $cell , $default_format );
				}

				$col_num++ ;
				$i++ ;
			}
			$row_num++ ; 
		}
		# stop -- building the header 
		
		foreach my $i( sort ( keys ( %$rs_meta ) )  ) {
         my $width = $rs_meta->{ $i }->{ 'MAX_WIDTH' } ;  
	      $objWorkSheet->set_column($i, $i, $width) if $width;
		}

	 	$objWorkBook->close();

		# The Excel file in now in $str. Remember to binmode() the output
		# filehandle before printing it.
		binmode STDOUT;
		
		return $file ; 

	}
	#eof sub doConvertTableToSheet
	
   
   sub doBuildHoursSubTotals { 
		
		my $self 						= shift  ;
		my $item_name 					= shift ; 
		my $rs 							= shift ; 
		my $start_upper_level		= shift || 0 ; 

		my $item_id_name				= $item_name . "Id" ;  
		my $hs_seq_logical_order	= {} ; 
		my $logical_order				= '1' ; 
		my $level_count				= '0' ; 	
		my $hs_level_counts			= {} ; 
		my $hs_level_hours			= {} ; 
		my $prev_level_num			= 0 ; 
		my $prev_row_id			   = 0 ; 
		my $prev_row 				   = {} ; 

		@$rs = sort { $a->{ 'SeqId' } <=> $b->{ 'SeqId' } } @$rs;
		my $rowc	= 0 ; 
		# ---
		# fill first the level counts
		foreach my $row ( @$rs )  {

			# set the id as the key to the logical hash
			my $id  = $row->{ $item_id_name } || $start_upper_level ; 
			$prev_level_num = $prev_row->{'Level'} || 0 ; 

			$hs_seq_logical_order->{ $id } = {} ; 
			$hs_seq_logical_order->{ $id }->{'Id'} = $id ; 
			

			my $level_num 	= $row->{ 'Level' } ; 

			my $start_num = 0 ; 
			# only the first visible level starts at 1
			$start_num 	= 0 if $row->{ 'Level' } == 2 ; 
			
			$hs_level_counts->{ $level_num } = $start_num 
				unless ( $hs_level_counts->{ $level_num } ) ; 
			
			#old if ( $row->{'Level'} == 1 ) {
			if ( $rowc == 0 ) {
				my $current_level = $row->{'Level'} ; 
				my $current_nxt_level = $row->{'Level'} ; 
				$hs_level_counts->{ $current_level } = 0 ; 
				$hs_level_counts->{ $current_nxt_level } = 0 ; 
				$rowc++ ;
				next  ;
			}


			if ( $level_num == $prev_level_num ) {
				my $prev_level_count = $hs_level_counts->{ $level_num } ; 
				# print "\$prev_level_count ::: $prev_level_count \n" ; 
				my $curr_level_count = $prev_level_count + 1 ;
				$hs_level_counts->{ $level_num } = $curr_level_count ; 
				$hs_level_hours->{ $level_num - 1 } += $row->{'Hours'}

			}
			if ( $level_num < $prev_level_num ) {
				#$hs_level_counts->{ $level_num } = $start_num  ; 
				$self->doResetAllSubordinateLevelsForHours ( $hs_level_counts , $level_num ) ;
				my $prev_level_count = $hs_level_counts->{ $level_num } ; 
				# print "\$prev_level_count ::: $prev_level_count \n" ; 
				my $curr_level_count = $prev_level_count + 1 ;
				$hs_level_counts->{ $level_num } = $curr_level_count ; 
			}
			if ( $level_num > $prev_level_num ) {
				my $prev_level_count = $hs_level_counts->{ $level_num } ; 
				# print "\$prev_level_count ::: $prev_level_count \n" ; 
				my $curr_level_count = $prev_level_count + 1 ;
				$hs_level_counts->{ $level_num } = $curr_level_count ; 
				$hs_level_counts->{ $level_num + 1 } = $start_num ; 
			}

			my %copy_of_hs_level_counts = %$hs_level_counts ; 
			$hs_seq_logical_order->{ $id }->{ 'HsLevelCounts' } = \%copy_of_hs_level_counts ; 


			#debug ok print "ok --- level_num ::: " . $level_num . "\n" ; 
			$prev_row_id = $id ; 
			$prev_row	 = $row ; 
			$rowc++ ; 
		}
		#eof foreach my $i

		# ---
		# build than the logical orders based on filled already level counts 
		# the $row is just a hash reference
		foreach my $row ( @$rs )  {
			# get the id as the key to the logical hash
			my $id  = $row->{ $item_id_name } || 0 ; 
			my $hs_i = $hs_seq_logical_order->{ $id }->{'HsLevelCounts'} ;
			#debug p($hs_i);

			foreach my $key ( sort ( keys ( %$hs_i ) )) {
				#debug print "hs_i key is " . $key . "\n" ; 

				my $post_dot_maybe			= '.' ; 
				$post_dot_maybe 				= '' if $key == 1 ; 

				my $curr_level_count = '' ; 
				$curr_level_count		= $hs_i->{ $key } 
					if ( $hs_i->{ $key } and $key != 1  ) ; 
				$post_dot_maybe 				= '' unless $curr_level_count ; 

				#$curr_level_count		= '' 
				#	if ( $curr_level_count == 0 and $key == 1 ) ; 
				if ( $key > 2 ) {				
					my $logical_order = $hs_seq_logical_order->{ $id }->{ 'Hours' } ; 
					$logical_order  =~ s/(.*)\.\.\./$1/g ; 
					$logical_order  .= 
						$curr_level_count . $post_dot_maybe ; 
					$hs_seq_logical_order->{ $id }->{ 'Hours' } = $logical_order ; 
				}
				else {
					$hs_seq_logical_order->{ $id }->{ 'Hours' } =
						$curr_level_count . $post_dot_maybe ; 
				}
				#debug print "logical order is " . $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } . "\n" ;  
			}
			#eof foreach my $key
		}
		#eof foreach my $i

		return $hs_seq_logical_order ; 
	} 
	#eof sub doBuidHoursSubTotals
   
	#
   # -----------------------------------------------------------------------------
	# clear the logical numbers from the node id passed and set to 0
   # -----------------------------------------------------------------------------
	sub doResetAllSubordinateLevelsForHours {

		my $self 						= shift ; 
		my $hs_level_counts		 	= shift ; 
		my $current_level				= shift ; 

		
		for ( my $level = 0 ;$level < 20; $level++ ) {
			next if $level <= $current_level  ; 
			$hs_level_counts->{ $level } = 0 ; 
		}
	
		#debug print "DocBuilder:: doResetAllSubordinateLevels" ; 
		#debug p($hs_level_counts);

	}
	#eof sub doResetAllSubordinateLevelsForHours

	#
   # -----------------------------------------------------------------------------
	# the numbering of the view page comes from here ...
	# call by doBuildLogicalOrderHash ( $item_name , $rs ) ; 
   # -----------------------------------------------------------------------------
	sub doBuildLogicalOrderHash { 
		
		my $self 						= shift  ;
		my $item_name 					= shift ; 
		my $rs 							= shift ; 
		my $start_upper_level		= shift || 0 ; 

		my $item_id_name				= $item_name . "Id" ;  
		my $hs_seq_logical_order	= {} ; 
		my $logical_order				= '1' ; 
		my $level_count				= '0' ; 	
		my $hs_level_counts			= {} ; 
		my $prev_level_num			= 0 ; 
		my $prev_row_id			= 0 ; 
		my $prev_row 				= {} ; 

		@$rs = sort { $a->{ 'SeqId' } <=> $b->{ 'SeqId' } } @$rs;
		my $rowc	= 0 ; 
		# ---
		# fill first the level counts
		foreach my $row ( @$rs )  {

			# set the id as the key to the logical hash
			my $id  = $row->{ $item_id_name } || $start_upper_level ; 
			$prev_level_num = $prev_row->{'Level'} || 0 ; 

			$hs_seq_logical_order->{ $id } = {} ; 
			$hs_seq_logical_order->{ $id }->{'Id'} = $id ; 
			

			my $level_num 	= $row->{ 'Level' } ; 

			my $start_num = 0 ; 
			# only the first visible level starts at 1
			$start_num 	= 0 if $row->{ 'Level' } == 2 ; 
			
			$hs_level_counts->{ $level_num } = $start_num 
				unless ( $hs_level_counts->{ $level_num } ) ; 
			
			#old if ( $row->{'Level'} == 1 ) {
			if ( $rowc == 0 ) {
				my $current_level = $row->{'Level'} ; 
				my $current_nxt_level = $row->{'Level'} ; 
				$hs_level_counts->{ $current_level } = 0 ; 
				$hs_level_counts->{ $current_nxt_level } = 0 ; 
				$rowc++ ;
				next  ;
			}


			if ( $level_num == $prev_level_num ) {
				my $prev_level_count = $hs_level_counts->{ $level_num } ; 
				# print "\$prev_level_count ::: $prev_level_count \n" ; 
				my $curr_level_count = $prev_level_count + 1 ;
				$hs_level_counts->{ $level_num } = $curr_level_count ; 

			}
			if ( $level_num < $prev_level_num ) {
				#$hs_level_counts->{ $level_num } = $start_num  ; 
				$self->doResetAllSubordinateLevels ( $hs_level_counts , $level_num ) ;
				my $prev_level_count = $hs_level_counts->{ $level_num } ; 
				# print "\$prev_level_count ::: $prev_level_count \n" ; 
				my $curr_level_count = $prev_level_count + 1 ;
				$hs_level_counts->{ $level_num } = $curr_level_count ; 
			}
			if ( $level_num > $prev_level_num ) {
				my $prev_level_count = $hs_level_counts->{ $level_num } ; 
				# print "\$prev_level_count ::: $prev_level_count \n" ; 
				my $curr_level_count = $prev_level_count + 1 ;
				$hs_level_counts->{ $level_num } = $curr_level_count ; 
				$hs_level_counts->{ $level_num + 1 } = $start_num ; 
			}

			my %copy_of_hs_level_counts = %$hs_level_counts ; 
			$hs_seq_logical_order->{ $id }->{ 'HsLevelCounts' } = \%copy_of_hs_level_counts ; 


			#debug ok print "ok --- level_num ::: " . $level_num . "\n" ; 
			$prev_row_id = $id ; 
			$prev_row	 = $row ; 
			$rowc++ ; 
		}
		#eof foreach my $i

		# ---
		# build than the logical orders based on filled already level counts 
		# the $row is just a hash reference
		foreach my $row ( @$rs )  {
			# get the id as the key to the logical hash
			my $id  = $row->{ $item_id_name } || 0 ; 
			my $hs_i = $hs_seq_logical_order->{ $id }->{'HsLevelCounts'} ;
			#debug p($hs_i);

			foreach my $key ( sort ( keys ( %$hs_i ) )) {
				#debug print "hs_i key is " . $key . "\n" ; 

				my $post_dot_maybe			= '.' ; 
				$post_dot_maybe 				= '' if $key == 1 ; 

				my $curr_level_count = '' ; 
				$curr_level_count		= $hs_i->{ $key } 
					if ( $hs_i->{ $key } and $key != 1  ) ; 
				$post_dot_maybe 				= '' unless $curr_level_count ; 

				#$curr_level_count		= '' 
				#	if ( $curr_level_count == 0 and $key == 1 ) ; 
				if ( $key > 2 ) {				
					my $logical_order = $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } ; 
					$logical_order  =~ s/(.*)\.\.\./$1/g ; 
					$logical_order  .= 
						$curr_level_count . $post_dot_maybe ; 
					$hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } = $logical_order ; 
				}
				else {
					$hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } =
						$curr_level_count . $post_dot_maybe ; 
				}
				#debug print "logical order is " . $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } . "\n" ;  
			}
			#eof foreach my $key
		}
		#eof foreach my $i

		return $hs_seq_logical_order ; 
	} 
	#eof sub doBuildLogicalOrderHash
   
	#
   # -----------------------------------------------------------------------------
	# clear the logical numbers from the node id passed and set to 0
   # -----------------------------------------------------------------------------
	sub doResetAllSubordinateLevels {

		my $self 						= shift ; 
		my $hs_level_counts		 	= shift ; 
		my $current_level				= shift ; 

		
		for ( my $level = 0 ;$level < 20; $level++ ) {
			next if $level <= $current_level  ; 
			$hs_level_counts->{ $level } = 0 ; 
		}
	
		#debug print "DocBuilder:: doResetAllSubordinateLevels" ; 
		#debug p($hs_level_counts);

	}
	#eof sub doResetAllSubordinateLevels

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
		$objLogger 		= $app_config->{'ObjLogger'} ;

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
	
	

	
1;


__END__


=head1 NAME

NiceTableBuilder

=head1 SYNOPSIS

use DocPub::View::NiceTableBuilder ; 
  
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
# VersionHistory
# -----------------------------------------------------------------------------
#
# 1.0.0 -- 2015-08-24 13-22-44 -- ysg -- initial version 
#
