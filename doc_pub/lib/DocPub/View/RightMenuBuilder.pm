package DocPub::View::RightMenuBuilder ; 

   use strict ; 
   use warnings ; 

   require Exporter; 
   use AutoLoader ; 

	use utf8 ; 
	use Mojo::Message::Request;
	use Mojo::URL ; 
	use Mojo::Parameters ; 
	use Mojo::Util ; 

	use Data::Printer ; 
	use Carp ; 

	use DocPub::View::HtmlHandler ; 


   our $ModuleDebug    	= 0 ; 
   our $IsUnitTest     	= 0 ; 
	our $objController 	= {} ; 
	our $objLogger			= q{} ;
	our $app_config		= q{} ;


   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub doBuildControl {
		
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
			<div>
				<span> No document found </span>
			</div>
		' ; 
			return ; 
		}

		# start -- building the header 
		my $row_num 		= 1 ; 
		$control				= '' ; 


		#start add the levels
		#img/screen/themes/default/site/doc_action_menu_bullet.png
		#
		$control				.= '<div>' ; 
		my $url 							= $objController->req->url ; 
		my $base 						= $url->base ; 
		my $port							= $url->port ; 
		my $query 						= $url->query;
		my $path 						= $url->path;
		my $params						= $objController->req->query_params ; 
		my $url_levels					= '1' ; 
		my $db							= $objController->param('db'); 
		my $branch_id					= $objController->param('branch-id') ; 
		my $path_id						= $objController->param('path-id') ; 
		my $table						= $objController->param('item') ; 
		my $hdrs_only					= 0 ; 
		my $curr_url_levels			= $objController->param('filter-value') ;
		my $last_level					= $curr_url_levels ; 
		$last_level						=~ s/(.*)(\d){1}/$2/g ; 
		$hdrs_only						= $objController->param('hdrs') || 0 ; 
		for ( my $i_level = 2 ; $i_level <= 7 ; $i_level++ ) {	
			$url_levels					  .= ',' . $i_level ; 
			my $doWhiteSpace				= $objController->stash('doWhiteSpace') || 0 ; 
			
			#debug print "doc_pub/lib/DocPub/View/RightMenuBuilder.pm \n\n"  ; 
			#debug print "branch_id : " . $branch_id . "\n" ; 
			#debug print "path_id : " . $path_id . "\n" ; 

			my $open_params		= '' ; 
			$open_params 		  .= 'db=' . $db; 
			$open_params 		  .= '&branch-id=' . $branch_id if ( $branch_id ) ; 
			$open_params 		  .= '&path-id=' . $path_id if ( $path_id ) ; 
			$open_params 		  .= '&filter-by=Level' ; 
			$open_params 		  .= '&item=' . $table ; 
			$open_params 		  .= '&hdrs=' . $hdrs_only ; 
			$open_params 		  .= '&filter-value=' . $url_levels ; 
			my $open_link		= $base . '/view?' . Mojo::Util::url_unescape ( $open_params ) ;
			$control				  .= '<a href="' . $open_link ; 
			my $image_path		 	= 'css/screen/themes/default/css_tree/toggle_minus.png' ; 
			$image_path		 	= 'css/screen/themes/default/css_tree/toggle_plus.png' 
				if ( $last_level >= $i_level )  ;
			$control				  .= '"><img src="' . $image_path . '"></a>&nbsp;' ; 
		}

		$control				.= '</div>' ; 
		#stop  add the levels


		my $hs_seq_logical_order = $self->doBuildLogicalOrderHash( $item , $rs )  ;
		#$control = p ( $hs_seq_logical_order ) ; 
		#my $hs_seq_logical_order = {} ; 

		foreach my $row ( @$rs )  {
			#$control .= '<tr>' ;
			my $i = 1 ; 
			
			foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
			
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
					for ( my $i=1; $i < $row->{ 'Level' };$i++) {
						$spaces				  .= '&nbsp;' ; 
						$spaces				  .= '&nbsp;' if $i > 3 ; 
					}
					$logical_order					= $spaces . $logical_order ; 
					
					my $url 							= $objController->req->url ; 
					my $title_link					= '' ; 
					my $seq_id						= $row->{'SeqId'} ; 
					my $title_lnk_title			= "# SeqId: " . $row->{'SeqId'} ; 
					$title_lnk_title			  .= ' . #Id: ' . $row->{"$item_id_name"} . '"' ;
					$title_link					  .= '<a href="#' . $item_lc . '_' . $row->{'SeqId'} ;
					$title_link					  .= '" title="' . $title_lnk_title . '">' ; 
					$title_link					  .= $title_data . '</a>' ; 
					my $doWhiteSpace				= $objController->stash('doWhiteSpace') || 0 ; 
					
					$title	 						.= '<div id="rmlid-' . $id . '" class="toc draggable droppable">'  ; 
					$title	 						.= $logical_order . " " . $title_link ; 
					$title	 						.= '</div>' ; 
					$title	 						.= "\n" if ( $do_white_space == 1 ) ; 
					
					
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
		my $rowc = 0 ; 
		# ---
		# fill first the level counts
		foreach my $row ( @$rs )  {

			# set the id as the key to the logical hash
			my $id  = $row->{ $item_id_name } || $start_upper_level ; 
			$prev_level_num = $prev_row->{'Level'} || -1 ; 

			$hs_seq_logical_order->{ $id } = {} ; 
			$hs_seq_logical_order->{ $id }->{'Id'} = $id ; 
			

			my $level_num 	= $row->{ 'Level' }  ; 
			

			my $start_num = 0 ; 
			# only the first visible level starts at 1
			$start_num 	= 0 if $row->{ 'Level' } == 2 ; 
			
			$hs_level_counts->{ $level_num } = $start_num 
				unless ( $hs_level_counts->{ $level_num } ) ; 
			
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
   # doInitialize the object with the minimum data it will need to operate 
   # -----------------------------------------------------------------------------
   sub doInitialize {

      my $self = shift ; 
		
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
	
	

	
1;


__END__


=head1 NAME

DocBuilder

=head1 SYNOPSIS

use DocPub::View::DocBuilder ; 
  
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
