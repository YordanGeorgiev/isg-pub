package DocPub::Model::RsToGitHubMdConverter; 

   use strict ; 
   use warnings ; 

   require Exporter; 
   use AutoLoader ; 

	use utf8 ; 
	use Encode ; 

	use Data::Printer ; 
	use File::Path ; 
	use Carp qw(cluck croak);
	use Carp ; 


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
		my $rs_images		= shift ; 

		my $id				= $objController->param('branch-id') || $objController->param('path-id') || 1 ; 
		my $hs_seq_logical_order = $self->doBuildLogicalOrderHash ( $table , $rs ) ; 		
		unless ( $rs_meta or $rs ) {
			return ; 
		}

		# Create a new Excel workbook
		my $project_version_dir 		= $app_config->{'ConfDir'} ; 
		$project_version_dir 			=~ s/(.*)(\/)(.*)/$1/g ; 
		my $githubmd_dir 						= '' ; 
		my $str_response					= '' ; 
	   
      # jump back	
      my $str_toc = $self->doBuildTOC ( $rs_meta , $rs ) ; 
		#debug print "RsToGitHubMdConverter:: doConvert githubmd_dir" . $githubmd_dir ; 
		
		$githubmd_dir = '/tmp' ; 
		my $file = "$githubmd_dir/" . $db . '.' . "$table" . '.' . $id . '.README.md' ; 
		
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
			
			$i++ ;
			$col++ ; 
		}
		# stop  -- building the header 
	

		# start -- building the body 
		# debug  p($rs ) ; 
		$row_num 	= 1 ; 


		foreach my $row ( @$rs )  {
			my $col_num = 0 ; 
			my $i = 1 ; 	
			my $logical_order = ' ' ; 
			my $id = 0 ; 			

			foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
				my $column_name 	= $rs_meta->{$i}->{'COLUMN_NAME'} ; 
				my $meta_id = $table . 'Id' ; 

				if ( $column_name eq $meta_id ) {
					$id = $row->{ $meta_id }  ; 
					$logical_order	= $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } || '' ; 


				}
				if ( $column_name eq 'Name' ) {
					my $h_syntax = '' ; 
					for ( my $h = 1 ; $h <= $row->{'Level'} ; $h++ ) {
						$h_syntax .= '#' ; 
					}
						$h_syntax .= ' ' . $logical_order . ' ' ; 
						my $cell 		= $row->{ 'Name' } ; 
						$cell =~ s/</&lt;/g ; 
						$cell =~ s/>/&gt;/g ; 

						$str_response .= $h_syntax . $cell ; 
						$str_response .= "\n" ; 
                  
                  # add the table of contents if this is the Level 1
                  $str_response .= $str_toc  if $row->{'Level'} == 1 ; 
				}
				if ( $column_name eq 'Description' ) {
					my $cell 		= $row->{ 'Description' } ; 
					$cell =~ s/</&lt;/g ; 
					$cell =~ s/>/&gt;/g ; 

               # convert all the relative paths as md lins as well
               $cell =~ s! ((\.\.\/){0,1}([a-zA-Z0-9_\-\/\\]*)[\/\\]([a-zA-Z0-9_\-]*)\.([a-zA-Z0-9]*)) ! [$3]($1) !gm ; 

					$str_response .= $cell ;
					$str_response .= "\n\n" ; 

					#p($rs_images);			
						my $img_caption_num = 1 ; 
						foreach my $row_img ( @$rs_images ) {
							next unless ( $row_img->{'ImageItemName'} eq $table ) ; 
							next unless ( $row_img->{'ImageItemId'} eq $id ) ; 
							my $row_image_data = $row_img ; 

							if ( $row_image_data->{'ImageItemId'} ) {	
								# ![myimage-alt-tag](url-to-image)
								$str_response			.= "\n" . $row_image_data->{'ImageTitle'} . "\n" ; 
								$str_response			.= '![' . $row_image_data->{'ImageDescription'} . ']' ; 
								$str_response			.= '(' . $row_image_data->{'ImageHttpPath'} . ')' ; 
							}

							$img_caption_num++ ; 
						} #eof foreach my row img
				}


				if ( $column_name eq 'SrcCode' ) {
					my $src_code = $row->{ 'SrcCode' } ; 
					$src_code =~ s/^/    /g ; 
					$src_code =~ s/\n/\n    /gm ; 
					$str_response .= $src_code ; 
					$str_response .= "\n\n" ; 
				}
				
				$col_num++ ;
				$i++ ;

			} #eof foreach column

			$row_num++ ; 
		}
		# eof foreach row 

		#debug print "START doc_pub/lib/DocPub/Model/RsToGitHubMdConverter.pm str_response \n\n\n" ; 
		#p($str_response); 
		#debug print "STOP doc_pub/lib/DocPub/Model/RsToGitHubMdConverter.pm str_response \n\n\n" ; 

		# ensure no Windows line endings ... 	
		$str_response =~ s/\r\n/\n/mg ; 		
		$self->PrintToFile ( $file , $str_response , ':utf8' ) ; 
		
      binmode STDOUT, ':utf8' ; 
		
		return $file ; 

	}
	#eof sub doConvertTableToSheet

  
   # 
	# -----------------------------------------------------------------------------
	# Prints the passed string to a file if the file exists it is overwritten
	# -----------------------------------------------------------------------------
	sub PrintToFile {
		my $self = shift ; 
		my $FileOutput = shift
			|| cluck("RsToGitHubMdConverter::PrintToFile undef \$FileOutput  !!!");
		my $StringToPrint = shift
			|| cluck("RsToGitHubMdConverter undef \$StringToPrint  !!!");

		my $mode = '' ; 
		$mode = shift if ( @_ ) ; 
		$mode = '' unless $mode ; 


		$FileOutput =~ m/(.*)(\\|\/)(.*)/g ;
		my $FileDir = "$1$2"  ;

		chomp ( $FileDir ) ; 

		# try to create the dir path of the file path if it does not exist
		unless (-d $FileDir) {
		
			mkpath( "$FileDir" ) || cluck( $! ) ; 
		  	carp "should create the file dir $FileDir" ; 
		}


		#READ ALL ROWS OF A FILE TO ALIST
		open(FILEOUTPUT, ">$FileOutput")
		|| cluck("could not open the \$FileOutput $FileOutput! $! \n");


		#use utf-8 bin mode is told to do so 
		binmode(FILEOUTPUT, ":utf8") ; 

		print FILEOUTPUT $StringToPrint;
		close FILEOUTPUT;

		#debug $strToReturn .=  $StringToPrint;

	}  
	#eof sub PrintToFile

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
	# constructs the table of contents
   # -----------------------------------------------------------------------------
	sub doBuildTOC {
		
		my $self 			= shift ;
		my $rs_meta 		= shift ; 
		my $rs				= shift ; 

		my $ret								= 1 ; 
		my $msg								= '' ; 
		my $debug_msg						= '' ; 
		my $control 						= '' ; 	
		my $item								= $objController->param('item')  || 'Issue' ;
		my $item_lc							= lc ( $item ) ; 
		my $objTitleControlBuilder 	= () ; 
		my $objTitleControlFactory 	= () ; 
		my $objPrgrphControlBuilder 	= () ; 
		my $objPrgrphControlFactory 	= () ; 
		my $objSrcCodeControlBuilder 	= () ; 
		my $objSrcCodeControlFactory 	= () ; 
		my $doWhiteSpace 					= $objController->stash('DoWhiteSpace') || 0 ; 
		my $do_white_space 				= $objController->stash('DoWhiteSpace') || 0 ; 

		$objTitleControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objTitleControlBuilder 		= $objTitleControlFactory->doInstantiate ( 'doc_title' ) ;
		$objPrgrphControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objPrgrphControlBuilder 		= $objPrgrphControlFactory->doInstantiate ( 'doc_prgrph' ) ;
		$objSrcCodeControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objSrcCodeControlBuilder 		= $objSrcCodeControlFactory->doInstantiate ( 'src_code' ) ;

		#$control 			.= p($rs ) ; 
		#p($rs) ; 
		
		@$rs = sort { $a->{ 'SeqId' } <=> $b->{ 'SeqId' } } @$rs;


		unless ( $rs_meta or $rs ) {
		$control = '
			No document found </span>
		' ; 
			return ; 
		}

		# start -- building the header 
		my $row_num 		= 1 ; 
		$control				= "\n\n" . 'Table of Contents' . "\n\n" ; 

		my $hs_seq_logical_order = $self->doBuildLogicalOrderHash( $item , $rs )  ;

		foreach my $row ( @$rs )  {
			#$control .= '<tr>' ;
			my $i = 1 ; 
			
			foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
	         next if $row->{'Level'} == 1 ; 
		
				my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
				my $cell = '' ; 


				if ( $i == 1 ) {

					my $id = $cell ; 
				}
				# the Name attribute in the db is the title in the UI
				if ( $column_name eq 'Name' && $row->{'Level'} != 0 ) {
					my $title = '' ; 
					#$title = $objTitleControlBuilder->doBuildControl ( 
					#		$rs_meta , $hs_seq_logical_order , $rs , $row );
					
					my $msg							= '' ; 
					my $debug_msg					= '' ; 
					my $do_white_space			= $objController->stash('DoWhiteSpace');
					my $table 						= $objController->param('item') || 'Issue' ; 
					my $item_id_name				= $table . 'Id' ; 
					my $db							= $objController->param('db') || 'isg_pub_en' ; 
					my $table_lc 					= lc($table);

					my $title_data					= $row->{'Name'} ; 
					$title_data						= DocPub::View::HtmlHandler::convertHtmlEntities ( $title_data) ;
					my $level_num					= $row->{'Level'} ; 
					$title_data						 = uc($title_data ) if ( $level_num == 1 or $level_num == 0 or $level_num == 2 ) ; 

					my $white_space 				= "\n" if ( $do_white_space ) ; 
					my $id							= $row->{ $table . 'Id' } ; 
					my $logical_order				= $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } || '' ; 
					my $spaces 						= '' ; 
               my $asterixes              = '' ; 
               my $dashes                 = '' ; 
					for ( my $i=1; $i < $row->{ 'Level' };$i++) {
						$spaces				  .= '  ' ; 
						$asterixes		     .= '*' ; 
						$dashes		        .= '#' ; 
						$spaces				  .= '  ' if $i > 3 ; 
					}
					
					my $url 							= $objController->req->url ; 
					my $title_link					= '' ; 
					$title_link					   = lc ($title_data ) ; 
					$title_link					   =~ s/ /-/g ; 
					$title_link					   =~ s/[\<\>\?\!\:]//g ; 
					$title_link					   =~ s/&gt;//g ; 
					$title_link					   =~ s/&lt;//g ; 
					$title_link					   =~ s/\-\-/-/g ; 
					$title_link					   =~ s/\.//g ; 
					
					$title	 						.= $spaces . '*' . ' [' . $logical_order . " " . $title_data . ']' ; 
               $logical_order              =~ s/\.//g ; 
					$title	 						.= '(' . '#' . $logical_order . "-" . $title_link . ')' ; 
					$title	 						.= "\n" ; 
					
					$control .= $title ; 
				} #eof if
				
				$i++ ;
			}
			#eof foreach
			
			$row_num++ ;
		}
		$control  .= "\n" if $doWhiteSpace ;

		return $control ; 
		
	}
	#eof sub doBuildControl


	#
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub doConfigureControl {

		my $self 			= shift ;
		my $control_name 	= shift ;
		my $rs_meta 		= shift ; 
		my $i					= 1 ; 
		
		my $ret				= 1 ; 
		my $msg				= '' ; 
		my $debug_msg		= '' ; 
		my $control 			= '' ; 	
		my $control_conf	= '' ; 
		
		return ( $ret , $msg , $debug_msg , $control_conf ) ; 

	}
	#eof sub doConfigureControl
	


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
