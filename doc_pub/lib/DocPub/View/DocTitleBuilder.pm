package DocPub::View::DocTitleBuilder ; 

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
	# call by: $objDocTitleBuilder->( $rs_meta , $hs_seq_logical_order , $rs , $row );
   # -----------------------------------------------------------------------------
	sub doBuildControl {
		
		my $self 						= shift ;
		my $rs_meta						= shift ; 
		my $hs_seq_logical_order 	= shift ; 
		my $rs							= shift ; 
		my $row							= shift ; 

		my $ret							= 1 ; 
		my $msg							= '' ; 
		my $debug_msg					= '' ; 
		my $control						= '' ; 
		my $do_white_space			= $objController->stash('DoWhiteSpace');
		my $table 						= $objController->param('item') || 'Issue' ; 
		my $db							= $objController->param('db') || 'isg_pub_en' ; 
      my $nonums                 = $objController->param('nonums') || 0 ; 
		my $table_lc 					= lc($table);

		my $title_data					= $row->{'Name'} ; 
		$title_data						= DocPub::View::HtmlHandler::convertHtmlEntities ( $title_data) ;
		my $level_num					= $row->{'Level'} ; 

		my $white_space 				= "\n" if ( $do_white_space ) ; 
		my $title						= '' ; 
		my $id							= $row->{ $table . 'Id' } ; 
		my $logical_order				= $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } || '' ; 
		$logical_order					= ' ' if $nonums == 1 ; 
		my $url 							= $objController->req->url ; 
		my $base 						= $url->base ; 
		my $port							= $url->port ; 
		my $query 						= $url->query;
		my $path 						= $url->path;
		my $params						= $objController->req->query_params ; 
		my $url_levels					= $objController->param('filter-value');
		my $hdrs_only					= 0 ; 
		$hdrs_only						= $objController->param('hdrs') || 0 ; 
		my $last_level					= $url_levels ; 
		$last_level						=~ s/(.*)(\d){1}/$2/g ; 
		my $one_level_down			= $last_level + 1 ; 
		$url_levels					  .= ',' . $one_level_down ; 
		my $doWhiteSpace				= $objController->stash('doWhiteSpace') || 0 ; 
		
		my $drill_down_params 		=  '' ; 
		$drill_down_params 		  .= 'db=' . $db; 
		$drill_down_params 		  .= '&branch-id=' . $id ; 
		$drill_down_params 		  .= '&filter-by=Level' ; 
		$drill_down_params 		  .= '&item=' . $table ; 
		$drill_down_params 		  .= '&hdrs=1' if ( $hdrs_only == 1 ) ; 
		$drill_down_params 		  .= '&filter-value=' . $url_levels ; 

		my $open_link					= $base . '/view?' . Mojo::Util::url_unescape ( $drill_down_params ) ; 
		my $headers_only_params		= '' ; 
		$headers_only_params 		  .= 'db=' . $db; 
		$headers_only_params 		  .= '&branch-id=' . $id ; 
		$headers_only_params 		  .= '&filter-by=Level' ; 
		$headers_only_params 		  .= '&item=' . $table ; 
		$headers_only_params 		  .= '&hdrs=1' ;
		$headers_only_params 		  .= '&filter-value=' . $url_levels ; 
		my $headers_only_link		= $base . '/view?' . Mojo::Util::url_unescape ( $headers_only_params ) ;


		my $printable_doc_params		= '' ; 
		$printable_doc_params 		  .= 'db=' . $db; 
		$printable_doc_params 		  .= '&branch-id=' . $id ; 
		$printable_doc_params 		  .= '&filter-by=Level' ; 
		$printable_doc_params 		  .= '&item=' . $table ; 
		$printable_doc_params 		  .= '&filter-value=' . $url_levels ; 
		my $printable_doc_link		= $base . '/viewpdf?' . Mojo::Util::url_unescape ( $printable_doc_params ) ;


		my $promote_link				= $base . Mojo::Util::url_unescape ( $url ) . '&promote-id=' . $id . '#' . $table_lc . '-' . $id ; 
		my $demote_link				= $base . Mojo::Util::url_unescape ( $url ) . '&demote-id=' . $id . '#' . $table_lc . '-' . $id ; 		
		my $item_id_name				= $table . "Id" ; 

		my $export_to_pdf_link		= $base . '/export?to=pdf&' . Mojo::Util::url_unescape ( $drill_down_params ) ; 
		my $export_to_githubmd_link = $base . '/export?to=githubmd&' . Mojo::Util::url_unescape ( $drill_down_params ) ; 
		my $export_to_bitbucketmd_link = $base . '/export?to=bitbucketmd&' . Mojo::Util::url_unescape ( $drill_down_params ) ; 
		my $export_to_xls_link		= $base . '/export?to=xls&' . Mojo::Util::url_unescape ( $drill_down_params ) ; 
		my $present_link				= $base . '/present' ; 
		$present_link					.= '?db=' . $db ; 
		$present_link					.= '&branch-id=' . $id ; 
		$present_link					.= '&item=' . $table ; 
		$present_link					.= '&filter-by=Level&filter-value=1,2,3' ; 

		my $seq_id						 = $row->{'SeqId'} ; 

		#ok<div class="item-heading"> 
		$title	 						.= "\n" . '<div class="item-heading edit draggable droppable" id="dp_Name-' . $id . '">' ; 

		#ok <a name="issue-722" id="issue-722"></a>
		$title	 						.= '<a name="' . $table_lc . '-' . $id . '" ' ; 
		$title	 						.=  'id="' . $table_lc . '-' . $id . '" '  ; 
		$title 							.= 'title="SeqId:' . $row->{'SeqId'} ; 
		$title							.= ' . #Id: ' . $row->{"$item_id_name"} . '"' ;
		$title	 						.=  ' " tabindex="0"></a>' ; 

		#ok <a name="issue_2" id="issue_2"></a> -- generate the anchors by sequence id
		$title	 						.= '<a name="' . $table_lc . '_' . $row->{'SeqId'} . '" ' ; 
		$title	 						.=  'id="' . $table_lc . '_' . $row->{'SeqId'} . '" '  ; 
		$title 							.= 'title="SeqId:' . $row->{'SeqId'} ; 
		$title							.= ' . #Id: ' . $row->{"$item_id_name"} . '"' ;
		$title	 						.=  ' " tabindex="0"></a>' ; 
		
		#<h2>1.0.0   INITIALIZE THE DOC-PUB PROTOTYPE MOJOLICIOUS APPLICATION</h2>
		my $tab_inx_seq				 = $row->{'SeqId'}  ; 
		$title							.= '<div class="ihtc">' ; 
		$title	 						.= '<h' . $level_num ; 
		$title	 						.= ' id="' . $table_lc . '-' . $id . '" '  ; 
		$title 							.= 'title="SeqId:' . $row->{'SeqId'} ; 
		$title							.= ' LeftRank: ' . $row->{'LeftRank'}  ;
		$title							.= ' RightRank: ' . $row->{'RightRank'}  ;
		$title							.= ' . #Id: ' . $row->{"$item_id_name"}  ;
		$title							.= ' . Level: ' . $row->{'Level'}  ;
		$title						 	.= '">' ; 
		$title							.= '<a href="' . $open_link . '">' . $logical_order . '</a>' ; 
		$title							.= '</h' . $level_num . '>' ; 
		$title							.= '</div> &nbsp; '  ; 

		$title							.= '<div class="ihtc">' ; 
		$title	 						.= '<h' . $level_num ; 
		$title 							.= ' title=" to EDIT click in the title , to CANCEL press the ESC key ' ; 
		$title 							.= ' to SAVE click elsewhere or press the tab key on the keyboard " ' ; 
		$title						 	.= '>' ; 
		$title							.= '<a href="' . $open_link . '" ' ; 
		#$title							.= 'tabindex="' . $tab_inx_seq . '">' ; 
		$title							.= 'tabindex="0">' ; 
		$title_data						 = uc($title_data ) if ( $level_num == 1 or $level_num == 0 or $level_num == 2 ) ; 
		$title							.= $title_data . '</a></div>' ; 
		$title							.= '</h' . $level_num . '>' ; 
		$title	 						.= '<div id="top_lnk-' . $id . '" class="top_links">' ; 
		$title							.= $base . Mojo::Util::url_unescape ( $url ) ;
		$title							.= '#' . $table_lc . '_' . $row->{'SeqId'} . '</div>' ; 
		
		# <div id="listing_links-722" class="listing_links">http://localhost:8080/isg-pub/show.pl?lang=en&page_type=status&page=issue&docid=9&level=1,2,3,4,5#issue-722</div>
		$title	 						.= '<div id="edit_links-' . $id . '" class="edit_links">' ; 


		my $listing_params		= '' ; 
		$listing_params 		  .= 'db=' . $db; 
		$listing_params 		  .= '&branch-id=' . $id ; 
		$listing_params 		  .= '&filter-by=Level' ; 
		$listing_params 		  .= '&item=' . $table ; 
		$listing_params 		  .= '&filter-value=' . $url_levels ; 
		my $listing_link		= $base . '/list?' . Mojo::Util::url_unescape ( $listing_params ) ;

		$title							.= $listing_link ;
		$title							.= '#' . $table_lc . '-' . $id . '</div>' ; 
		
		$title	 						.= '<div id="open_links-' . $id . '" class="open_links">' ; 
		$open_link						.= '</div>' ; 
		$title							.= $open_link ;
	
		if ( $level_num == 1 ) {
			$title	 						.= '<div id="present_links-' . $id . '" class="present_links">' ; 
			$present_link					.= '</div>' ; 
			$title							.= $present_link ;
		}
		
		$title	 						.= '<div id="headers_only_links-' . $id . '" class="headers_only_links">' ; 
		$headers_only_link			.= '</div>' ; 
		$title							.= $headers_only_link ; 
		
		$title	 						.= '<div id="printable_doc_links-' . $id . '" class="printable_doc_links">' ; 
		$printable_doc_link			.= '</div>' ; 
		$title							.= $printable_doc_link ; 

		$title	 						.= '<div id="export_to_xls_links-' . $id . '" class="export_to_xls_links">' ; 
		$export_to_xls_link			.= '</div>' ; 
		$title							.= $export_to_xls_link ; 

		$title	 						.= '<div id="export_to_pdf_links-' . $id . '" class="export_to_pdf_links">' ; 
		$export_to_pdf_link			.= '</div>' ; 
		$title							.= $export_to_pdf_link ; 
		
		$title	 						.= '<div id="export_to_githubmd_links-' . $id . '" class="export_to_githubmd_links">' ; 
		$export_to_githubmd_link			.= '</div>' ; 
		$title							.= $export_to_githubmd_link ; 
		
		$title	 						.= '<div id="export_to_bitbucketmd_links-' . $id . '" class="export_to_bitbucketmd_links">' ; 
		$export_to_bitbucketmd_link			.= '</div>' ; 
		$title							.= $export_to_bitbucketmd_link ; 
		
		$title	 						.= '<div id="promote_links-' . $id . '" class="promote_links">' ; 
		$promote_link					.= '</div>' ; 
		$title							.= $promote_link ; 
		
		$title	 						.= '<div id="demote_links-' . $id . '" class="demote_links">' ; 
		$demote_link					.= '</div>' ; 
		$title							.= $demote_link ; 

		#debug $title							.= $row->{ 'TagName' } if $row->{ 'TagName' } ; 
		
		$title	 						.= '</div>' ; 
		$title	 						.= "\n" if ( $doWhiteSpace ) ; 

		return $title ; 

	}
	#eof sub doBuildControl
  

	#
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub doConfigureControl {

		my $self 			= shift ;
		my $table_name 	= shift ;
		my $rs_meta 		= shift ; 
		my $i					= 1 ; 
		
		my $ret				= 1 ; 
		my $msg				= '' ; 
		my $debug_msg		= '' ; 
		my $table 			= '' ; 	
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

DocTitleBuilder

=head1 SYNOPSIS

use DocPub::View::DocTitleBuilder ; 
  
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
