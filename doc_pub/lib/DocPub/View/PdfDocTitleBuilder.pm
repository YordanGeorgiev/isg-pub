package DocPub::View::PdfDocTitleBuilder ; 

   use strict ; 
   use warnings ; 
	use utf8 ; 

   require Exporter; 
   use AutoLoader ; 

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
	# call by: $objPdfDocTitleBuilder->( $rs_meta , $hs_seq_logical_order , $rs , $row );
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
		my $do_white_space			= $objController->stash('DoWhiteSpace') || 0 ; 
		my $table 						= $objController->param('item') || 'Issue' ; 
		my $db							= $objController->param('db') || 'isg_pub_en' ; 
		my $table_lc 					= lc($table);

		my $title_data					= $row->{'Name'} ; 
		$title_data						= DocPub::View::HtmlHandler::convertHtmlEntities ( $title_data) ;
		my $level_num					= $row->{'Level'} ; 

		my $white_space 				= "\n" if ( $do_white_space ) ; 
		my $title						= '' ; 
		my $id							= $row->{ $table . 'Id' } ; 
		my $logical_order				= $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } || '' ; 
		$logical_order					= ' ' if $objController->param('nonums') == 1 ; 		
		
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
		my $item_id_name				= $table . "Id" ; 
		

		#ok<div class="item-heading"> 
		$title	 						.= "\n" . '<div class="item-heading" id="dp_Name-' . $id . '">' ; 

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
		$title							.= ' ' . $logical_order . ' ' ; 

		#$title							.= 'tabindex="' . $tab_inx_seq . '">' ; 
		$title_data						 = uc($title_data ) if ( $level_num == 1 or $level_num == 0 or $level_num == 2 ) ; 
		$title							.= $title_data . '</a></div>' ; 
		$title							.= '</h' . $level_num . '>' ; 
		$title	 						.= '<div id="top_lnk-' . $id . '" class="top_links">' ; 
		$title							.= $base . Mojo::Util::url_unescape ( $url ) ;
		$title							.= '#' . $table_lc . '-' . $id . '</div>' ; 
		
		# <div id="listing_links-722" class="listing_links">http://localhost:8080/isg-pub/show.pl?lang=en&page_type=status&page=issue&docid=9&level=1,2,3,4,5#issue-722</div>
	
		
		$title	 						.= '</div>' ; 
		$title	 						.= "\n" if ( $do_white_space == 1 ) ; 

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

PdfDocTitleBuilder

=head1 SYNOPSIS

use DocPub::View::PdfDocTitleBuilder ; 
  
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
