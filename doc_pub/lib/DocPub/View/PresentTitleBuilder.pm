package DocPub::View::PresentTitleBuilder ; 

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
		my $prev_row					= shift ; 

		my $ret							= 1 ; 
		my $msg							= '' ; 
		my $debug_msg					= '' ; 
		my $control						= '' ; 
		my $do_white_space			= $objController->stash('DoWhiteSpace');
		my $table 						= $objController->param('item') || 'Issue' ; 
		my $db							= $objController->param('db') || 'isg_pub_en' ; 
		my $table_lc 					= lc($table);

		my $title_data					= $row->{'Name'} ; 
		my $level_num					= $row->{'Level'} ; 

		my $white_space 				= "\n" if ( $do_white_space ) ; 
		my $title						= '' ; 
		my $id							= $row->{ $table . 'Id' } ; 
		my $logical_order				= $hs_seq_logical_order->{ $id }->{ 'LogicalOrder' } ; 
		
		my $url 							= $objController->req->url ; 
		my $base 						= $url->base ; 
		my $port							= $url->port ; 
		my $query 						= $url->query;
		my $path 						= $url->path;
		my $params						= $objController->req->query_params ; 
		my $url_levels					= $objController->param('filter-value');
		my $hdrs_only					= $objController->param('hdrs');
		my $last_level					= $url_levels ; 
		$last_level						=~ s/(.*)(\d){1}/$2/g ; 
		my $one_level_down			= $last_level + 1 ; 
		$url_levels					  .= ',' . $one_level_down ; 

		my $seq_id					   = $row->{'SeqId'} ;	
		my $prev_level_num			= $prev_row->{'Level'} ;	
		my $maybe_start_ul			=  '' ; 
		my $maybe_start_h				= '<h' . $level_num . '>' ;
		my $maybe_stop_ul				= '' ; 
		my $maybe_stop_h				= '</h' . $level_num . '>' ; 
		

		$title							.= $maybe_start_ul ; 
		$title	 						.= $maybe_start_h . $logical_order . " " . $title_data ; 
		$title							.= $maybe_stop_h ; 

		$title							.= $maybe_stop_ul ; 

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
