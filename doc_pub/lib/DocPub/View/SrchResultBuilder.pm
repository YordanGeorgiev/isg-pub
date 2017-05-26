package DocPub::View::SrchResultBuilder ; 

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
		my $doWhiteSpace 	= $objController->stash('DoWhiteSpace'); 
		
		my $url 							= $objController->req->url ; 
		my $base 						= $url->base ; 
		my $query 						= $url->query;
		my $path 						= $url->path;
		my $params						= $objController->req->query_params ; 

		$objTitleControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objTitleControlBuilder 		= $objTitleControlFactory->doInstantiate ( 'srch_title' ) ;
		$objPrgrphControlFactory 		= 'DocPub::View::ControlFactory'->new( \$objController);
		$objPrgrphControlBuilder 		= $objPrgrphControlFactory->doInstantiate ( 'srch_prgrph' ) ;

		#debug $control 			.= p($rs ) ; 
		

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

		#return ( $ret , $msg , $debug_msg , $control ) ; 
		my $refItemViews				= $objController->stash('RefItemViews');
		my $sth 							= () ; 
		my $ref_sth 					= () ; 
		

		my $refFetchedAll = $objController->stash('doSearchNamesAndDescriptions');
		#print "\n\n doc_pub/lib/DocPub/View/SrchResultBuilder.pm " ; 
		#p($refFetchedAll ) ; 

		my $Num 	  = '' ; 
		$objLogger->debug ( p($refFetchedAll) ) if ( $ModuleDebug == 1 ) ; 
		

      foreach my $Key ( sort ( keys %$refFetchedAll )) {
			my $rfHashRow 					= $refFetchedAll->{"$Key"} ; 
			my $db							= $rfHashRow->{'Db'} ; 
			my $TableNameLC 				= $rfHashRow->{'TableNameLC'} ; 
			my $Table                  = $rfHashRow->{'TableName'} ; 
			my $page							= $rfHashRow->{'Page'} ; 
			my $doc_id						= $rfHashRow->{'DocId'} ; 
			my $id 							= $rfHashRow->{'Id'} ; 
			my $title						= 'document: ' . $rfHashRow->{'LeftMenuItemName'} ; 
       	
			my $found_url					= q{} ; 
	
			$found_url						.= $base . '/view' ; 
			$found_url						.= '?' ; 
			$found_url						.= 'db=' 	 . $db;
			$found_url						.= '&path-id=' 	 . $id ;
			$found_url						.= '&item=' 	 . $Table ; 
			$found_url						.= '&order-by=SeqId'  ; 
			$found_url						.= '&filter-by=Level' ; 
			my $levels 						 = $rfHashRow->{'Level'} ;
			my $latest_level				 = $levels ; 
			$latest_level					 =~ s/(.*),(\d)/$2/g ; 
			my $filter_value				 = '0' ; 
			for ( my $i = 1 ; $i <= $latest_level ; $i++ ) { 
				$filter_value				.= ',' . $i ; 	
			}
			$found_url						.= '&filter-value=' . $filter_value ; 
			$found_url						.= '#' . $TableNameLC . '-' . $id ; 

			# START TITLE
			my $current_token=$rfHashRow->{'Name'} ; 
			my $heading_num             =  4 ; 

			# if not name defined do nothing 
			next unless ( defined ( $current_token ) ) ;

			my $visible_title        = " " . $Table . ": " . $current_token ; 
			#$visible_title           =~ s/(.*)\.([a-z]*)/$1/g ; 
			# capitalize the first letter of the visible title
			$visible_title           =~ s/ 
				(^\w)    #at the beginning of the line
				/\U$1/xgu ;  
			my $link                    =  '<a href="' . "$found_url" ; 
			$link                   .=  '">' . "$visible_title" . '</a>' ; 

			$control     .= '<div class="result_body_txt" ' . 'title="' . $title . '">'  ; 
			
			$control     .= '<h' . $heading_num . '>' ; 
			$link			 = "$visible_title" if ( $rfHashRow->{'SearchType'} eq 'file' ) ; 
			$control		.= $link ; 
			$control 		.= '</h' . "$heading_num" . '>' . "\n" ; 

			$current_token = $rfHashRow->{'Description'} ; 
			$current_token = substr $current_token , 0 , 100 ; 
			$current_token .= ' ...' ; 
			
			$current_token = text2html($current_token ) ; 

			$current_token     =~ s/
			  (^\w)    #at the beginning of the line
			 /\U$1/xgu ; 

			$control 		.= '<div>' . "\n" ; 
			$control 		.= $current_token . '</p></div>' . "\n" ;  
			#debug $control 		.= p($refFetchedAll );
			$control 		.= '</div>' . "\n" ; 
            
      }
		#eof foreach Key
      
		#my $page_html_title = 'search ' . $Project ; 
		#$self->set('HtmlPageTitle' , $page_html_title ) ; 

		$msg .= $objController->stash('Msg');
		$objController->set('Msg' , $msg ) ; 

		$debug_msg .= $objController->stash('DebugMsg');
		$objController->stash('DebugMsg' , $debug_msg ) ; 

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
