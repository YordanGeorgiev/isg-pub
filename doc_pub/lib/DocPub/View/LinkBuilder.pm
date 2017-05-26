package DocPub::View::LinkBuilder;

	use strict ; use warnings ; use diagnostics ; 
	
	require Exporter ; 
	our @ISA = qw(Exporter);
	our %EXPORT_TAGS = ( 'all' => [ qw(buildStatusListingEditLink buildDocListingEditLink doCreateInterLinkAnchors buildHeaderSortingLink buildNewItemLink buildDocFlipFlopLink buildStatusFlipFlopLink buildTopLink buildPageTypeLink buildDocListingTopLink ) ] ) ; 
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
	our @EXPORT = qw() ; 
	use AutoLoader 'AUTOLOAD';

	use Carp qw (croak carp);

	use Data::Printer ; 


	#
	# -----------------------------------------------------------------------------
	# variables
	# -----------------------------------------------------------------------------
	our $ModuleDebug 		= 0  ; 

	#
	# -----------------------------------------------------------------------------
	# start subs
	# -----------------------------------------------------------------------------


	#
	# -----------------------------------------------------------------------------
	# do set the initial vars
   # $self->doCreateInterLinkAnchors ( $caller , $objController , $content ) ; 
	# issue-645
	# -----------------------------------------------------------------------------
   sub doCreateInterLinkAnchors { 

      my $caller                 = shift ; 
		my $objController				= shift ; 
      my $content     				= shift ; 
      my $db                     = $objController->param ( 'db' ) || 'isg_pub_en' ; 
		my $refItemViews     = $objController->app->getAppStructureData ( \$objController, $db ) ; 
		#  print "doCreateInterLinkAnchors " ; 
		# p($refItemViews);
		my $url 							= $objController->req->url ; 
		my $base 						= $url->base ; 
		my $query 						= $url->query;
		my $path 						= $url->path;
		my $params						= $objController->req->query_params ; 
		my $url_params_hash			= $params->to_hash  ; 
	
		#p($refItemViews);

      foreach my $key ( keys (%$refItemViews)) {

			my $rfHashRow 					= $refItemViews->{"$key"} ; 

         my $item      					= $rfHashRow->{"TableNameLC"} ; 
      
			next unless $item ; 

         my $table                  = '' ; 
         $table	                  = $rfHashRow->{"TableNameLC"}  ; 

         my $Table                  = '' ; 
         $Table                  	= $rfHashRow->{"TableName"}  ; 


         my $doc_page               = '' ; 
         $doc_page	               = $rfHashRow->{"Name"}  ; 
         my $status_page 				= $doc_page ;  

         my $doc_page_link 			= $rfHashRow->{"Name"}  ; 
         my $status_page_link 		= $doc_page_link ; 

			$doc_page_link		 	= 
				$base . '/view' 
					. '?' 
					. 'db=' . $objController->param('db')
					. '&item=' . $rfHashRow->{'TableName'}
					. '&' . 'filter-by=Level&filter-value=1,2,3,4,5,6'
					. '&' . 'path-id='
				; 

			$status_page_link		 = 
				$base . '/list'
					. '?' 
					. 'db=' . $objController->param('db')
					. '&item=' . $rfHashRow->{'TableName'}
					. '&' . 'filter-by=Level&filter-value=1,2,3,4,5,6'
					. '&' . 'path-id='
				; 

			my $a_href_open		= '<a href="' ; 
			my $a_href_close		= '">' ;
			my $hash_mark			= '#' ; 
			my $a_close_final		= '</a>' ; 

			my $strOpenLink      = '<a href="' . $doc_page_link . '#' ; 
         my $strCloseLink1    = '">' ; 
         my $strCloseLink2    = '</a>' ; 
         
         my $strBoltOpenLink  = '<a href="' . "$status_page_link" . '#' ; 
         my $str_bolt_img     = '' ; 
         my $strSpace         = '&nbsp;' ; 

			# see issue-645
			# OBS !!! if the there are spaces before or after the entity aka " issue-38 "
			# OBS !!! we do not replace
			# we should avoid also already converted to links item_name-item_id's e.g:
			# #issue-1">issue-1<
         $content =~ s{[^\#\>]((\ )((($item)-([0-9]*))(\ )))[^\"\<]}{
					$strSpace$a_href_open$doc_page_link$6$hash_mark$4$a_href_close$1$a_close_final
               }gxm ; 

#			print '1 is "' . $1 . '"' . " \n" if ( $item eq 'issue' and $3 ) ; 
#			print '2 is "' . $2 . '"' . " \n" if ( $item eq 'issue' and $3 ) ; 
#			print '3 is "' . $3 . '"' . " \n" if ( $item eq 'issue' and $3 ) ; 
#			print '4 is "' . $4 . '"' . " \n" if ( $item eq 'issue' and $3 ) ; 
#			print '5 is "' . $5 . '"' . " \n" if ( $item eq 'issue' and $3 ) ; 
      }
      #eof foreach 
            
				
				
				return $content ; 


   }
   #eof sub doCreateInterLinkAnchors


	#
	# -----------------------------------------------------------------------------
	# simply print a better message by using AUTOLOAD 
	# -----------------------------------------------------------------------------
	no warnings 'redefine' ; 
	sub AUTOLOAD {
		my $func_name 	 = our $AUTOLOAD ; 
		my $error_msg 	 = '' ; 
		$error_msg 		.= "\n\n\n[FATAL] Undefined function $func_name " ; 
		$error_msg 		.= "with params:\"" . ( @_ ) . "\" called !!!\n\n\n" ; 
		Carp::croak $error_msg ; 
	}
	use warnings 'redefine' ; 


	#
	# -----------------------------------------------------------------------------
	# stop subs
	# -----------------------------------------------------------------------------

1;
__END__




=head1 NAME

LinkBuilder

=head1 SYNOPSIS

use LinkBuilder
  
=head1 DESCRIPTION

the Model object ( one and only ?! ) 

=head2 EXPORT


=head1 SEE ALSO


  No mailing list for this module


=head1 AUTHOR

  yordan.georgiev@gmail.com

=head1 COPYRIGHT MOR LICENSE

  Copyright (C) 2014 Yordan Georgiev

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.8.1 or,
  at your option, any later version of Perl 5 you may have available.

=cut


# 
# -----------------------------------------------------------------------------
# VersionHistory
# -----------------------------------------------------------------------------
#
# 1.0.0 -- 2014-09-02 21:55:09 -- ysg -- output sh and txt files ok
#
