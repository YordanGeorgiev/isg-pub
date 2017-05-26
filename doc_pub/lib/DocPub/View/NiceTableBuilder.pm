package DocPub::View::NiceTableBuilder ; 

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
		my $table 			= '' ; 	

		my $url 				= $objController->req->url ; 
		my $base 			= $url->base ; 
		my $query 			= $url->query;
		my $path 			= $url->path;
		my $params			= $objController->req->query_params ; 



		unless ( $rs_meta or $rs ) {
		$table= '
			<table id="txt_query" class="inline_table">
			<tr><td> No results yet ... </td></tr>
			</table>
		' ; 
			return ; 
		}

		# start -- building the header 
		my $i 				= 1 ; 
		$table			= ' 
			<div id="div_table">
				<table id="nice_table" class="inline_table">
				<thead>
					<tr>' ; 

		my @char_datatypes = qw ( varchar char );

		foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
			my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
			$column_name =~ s/_/ /g ; 
			my $data_type = $rs_meta->{$i}->{'DATA_TYPE'} ; 
			
			no if $] >= 5.017011, warnings => 'experimental::smartmatch';
			# nees arrays of datatypes 
			my $col_width = '10' ; 
			$col_width = $rs_meta->{$i}->{'CHARACTER_MAXIMUM_LENGTH'} 
				if /$data_type/i ~~ @char_datatypes ; 
			$col_width = $rs_meta->{$i}->{'NUMERIC_PRECISION'} 
				if $rs_meta->{$i}->{'DATA_TYPE'} eq 'bignt' ; 


			my $style = ' style="' ; 
			$col_width = 2*$col_width ; 
			$style .= 'width:' . $col_width . 'px;' ;
			$style .= 'display:none;'
			if ( $column_name eq 'LeftRank' or $column_name eq 'RightRank' or $column_name eq 'DocId' );

			$style .= '"' ; 
			$table .= '<th' . $style . '>' . $column_name . '</th>' ; 
			$i++ ;
		}
					
		$table .= '</tr>
				</thead>' ; 
		# stop  -- building the header 
	

		# start -- building the body 
		$table .= '<tbody>' . "\n" ; 
		# p($rs ) ; 
		foreach my $row ( @$rs )  {
			$table .= '<tr>' ;
			my $i = 1 ; 
			
			foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
			
				my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
				my $cell = '' ; 
				$cell = $row->{"$column_name"} ; 
				$cell = DocPub::View::HtmlHandler::text2html ( $cell ) 
					if $column_name eq 'Description' ; 

				if ( $i == 1 ) {

					my $id = $cell ; 
					$params 				= $params->remove('branch-id');
					my $str_params		= $params->to_string ; 
					my $ref_all_vals	= $objController->every_param('filter-value') ; 
					my $levels			= '' ; 	
					foreach my $level ( @$ref_all_vals ) {
						$levels 			.= $levels if ( $level =~ m/((\d)+(,)*)+/g )
					}
					my $latest_level	= $levels ; 
					$latest_level		=~ s/(.*),(\d)/$2/g ; 
					my $filter_value			= '0' ; 
					for ( my $i = 1 ; $i <= $latest_level ; $i++ ) { 
						$filter_value				.= ',' . $i ; 	
					}

					#debug jjprint "./doc_pub/lib/DocPub/View/NiceTableBuilder.pm :: filter_value $filter_value \n" ; 
					$url					= $url->query("branch-id=$id" .'&' . Mojo::Util::url_unescape ( $params->to_string)) ; 

					$cell  = '<a href="'  ;
					$cell  .= "$base" . $path . '?'. $query . '">' ; 
					$cell  .= $id . '</a>' ; 
				}

				$table .= '<td>' . $cell . '</td>' ; 
				$i++ ;
			}
			$table .= '</tr>' ;
			$i++ ;
		}
		$table  .= '
				</tbody>
			</table>
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

		my $self 				= shift ;
		my $table_name 		= shift ;
		my $rs_meta 			= shift ; 
		my $i						= 1 ; 
		
		my $table_conf			= '' ; 
		my $tbl_col_defs		= '"aoColumnDefs" : [' ; 
		my $tbles_vis_cnf 	= 'var table = $(\'#nice_table\').DataTable();' ; 
		my $table_labels  	= '' ; 
		my $col_definitions  = '' ; 
		#my $columnDefs			= "\n" . ', "columnDefs": [' ; 
		
		my $columnDefs			= "\n" . ', "ColumnDefs" : [
		{  "targets": -1,
			"data": null,
			"defaultContent": "<button>Click!</button>"
		},
		' ; 

		foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
		
			my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 
			my $column_num = $rs_meta->{$i}->{'ORDINAL_POSITION'} - 1; 
			my $col_width = '10' ; 
			$col_width = $rs_meta->{$i}->{'CHARACTER_MAXIMUM_LENGTH'} 
				if $rs_meta->{$i}->{'DATA_TYPE'} eq 'varchar' ; 
			$col_width = $rs_meta->{$i}->{'NUMERIC_PRECISION'} 
				if $rs_meta->{$i}->{'DATA_TYPE'} eq 'bignt' ; 
			$col_width = 2*$col_width ; 

			my $row_conf		 = "\n" . '{ ' ; 
			$row_conf			.= '"bSortable":true ' ;  
			$row_conf			.= ',"bSearchable":true ' ; 
			my $visibility		 = 'true' ; 
			my $searchable 	 = 'true' ; 

			if ( $column_name eq 'LeftRank' 
					or $column_name eq 'RightRank' 
					or $column_name eq 'FileType' 
					or $column_name eq 'DocId' ) {
				$visibility		 = 'false' ; 	
				$searchable		 = 'false' ; 	
			}

			$tbles_vis_cnf		.= 'table.column( ' . $column_num . ').visible( ' . $visibility . ' ) ; ' ; 
			$columnDefs			.= '
				{
					"targets": [' . $column_num . '],
					"visible": ' . $visibility . ' ,' ; 
			$columnDefs			.= '"sType": "html",' if $column_name eq 'Description' ; 
			$columnDefs			.= '"searchable": ' . $searchable . '},' ; 

			$row_conf			.= ',"sWidth":"' . $col_width . 'px"' ; 
			$row_conf			.= ',"targets":' . $column_num . '' ;  
			$row_conf			.= ' },' ; 


			$tbl_col_defs		.= $row_conf ; 

			$table_labels 		.= '{
                label: "' . $column_name . '",
                name: "' . $column_name . '"
            },' ; 
			$col_definitions 	.= '
			{ data: "' . $column_name . '"},' ; 

			$i++ ;
		}
		#eof foreach rs_meta key
	
		chop($table_conf);
		chop($table_labels) ; 
		chop($col_definitions) ; 
		chop($tbl_col_defs) ; 
		chop($columnDefs) ; 

		#$table_conf			.= $tbl_col_defs . ']' ; 
		$columnDefs 		.= ']' . "\n  " ; 
		$table_conf			.= "\n" . '"columns":[' . $col_definitions . ']' ; 
		$table_conf			.= $columnDefs ; 

		return ( $table_conf , $tbles_vis_cnf , $table_labels );

	}
	#eof sub doConfigureControl


   #
   # -----------------------------------------------------------------------------
   # doInitialize the object with the minimum data it will need to operate 
   # -----------------------------------------------------------------------------
   sub doInitialize {

      my $self = shift ; 
		
		# get the application configuration hash
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

NiceTableBuilder

=head1 SYNOPSIS

use DocPub::View::NiceTableBuilder ; 
  
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
