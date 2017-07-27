package DocPub::Controller::Query ; 

use utf8 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;

use Data::Printer ; 

use DocPub::Model::DbHandlerFactory ; 

our $app_config  				= q{} ; 
our $objLogger 				= q{} ; 
our $rdbms_type 				= 'mysql' ; 


sub show_query_ui {

	my $self = shift ; 
	
	$app_config 	= $self->app->get('AppConfig');
	$objLogger 		= $self->app->get('ObjLogger');
	
	my $table 					= ' ' ; 
	my $database 				= ' ' ; 
	my $web_host 				= ' ' ; 
	my $str_table 				= ' ' ; 
	my $str_textarea 			= ' ' ; 
	my $str_go_button 		= ' ' ; 
	my $conn_hook 				= $self->req->query_params->param('conn');
	my $schema 					= $self->req->query_params->param('schema');

	my $res_meta 				= $self->session->{'ResMeta'} 	|| q{} ; 
	my $res 		 				= $self->session->{'Res'} 		|| q{} ; 
	
	$rdbms_type		= $self->param('rdbms') 		|| 'mysql' ; 
	#debug print '@show_query_ui rdbms_type:: ' . $rdbms_type ; 
	
	my $sql						= '' ; #$self->param("txt_query") || '' ; 
	my $str_sql = $sql ; 
	$str_sql =~ s|"|\"|g ; 

	;


	if ( $res_meta or $res ) {
		$str_table = '
			<table id="txt_query" class="inline_table">
			<tr><td> No results yet ... </td></tr>
			</table>
		' 
	}
	else {

		# build the View
		my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
		my $objControlBuilder 	= q{} ; 
		# this is UGLY , but for  now ... must live with it ... 
		$objControlBuilder 		= $objControlFactory->doInstantiate ( "nice_table" ) 
			unless ( $table eq 'Position' or $table eq 'PositionHistory' ) ; 
		$objControlBuilder 		= $objControlFactory->doInstantiate ( "link_action_table" ) 
			if ( $table eq 'Position' or $table eq 'PositionHistory' ) ; 

		$str_table 					= $objControlBuilder->doBuildControl( "$table" , $res_meta , $res );
	}
	
	$str_go_button = '
		<input id="but_go" type="submit" value="Go"></input>'
	; 

	#hinto to the post action the type of the rdms fetched from the get url param
	$str_go_button .= '<input type="hidden" name="rdbms" value="' . $rdbms_type . '"></input>' . "\n" ; 
	$str_go_button .= '<input type="hidden" name="conn" value="' . $conn_hook . '"></input>' . "\n" ;  
	$str_go_button .= '<input type="hidden" name="schema" value="' . $schema . '"></input>' . "\n" ;  
	#$str_go_button .= '<input type="hidden" name="txt_query" value="' . $str_sql. '"></input>' . "\n" ;  
	
	# and render the result
  	$self->render(
		str_sql 			=> $str_sql
	 , str_go_button  => $str_go_button
	 , table 			=> $table 
	 , database 		=> $database
	 , web_host 		=> $web_host
	 , str_table 		=> $str_table
	 , rdbms_type 		=> $rdbms_type
	);

	
}
#eof sub show_query_ui


#
# ---------------------------------------------------------
# add the showsub action in the Show controller 
# ---------------------------------------------------------
sub list_query_data {
	#debug print '@ doc_pub/lib/DocPub/Controller/Query.pm sub query_items' . "\n" ; 
   my $self = shift;

	# get the application configuration hash
	# global app config hash
	$app_config 	= $self->app->get('AppConfig');
	$objLogger 		= $self->app->get('ObjLogger');


	my $web_host 		= $app_config->{'web_host'} ;
	# get url params 
	$rdbms_type			= $self->param('rdbms') || 'mysql' ; 
	my $str_sql			= $self->param("txt_query"); 
	unless ( $str_sql ) {
		$str_sql			= $self->session("txt_query");
	}
	$self					= $self->session( {	"txt_query" => $str_sql } );

	my $conn_hook 		= $self->req->body_params->param('conn');
	my $schema 			= $self->req->body_params->param('schema');
	
	
	# get url params 
	my $table = ' ' ; 
	my $database = ' ' ; 
	my $str_table = ' ' ; 
	my $str_textarea = ' ' ; 
	my $str_go_button = ' ' ; 


	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

	# get the data from the Model
	my $res 						= $objDbHandler->list_query_data ( $str_sql) ;
	my $res_meta				= $objDbHandler->get('ResMeta') ; 

	$self->session('ResMeta' => $res_meta);
	$self->session('Res' => $res);


	# build the View json
	my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objControlBuilder 	= q{} ; 
	# this is UGLY , but for  now ... must live with it ... 
	$objControlBuilder 		= $objControlFactory->doInstantiate ( "nice_s_table" ) ;
	$str_table 					= $objControlBuilder->doBuildControl( "$table" , $res_meta , $res );
	$str_sql =~ s/"/\\"/g ; 

	;
	
	$str_go_button = '
		<input id="but_go" type="submit" value="Go"></input>'
	; 
	#hinto to the post action the type of the rdms fetched from the get url param
	$str_go_button .= '<input type="hidden" name="rdbms" value="' . $rdbms_type . '">' ; 
	$str_go_button .= '<input type="hidden" name="conn" value="' . $conn_hook . '"></input>' . "\n" ;  
	$str_go_button .= '<input type="hidden" name="schema" value="' . $schema . '"></input>' . "\n" ;  
	$str_go_button .= '<input type="hidden" name="str_sql" value="' . $str_sql. '"></input>' . "\n" ;  

	# and render the result
  	$self->render(
		table 			=> $table 
	 , str_sql 			=> $str_sql
	 , database 		=> $database
	 , web_host 		=> $web_host
	 , str_table 		=> $str_table
	 , str_textarea	=> $str_textarea
	 , str_go_button  => $str_go_button
	 , rdbms_type 		=> $rdbms_type
	);

}
#eof sub query_table 


1;


__END__
