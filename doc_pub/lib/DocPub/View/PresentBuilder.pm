package DocPub::View::PresentBuilder ; 

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
	our $doWhiteSpace		= 1 ; 

   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub doBuildControl {
		
		my $self 			= shift ;
		my $rs_meta 		= shift ; 
		my $rs				= shift ; 
		my $ret				= 1 ; 
		my $msg				= '' ; 
		my $debug_msg		= '' ; 
		my $control 		= '' ; 	
		my $item				= $objController->param('item')  || 'Issue' ;
		my $hdrs_only		= $objController->param('hdrs')		|| '0' ; 

		my $objTitleControlBuilder 	= () ; 
		my $objTitleControlFactory 	= () ; 
		my $objPrgrphControlBuilder 	= () ; 
		my $objPrgrphControlFactory 	= () ; 
		my $objSrcCodeControlBuilder 	= () ; 
		my $objSrcCodeControlFactory 	= () ; 
		my $doWhiteSpace 	= $objController->stash('DoWhiteSpace'); 

		$objTitleControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objTitleControlBuilder 		= $objTitleControlFactory->doInstantiate ( 'present_title' ) ;
		$objPrgrphControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objPrgrphControlBuilder 		= $objPrgrphControlFactory->doInstantiate ( 'present_prgrph' ) ;
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
		$control				= '' ; 

		my $hs_seq_logical_order = $self->doBuildLogicalOrderHash( $item , $rs )  ;
		my $header_count = 1 ; 
		# use only the first 4 levels
		for ( my $tgt_level = 0 ; $tgt_level < 3 ; $tgt_level ++ ) {
			foreach my $row ( @$rs )  {
				#$control .= '<tr>' ;
				if ( $tgt_level == $row->{'Level'} ) {
					$control  .= $self->doBuildPresentationTitle ( 
						$rs_meta , $rs  , $hs_seq_logical_order , $tgt_level 
						, $row->{'LeftRank'}  , $row->{'RightRank'} , $header_count );
					$header_count++ ; 
				}
			}

		}
		
		#$control  .= $self->doBuildFirstLevel ( $rs_meta , $rs ) ; 	
		
		$control  .= "\n" if $doWhiteSpace ;

		# stop -- building the header 

		return $control ; 
		

	}
	#eof sub doBuildControl


	# -
	# build the first slide of the document
	# ---------------------------------------
	sub doBuildPresentationTitle {

		my $self 						= shift ;
		my $rs_meta 					= shift ; 
		my $rs							= shift ; 
		my $hs_seq_logical_order 	= shift ; 
		my $tgt_level					= shift ; 
		my $tgt_lft_rnk 				= shift ; 
		my $tgt_rgt_rnk 				= shift ; 
		my $header_count				= shift ; 
		my $ret							= 1 ; 
		my $msg							= '' ; 
		my $debug_msg					= '' ; 
		my $control 					= '' ; 	
		my $item							= $objController->param('item')  || 'Issue' ;
		my $table						= $objController->param('item')  || 'Issue' ;
		my $hdrs_only					= $objController->param('hdrs')		|| '0' ; 
	
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

		foreach my $row ( @$rs )  {
			#$control .= '<tr>' ;
			my $i = 1 ; 
			
		 if ( 
			1==1
			and $row->{'LeftRank'}  >= $tgt_lft_rnk
			and $row->{'LeftRank'}  < $tgt_rgt_rnk
			and $tgt_level == $row->{'Level'} 
			) {
				foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
					my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
					my $id							= $row->{ $table . 'Id' } ; 
					my $logical_order				= $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } ; 
					# the Name attribute in the db is the title in the UI
					if ( $column_name eq 'Name' && $row->{'Level'} == $tgt_level ) {
				
						$control .= '<!-- START presenting documenent title slide -->' ; 
						$control	.= '<section>' . "\n" ; 
						$control .= '<h1 class="fragment highlight-blue slide_title">' ; 
						#REBUILD ISG-PUB ON TOP OF MOJOLICIOUS 
						$control	.= $logical_order . " " . $row->{'Name'} ; 
						$control .= '</h1>' . "\n"  ;
						$control .= '</section>' . "\n" ; 
						$control	.= '<!-- START presenting level-' . $header_count . ' with subtitles  -->' ; 
						$control .= '<section data-state="header' . $header_count . '">' ; 
						$control .= '<style>.header' . $header_count . ' header:after { content: "' ; 
						$control .= $logical_order . " " . $row->{'Name' }  . '" ; }</style>' ; 
						$control .= $self->doBuildSubLevel ( 
						$rs_meta , $rs  , $hs_seq_logical_order , $tgt_level
						, $row->{'LeftRank'}  , $row->{'RightRank'} , $header_count );

						$control .= '</section>' . "\n" ; 

					} #eof if Name
					$i++ ;
				} #eof foreach col
			} #eof if 
			$row_num++ ;
		}
		$control  .= "\n" if $doWhiteSpace ;
		return $control ; 
		
			
	}
	#eof sub doBuildPresentationTitle
	

	# build the first slide of the document
	sub doBuildSubLevel {

		my $self 						= shift ;
		my $rs_meta 					= shift ; 
		my $rs							= shift ; 
		my $hs_seq_logical_order 	= shift ; 
		my $upper_level				= shift ; 
		my $tgt_level					= $upper_level + 1 ; 
		my $tgt_lft_rnk 				= shift ; 
		my $tgt_rgt_rnk 				= shift ; 
		my $header_count				= shift ; 
		my $ret							= 1 ; 
		my $msg							= '' ; 
		my $debug_msg					= '' ; 
		my $control 					= '' ; 	
		my $item							= $objController->param('item')  || 'Issue' ;
		my $table						= $objController->param('item')  || 'Issue' ;
		my $hdrs_only					= $objController->param('hdrs')		|| '0' ; 
	
		@$rs = sort { $a->{ 'SeqId' } <=> $b->{ 'SeqId' } } @$rs;

		# start -- building the header 
		my $row_num 		= 1 ; 

		foreach my $row ( @$rs )  {
			#$control .= '<tr>' ;
			my $i = 1 ; 
			
		 if ( 
			1==1
			and $row->{'LeftRank'}  >= $tgt_lft_rnk
			and $row->{'LeftRank'}  < $tgt_rgt_rnk
			and $row->{'Level'}  	== $tgt_level
			) {
				foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
					my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
					my $id							= $row->{ $table . 'Id' } ; 
					my $logical_order				= $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } ; 
					# the Name attribute in the db is the title in the UI
					if ( $column_name eq 'Name' && $row->{'Level'} == $tgt_level ) {
				
						$control .= '<!-- START presenting sublevel - documenent title slide -->' ; 
						$control .= '<p class="fragment highlight-blue"> ' ; 
						$control .= $logical_order . " " . $row->{'Name'} . ' </p>' ; 

					} #eof if Name
					$i++ ;
				} #eof foreach col
			} #eof if 
			$row_num++ ;
		}
		$control  .= "\n" if $doWhiteSpace ;
		return $control ; 
		
			
	}
	#eof sub doBuildFirstLevel
	
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

	

	sub doResetAllSubordinateLevels {

		my $self 						= shift ; 
		my $hs_level_counts		 	= shift ; 
		my $current_level				= shift ; 

		
		for ( my $level = 0 ;$level < 20; $level++ ) {
			next if $level <= $current_level  ; 
			$hs_level_counts->{ $level } = 0 ; 
		}
		
		p($hs_level_counts);

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
