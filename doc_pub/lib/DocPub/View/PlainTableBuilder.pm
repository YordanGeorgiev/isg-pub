package DocPub::View::PlainTableBuilder ; 

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
	   my @cols_to_hide	= split( ',' , $params->param('hide'));

		my $num_of_rs_meta_el = scalar(keys %$rs_meta ) ; 
		my $new_last_el	= $num_of_rs_meta_el ; 
		$rs_meta->{$new_last_el}->{'COLUMN_NAME'} = 'ActionButtons' ; 
		$rs_meta->{$new_last_el}->{'DATA_TYPE'} = 'bigint' ; 
		$rs_meta->{$new_last_el}->{'NUMERIC_PRECISION'} = 15 ; 
		$rs_meta->{$new_last_el}->{'CHARACTER_MAXIMUM_LENGTH'} = 9 ; 

		unless ( $rs_meta or $rs ) {
		$table= '
			<table id="txt_query" class="inline_table display responsive">
			<tr><td> No results yet ... </td></tr>
			</table>
		' ; 
			return ; 
		}

		# start -- building the header 
		my $i 				= 1 ; 
		$table				= ' 
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
			#$col_width = 2*$col_width ; 
			#$style .= 'width:' . $col_width . 'px;' ;
			$style .= 'width:auto;' ; 
			#$style .= 'display:none;'
			#if ( $column_name eq 'LeftRank' or $column_name eq 'RightRank' or $column_name eq 'DocId' );

			$style .= '"' ; 
			
			$table .= '<th' . $style . '>' . $column_name . '</th>' 
			unless ( 
						$column_name eq 'LeftRank' 
					or $column_name eq 'RightRank' 
					or $column_name eq 'DocId' 
					or $column_name eq 'SrcCode' 
					or $column_name eq 'FileType' 
               or grep( /^$column_name$/, @cols_to_hide ) > 0
				);
			$i++ ;
		}
					
		#$table 			.= '<th>buttons</th>' ; 
		$table .= '</tr>
				</thead>' ; 
		# stop  -- building the header 
	

		# start -- building the body 
		$table .= '<tbody>' . "\n" ; 
		# p($rs ) ; 
		my $last_cell = '' ; 
		foreach my $row ( @$rs )  {
			$table .= '<tr>' ;
			my $i = 1 ; 
			
			foreach my $num ( sort ( keys ( %$rs_meta ) )  ) {
			
				my $column_name = $rs_meta->{$i}->{'COLUMN_NAME'} ; 

				my $cell = ' ' ; 
				$cell = $row->{"$column_name"} ; 
				if ( $i == 1 ) {
					my $id 		= $cell ; 
					$cell 		= $id ;  
					
					$params 		= $params->remove('branch-id');
					$url			= $url->query("branch-id=$id" .'&' . 
							Mojo::Util::url_unescape ( $params->to_string)) ; 

					$last_cell   		= '<a href="'  ;
					$last_cell  		.= "$base" . $path . '?'. $query . '">' ; 
					$last_cell  		.= $id . '</a>' ; 
				} 
				
				$cell = $last_cell if ( $i == $num_of_rs_meta_el  ); 
				$cell = ' ' unless $cell ; 
				my $td_class = '' ; 
				# if using linkify
				#$td_class = ' class="desc" ' if $column_name eq 'Description' ; 
				#$cell		= DocPub::View::HtmlHandler::text2html ( $cell ) 
				#	if ( $column_name eq 'Description' ) ; 
				# 
				# if the ColumnName is not set to be hidden
				$table .=  '<td' . $td_class . '>' . $cell . '</td>'   
				unless ( 
						$column_name eq 'LeftRank' 
					or $column_name eq 'RightRank' 
					or $column_name eq 'DocId' 
					or $column_name eq 'SrcCode' 
					or $column_name eq 'FileType' 
               or grep( /^$column_name$/, @cols_to_hide ) > 0
						);
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
		my $params			= $objController->req->query_params ; 
	   my @cols_to_hide	= split( ',' , $params->param('hide'));
		my $i						= 1 ; 
		
		my $table_conf			= '' ; 
		my $tbl_col_defs		= '"aoColumnDefs" : [' ; 
		my $tbles_vis_cnf 	= 'var table = $(\'#nice_table\').DataTable();' ; 
		my $table_labels  	= '' ; 
		my $col_definitions  = '' ; 
		my $columnDefs			= "\n" . ', "columnDefs": [' ; 
		
		my $num_of_rs_meta_el = scalar(keys %$rs_meta ) ; 
		my $new_last_el	= $num_of_rs_meta_el ; 
		$rs_meta->{$new_last_el}->{'COLUMN_NAME'} = 'ActionButtons' ; 
		$rs_meta->{$new_last_el}->{'DATA_TYPE'} = 'bigint' ; 
		$rs_meta->{$new_last_el}->{'NUMERIC_PRECISION'} = 15 ; 
		$rs_meta->{$new_last_el}->{'CHARACTER_MAXIMUM_LENGTH'} = 9 ; 

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

			if (     
						$column_name eq 'LeftRank' 
					or $column_name eq 'RightRank' 
					or $column_name eq 'DocId' 
					or $column_name eq 'SrcCode' 
					or $column_name eq 'FileType' 
               or grep( /^$column_name$/, @cols_to_hide ) > 0
					
					) {
				$visibility		 = 'true' ; 	
				$searchable		 = 'true' ; 	
			}
			$column_num			 = $column_num ;
			$tbles_vis_cnf		.= 'table.column( ' . $column_num . ').visible( ' . $visibility . ' ) ; ' ; 

			$columnDefs			.= '
				{
					"targets": ' . $column_num . ',
					"visible": ' . $visibility . ' ,' ; 
			$columnDefs			.= '"sType": "html",' if $column_name eq 'Description' ; 
			$columnDefs			.= '"searchable": ' . $searchable . '},' ; 

			$row_conf			.= ',"sWidth":"' . $col_width . 'px"' ; 
			$row_conf			.= ',"targets":' . $column_num . '' ;  
			$row_conf			.= ' },' ; 


			$tbl_col_defs		.= $row_conf ; 
			# convert the type of the control to textaread and not the default text input
			my $type_of_control = '' ; 
			$type_of_control = 'type: "textarea",' if ( 
							$column_name eq 'Description' ) ; 

			#next if $column_name eq 'ActionButtons' ; 

			$table_labels 		.= '{' . 
                "$type_of_control" . 
					 'label: "' . $column_name . '",
                 name: "'  . $column_name . '"
            },'  
			unless ( 
						$column_name eq 'LeftRank' 
					or $column_name eq 'RightRank' 
					or $column_name eq 'DocId' 
					or $column_name eq 'SrcCode' 
					or $column_name eq 'FileType' 
               or grep( /^$column_name$/, @cols_to_hide ) > 0
				);

			$col_definitions 	.= '
			{ data: "' . $column_name . '"},'   
			unless ( 
						$column_name eq 'LeftRank' 
					or $column_name eq 'RightRank' 
					or $column_name eq 'DocId' 
					or $column_name eq 'SrcCode' 
					or $column_name eq 'FileType' 
               or grep( /^$column_name$/, @cols_to_hide ) > 0
				);

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
		$columnDefs			= '' ; 
		#$table_conf			.= "\n" . '"columns":[' ; 
		$table_conf			.= "\n" . '"columns":[' . "\n" ; 
#		{
#			data: null,
#			defaultContent: \'\',
#			className: \'select-checkbox\',
#			orderable: false
#		},
		$table_conf .= $col_definitions . ']' ; 
#	   {
#			data: null,
#			className: "center",
#			defaultContent: \'<a href="" class="editor_edit">Edit</a> / <a href="" class="editor_remove">Delete</a>\'
#		},
		
		#$table_conf			.= $columnDefs ; 
		$tbles_vis_cnf 		= '' ; 
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

PlainTableBuilder

=head1 SYNOPSIS

use DocPub::View::PlainTableBuilder ; 
  
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
