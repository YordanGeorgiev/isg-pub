package DocPub::View::DocPrgrphBuilder ; 

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
	use DocPub::View::LinkBuilder ; 

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
		
		my $self 				= shift ;
		my $rs_meta				= shift ; 
		my $hs_seq_logical_order = shift ; 
		my $rs					= shift ; 
		my $row					= shift ; 
		my $row_image_data 	= shift ; 

		#debug print "DocPrgrphBuilder row_image_data " . p($row_image_data) . "\n" ; 

		my $title_data			= $row->{'Name'} ; 
		my $ret					= 1 ; 
		my $msg					= '' ; 
		my $debug_msg			= '' ; 
		my $item					= $objController->param('item') || 'Issue' ; 
		my $control				= '' ; 
		my $content				= '' ; 

		my $do_white_space	= $objController->stash('DoWhiteSpace');
		my $white_space		= '' ; 
		my $level_num			= $row->{'Level'} ; 
		my $item_id_name		= $item . 'Id' ; 

		$white_space 			= "\n" if ( $do_white_space ) ; 
		my $paragraph			= '' ; 
		my $id 					= $row->{"$item_id_name"} ; 
		
		$content					= $row->{'Description'} ; 
		$content					= DocPub::View::HtmlHandler::text2html ( $content) ;
		$content 				= DocPub::View::LinkBuilder::doCreateInterLinkAnchors ( 'doc' , $objController , $content ) ;
		my $tab_inx_seq		= $row->{'SeqId'} ;  
		$paragraph				.= $white_space . '<div class="body_txt edit_area selectable" ' ; 
		$paragraph				.= 'id="dp_Description' . '-' . $id . '" ' ; 
		#$paragraph				.= 'tabindex="' . $tab_inx_seq . '" ' ;  
		$paragraph				.= 'tabindex="0" ' ;  
		#$paragraph				.= 'id="' . $id . '" ' ;  
		$paragraph				.= 'title="SeqId:' . $row->{'SeqId'} . ' . #Id: ' . $id . '"' ;
		$paragraph				.= '>' ; 
		#$paragraph				.= '<a href="#"> _ </a>' ; 
		$paragraph				.= $content ; 

		# start add tags
		# http://localhost:3000/search?txt_srch=boo&but=&db=isg_pub_en
		if ( $row->{'TagName'} ) {
			#todo: add split foreach tag in tags
			my $tags = $row->{'TagName'} ; 
			my @tags = split ( ' ' , $tags ) ; 
			$paragraph				.= '<div class="tag_cloud edit_area">'  ;
			foreach my $tag ( @tags ) {
				# todo parametrize
				$paragraph				.= '<a href="/search?tag_srch=' . $tag . '&but=&db=isg_pub_en">' ;
				$paragraph				.= $tag . '</a>' ; 
				$paragraph				.= ' ' ; 
			}

			$paragraph				.= '</div>'  ;
		}

		# stop  add tags 



		$paragraph				.= '</div>' . $white_space ; 

		#debug print 'doc_pub/lib/DocPub/View/DocPrgrphBuilder.pm' . "\n" ; 
		#debug p($row_image_data) ; 

		if ( $row_image_data->{'ImageItemId'} ) {	
			# ItemId		 	as ImageItemId
			# , Name 				as ImageTitle
			# , Description		as ImageDescription
			# , RelativePath 	as ImageRelativePath
			# , ItemName		 	as ImageItemName
			$paragraph			.= '<div class="img_control">' ; 
#			$paragraph			.= '<p class="image_title" id="img-ttle-' ;
#			$paragraph 			.= $row_image_data->{'ImageItemId'} . '"> ' ;
#			$paragraph			.= $row_image_data->{'ImageTitle'} ; 
#			$paragraph			.= '</p>' ; 
			$paragraph			.= '<p>' ; 
			$paragraph			.= '<figure>' ; 
			$paragraph			.= '<figcaption> ' ; 
			$paragraph			.= 'Figure: ' . $row_image_data->{'ImageCaptionNumber'} . " " . $row_image_data->{'ImageTitle'} ; 
			$paragraph			.= ' </figcaption>' ; 
			$paragraph			.= '<img src="' . $row_image_data->{'ImageRelativePath'} . '" ' ; 
			$paragraph			.= 'width="' . $row_image_data->{'Width'} . '" ' ; 
			$paragraph			.= 'height="' . $row_image_data->{'Height'} . '"  ' ; 
			$paragraph			.= 'alt="' . $row_image_data->{'ImageDescription'} . '"></img>' ; 
			$paragraph			.= '</figure>' ; 
			$paragraph			.= '</p>' ; 
			$paragraph			.= '</div>' ; 
		}


		return $paragraph ; 

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

DocPrgrphBuilder

=head1 SYNOPSIS

use DocPub::View::DocPrgrphBuilder ; 
  
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
