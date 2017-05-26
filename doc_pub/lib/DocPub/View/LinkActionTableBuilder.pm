package DocPub::View::LinkActionTableBuilder ; 

   use strict ; 
   use warnings ; 

   require Exporter; 
   use AutoLoader ; 

	use utf8 ; 

	use Data::Printer ; 
	use Carp ; 

	use DocPub::View::HtmlHandler ; 


   our $ModuleDebug           = 0 ; 
   our $IsUnitTest            = 0 ; 
	our $objController 			= {} ; 
	our $objLogger					= q{} ;
	our $app_config				= q{} ;



   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub doBuildControl {

		my $self 			= shift ;
		my $table_name 	= shift ;
		my $rs_meta 		= shift ; 
		my $rs				= shift ; 
	
		my $url 				= $objController->req->url ; 
		my $base 			= $url->base ; 
		my $query 			= $url->query;
		my $path 			= $url->path;
		my $params			= $objController->req->query_params ; 

		# start -- building the header 
		my $i 				= 1 ; 
		my $table			= ' 
			<div id="div_table">
				<table id="nice_table" class="inline_table"> ' ; 
		my $table_header = "\n"  ; 
		foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
			my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
			$column_name =~ s/_/ /g ; 

			if ( $column_name =~ m/LINK BUTTON/ ) {
				$column_name  =~ s/LINK BUTTON//g ; 
				#prepend instead of append
				$table_header = '<th>' . $column_name . '</th>' . $table_header ; 
			}
			else {
				$table_header .= '<th>' . $column_name . '</th>' ; 
			}
			$i++ ; 
		}
					
		$table .= '<thead><tr>' .$table_header . '</tr></thead>' ."\n" ; 
		# stop  -- building the header 
	

		# start -- building the body 
		$table .= '<tbody>' . "\n" ; 
		my $table_body = '' ; 
		# p($rs ) ; 
		foreach my $row ( @$rs )  {
			my $i = 1 ; 
			my $row_html = '' ; 	
			foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
				my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} // '' ;
				my $cell = '' ; 
				$cell = $row->{"$column_name"} ; 

				if ( $column_name =~ m/LINK_BUTTON/ ) {
					$column_name  =~ s/LINK_BUTTON//g ; 
					$column_name  =~ s/_/ /g ; 
					my $link_cell = '' ; 
					#build the link	
					$link_cell .= '<span class="link_button"><a href="' ; 
					$link_cell .= $cell . '">&gt;<a/></span>' ; 
					
					#prepend instead of append
					$row_html = '<td>' . $link_cell . '</td>' . $row_html ; 
				}
				else {
					$cell = DocPub::View::HtmlHandler::text2html ( $cell ) 
						if $column_name eq 'Description' ; 


					if ( $i == 1 ) {

						my $id = $cell ; 
						$params 				= $params->remove('branch-id');
						#$params1->append ( $params ) ;
						#$params 			= $params->merge('branch-id', $id );
						$url					= $url->query("branch-id=$id" .'&' . 
								Mojo::Util::url_unescape ( $params->to_string)) ; 

						$cell  = '<a href="'  ;
						$cell  .= "$base" . $path . '?'. $query . '">' ; 
						$cell  .= $id . '</a>' ; 
					}

					$row_html .= '<td>' . $cell . '</td>' ; 
				}
				$i++ ;
			}
			$row_html	= '<tr>' . $row_html . '</tr>' ;
			$table_body .= $row_html ; 
			$i++ ;
		}
		$table .= $table_body . '</tbody>' ; 
		$table  .= '</table>
			</div>
		' ;
		# stop -- building the header 

		return $table ; 
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
		
		my $table_conf		= '"aoColumnDefs" : [' ; 
		my $tbles_vis_cnf = '' ; 


		foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
		
			my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
			my $column_num = $rs_meta->{$i}->{'ORDINAL_POSITION'} - 1; 
			my $col_width = '10' ; 
			$col_width = $rs_meta->{$i}->{'CHARACTER_MAXIMUM_LENGTH'} 
				if $rs_meta->{$i}->{'DATA_TYPE'} eq 'varchar' ; 
			$col_width = $rs_meta->{$i}->{'NUMERIC_PRECISION'} 
				if $rs_meta->{$i}->{'DATA_TYPE'} eq 'bignt' ; 
			$col_width = 2*$col_width ; 

			my $row_conf		 = '{ ' ; 
			$row_conf			.= '"bSortable":true ' ;  
			$row_conf			.= ',"bSearchable":true ' ; 
			# because  there are 4 links
			my $visib_column_num	= $i + 6 ; 
			 $tbles_vis_cnf		.= 'objNiceTable.fnSetColumnVis(' . $visib_column_num . ',false) ;' 
			 if ( $column_name eq 'LeftRank' or $column_name eq 'RightRank' or $column_name eq 'DocId' );

			$row_conf			.= ',"sWidth":"' . $col_width . 'px"' ; 
			$row_conf			.= ',"aTargets":[' . $column_num . ']' ;  
			$row_conf			.= ' },' ; 


			$table_conf			.= $row_conf ; 
			$i++ ;
		}
		#eof foreach rs_meta key
	
		chop($table_conf);
		$table_conf			.= ']' ; 

		return ( $table_conf , $tbles_vis_cnf );

	}
	#eof sub doConfigureControl

   #
   # -----------------------------------------------------------------------------
   # doInitialize the object with the minimum data it will need to operate 
   # -----------------------------------------------------------------------------
   sub doInitialize {

      my $self = shift ; 
		
		# get the application configuration hash
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

LinkActionTableBuilder

=head1 SYNOPSIS

use MariaDbWrapper
  
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
