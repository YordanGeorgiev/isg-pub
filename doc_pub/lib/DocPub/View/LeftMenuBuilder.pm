package DocPub::View::LeftMenuBuilder ; 

   use strict ; 
   use warnings ; 

   require Exporter; 
   use AutoLoader ; 

	use utf8 ; 
	use Mojo::Message::Request;
	use Mojo::URL ; 
	use Mojo::Parameters ; 
	use Mojo::Util ; 
	use HTML::Entities ; 

	use Data::Printer ; 
	use Carp ; 



   our $ModuleDebug    	= 1 ; 
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
		my $route			= shift ; 

		my $ret				= 1 ; 
		my $msg				= '' ; 
		my $debug_msg		= '' ; 
		my $control 		= '' ; 	
		my $item				= $objController->param('item')  || 'Issue' ;
		my $hdrs_only		= $objController->param('hdrs')		|| '0' ; 
      my $db            = $objController->param('db')		|| 'isg_pub_en' ; 
		my $objTitleControlBuilder 	= () ; 
		my $objTitleControlFactory 	= () ; 
		my $objPrgrphControlBuilder 	= () ; 
		my $objPrgrphControlFactory 	= () ; 
		my $objSrcCodeControlBuilder 	= () ; 
		my $objSrcCodeControlFactory 	= () ; 
		my $doWhiteSpace 					= $objController->stash('DoWhiteSpace'); 
		my $refItemViews					= $objController->app->getAppStructureData ( \$objController, $db ) ; 
      # 'RefItemViews'
		$objTitleControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objTitleControlBuilder 		= $objTitleControlFactory->doInstantiate ( 'doc_title' ) ;

		#$control 			.= p($rs ) ; 
		# debug print "START doc_pub/lib/DocPub/View/LeftMenuBuilder.pm \n" ; 
		# debug p($refItemViews) ; 
		# debug print "STOP  doc_pub/lib/DocPub/View/LeftMenuBuilder.pm \n" ; 


		unless ( $refItemViews ) {
		$control = '
			<div>
				<span> cannot build left menu - no documents found !!! </span>
			</div>
		' ; 
			return ; 
		}

		# start -- building the header 
		my $row_num 		= 0 ; 
		$control				= '' ; 
		$control  			.= '<ol class="tree">' ; 

		my $prev_folder_name = '' ; 
		# note the sorting is performed according the SeqId of the ItemView table
		my @sorted_data_keys = 
			sort { $refItemViews->{$a}{'SeqId'} <=> $refItemViews->{$b}{'SeqId'} } keys %$refItemViews;
      my $TableName = '' ; 

		#debug print "doc_pub/lib/DocPub/Model/MariaDbHandler.pm sub doListFoldersAndDocsTitles \n" ; 
      foreach my $key ( @sorted_data_keys ) {
         
         my $Name				= $refItemViews->{"$key"}->{'Name'} ; 
			$Name					= lc ( $Name ) ; 
			$Name					= encode_entities( $Name ) ; 
         my $Description	= $refItemViews->{"$key"}->{'ItemViewDescription'} ; 
         my $do				= $refItemViews->{"$key"}->{'doGenerateLeftMenu'} ; 
         my $Type				= $refItemViews->{"$key"}->{'Type'} ; 
         my $TableName		= $refItemViews->{"$key"}->{'TableName'} ; 
         my $ItemViewId		= $refItemViews->{"$key"}->{'ItemViewId'} ; 
         my $BranchId		= $refItemViews->{"$key"}->{'BranchId'} ; 
			my $TableNameLC	= $refItemViews->{"$key"}->{'TableNameLC'} ; 
			my $Level 			= $refItemViews->{"$key"}->{'Level' } ; 
			my $folder_key		= $key*1000 ; 
			my $itm_ctn_id		= $refItemViews->{"$key"}->{'ItemControllerId' } ;
			
			next if $Level == 0 ; 
			#next if $Level == 1 ; 
			next if $do 	!= 1 ; 

         print "START \n" ; 
         p($refItemViews->{"$key"}) ; 
         print "STOP \n " ; 

			if ( $Type eq 'document' ) {
				$control			.= "\n\t\t"  if $ModuleDebug ; 
				my $link	 		= '/' . $route . '?db=' . $objController->param('db' ) ; 
				$link 			.= '&branch-id=' . $BranchId ; 
				$link 			.= '&item=' . $TableName ; 
				$link				.= '&order-by=SeqId&filter-by=Level&filter-value=0,1,2,3,4,5,6' ; 
				my $css_class  = 'file' ; 

				# both the TableName and the BranchId must be defined ... 
				if ( $TableName && $BranchId && 
						( $objController->param('branch-id') == $BranchId && 
					  		$objController->param('item' ) eq $TableName 
						) 
					 ) {
					$css_class 		 = 'current_selected_file' 
				}
				$control			.= '<li class="' . $css_class . '">' ; 
            $Description   = ' ' unless ( $Description ) ; 
				$control 		.= '<a href="' . $link . '" title="' . $Description . '">' ; 
				$control			.= ' ' . $Name ; 
				$control			.= '</a>'  ; 
				$control			.= '</li>'  ; 
				$control			.= "\n"  if $ModuleDebug ; 
			}
			elsif (  $Type eq 'folder' ) {
				my $folder_name	 = $Name ; 
				next if $folder_name eq $prev_folder_name ; 
				$prev_folder_name	 = $folder_name ; 
				my $label_id		 = "lml-" . $ItemViewId ; 
				$control				.= '</ol>' unless $row_num == 0 ; 
				$control  			.= '<li>' ; 
				$control  			.= '<a href="#">' ; 
				$control  			.= '<label for="' . $label_id . '">' ; 
				$control 			.= $Name ; 
				$control				.= '</label>' ; 
				$control  			.= '</a>' ; 
				$control				.= '<input tabindex="0" type="checkbox" ' ; 
				$control				.= 'id="chk-' .  $ItemViewId . '" ' ; 
				$control				.= 'class="folder_chk" ' ; 
				$control				.= 'name="chkn-' .  $ItemViewId . '" />' ; 
				$control				.= "\n"  if $ModuleDebug ; 
				$control				.= '<ol>' ; 

			#<label for="folder2">Folder 2</label> <input type="checkbox" id="folder2" /> 
			}
			
			$row_num++ ;
		}
		$control  			.= '</ol>' ; 
		$control  .= "\n" if $doWhiteSpace ;

		return $control ; 
		
	}
	#eof sub doBuildControl
	


   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub doBuildControlOld {
		
		my $self 			= shift ;
		my $rs				= shift ; 
		my $route			= shift ; 

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
		my $doWhiteSpace 					= $objController->stash('DoWhiteSpace'); 

		$objTitleControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objTitleControlBuilder 		= $objTitleControlFactory->doInstantiate ( 'doc_title' ) ;

		#$control 			.= p($rs ) ; 
		
		@$rs = sort { $a->{ 'SeqId' } <=> $b->{ 'SeqId' } } @$rs;
		#debug "LeftMenuBuilder \n" ; 
		#debug p($rs) ; 


		unless ( $rs ) {
		$control = '
			<div>
				<span> No document found </span>
			</div>
		' ; 
			return ; 
		}

		# start -- building the header 
		my $row_num 		= 0 ; 
		$control				= '' ; 
		$control  			.= '<ol class="tree">' ; 

		my $hs_seq_logical_order = $self->doBuildLogicalOrderHash( $item , $rs )  ;
		#$control = p ( $hs_seq_logical_order ) ; 
		#my $hs_seq_logical_order = {} ; 
		my $prev_row = () ; 
		my $prev_folder_name = '' ; 
		foreach my $row ( @$rs )  {

			if ( $row->{'Level'} == 2 ) {
				$control	.= "\n\t\t"  if $ModuleDebug ; 
				my $link	 = '/' . $route . '?db=' . $objController->param('db' ) ; 
				my $table = $row->{'TableName'} ; 
				my $d 	 = $row->{'TableName'} ; 
				$link 	.= '&branch-id=' . $row->{'Id'} ; 
				$link 	.= '&item=' . $table ; 
				$link		.= '&order-by=SeqId&filter-by=Level&filter-value=0,1,2,3' ; 
				$control	.= '<li class="file">' ; 
				$control .= '<a href="' . $link . '">' ; 
				$control	.= ' ' . $row->{'Name'} ;
				$control	.= '</a>'  ; 
				$control	.= '</li>'  ; 
				$control	.= "\n"  if $ModuleDebug ; 
			}
			elsif (  $row->{'Level'} == 1 ) {
				my $folder_name	 = $row->{'Name'} ; 
				next if $folder_name eq $prev_folder_name ; 
				$prev_folder_name	 = $folder_name ; 
				my $label_id		 = "lml-" . $row->{'SeqId'} ; 
				$control				.= '</ol>' unless $row_num == 0 ; 
				$control  			.= '<li>' ; 
				$control  			.= '<a href="#">' ; 
				$control  			.= '<label for="' . $label_id . '">' ; 
				$control 			.= $row->{'Name'} ; 
				$control				.= '</label>' ; 
				$control  			.= '</a>' ; 
				$control				.= '<input tabindex="0" type="checkbox" ' ; 
				$control				.= 'id="chk-' .  $label_id . '" ' ; 
				$control				.= 'class="folder_chk" ' ; 
				$control				.= 'name="chkn-' .  $label_id . '" />' ; 
				$control				.= "\n"  if $ModuleDebug ; 
				$control				.= '<ol>' ; 

			#<label for="folder2">Folder 2</label> <input type="checkbox" id="folder2" /> 
			}
			
			$row_num++ ;
			$prev_row = $row  ;
		}
		$control  			.= '</ol>' ; 
		$control  .= "\n" if $doWhiteSpace ;

		return $control ; 
		
	}
	#eof sub doBuildControl




	#
   # -----------------------------------------------------------------------------
	# build the inline table ... 
   # -----------------------------------------------------------------------------
	sub doBuildInlineTable {
		my $self 						= shift  ; 
		my $item 						= shift ; 
		my $row  						= shift ; 

		# start -- add the inline table
		my $refInlineTables 		 	= $objController->stash('FetchedDocumentInlineTables') ; 

		return unless ( $refInlineTables ) ; 

		#p($refInlineTables);
		#debug print "NOW \n\n\n\n" ; 
		my $item_id_name			 	= $item . 'Id' ; 
		my $item_id					 	= $row->{$item_id_name} ; 


		# proceed if the book does have any inline tables 
		if ( $refInlineTables ) {
			my %hInlineTables			 = %{$refInlineTables} ; 
			my $BookItemId 			 = lc($item) . '_' . $item_id ; 
			
			# leave only the slice of the hash ref of hash refs which matches the current item id
			#src: http://stackoverflow.com/a/18660724/65706
			delete @hInlineTables 
				{ grep { $hInlineTables{$_}{'BookItemId'} ne $BookItemId } keys(%hInlineTables) };

			# and proceed if there is data only for this item_id
			if ( %hInlineTables ) {
				my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$objController );
				my $objControlBuilder	= $objControlFactory->doInstantiate ( "inline_table" ) ;
				my $str_table           = $objControlBuilder->doBuildControl( $row , \%hInlineTables ) ; 
				# and restore the bigger hs of hss
				$objController->stash('FetchedDocumentInlineTables' , $refInlineTables  ) ;
				return $str_table ; 
			}
		}

		#otherwise 0 is returned and shown in the gui ...
		return '' ; 	
	}
	#eof sub doBuildInlineTable {



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
		# ---
		# fill first the level counts
		foreach my $row ( @$rs )  {

			# set the id as the key to the logical hash
			my $id  = $row->{ $item_id_name } || $start_upper_level ; 
			$prev_level_num = $prev_row->{'Level'} ; 

			$hs_seq_logical_order->{ $id } = {} ; 
			$hs_seq_logical_order->{ $id }->{'Id'} = $id ; 
			

			my $level_num 	= $row->{ 'Level' } ; 

			my $start_num = 0 ; 
			# only the first visible level starts at 1
			$start_num 	= 0 if $row->{ 'Level' } == 2 ; 
			
			$hs_level_counts->{ $level_num } = $start_num 
				unless ( $hs_level_counts->{ $level_num } ) ; 
			
			if ( $row->{'Level'} == 1 ) {
				$hs_level_counts->{ 1 } = 0 ; 
				$hs_level_counts->{ 2 } = 0 ; 
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
