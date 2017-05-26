package DocPub::Controller::Edit ; 

use utf8 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;

use Data::Printer ; 

use DocPub::Model::DbHandlerFactory ; 
use DocPub::View::ControlFactory ; 

our $app_config  ; 
our $objLogger ; 

#
# ---------------------------------------------------------
# add the showsub action in the Show controller 
# ---------------------------------------------------------
sub list_items {
	#debug print '@ doc_pub/lib/DocPub/Controller/List.pm sub list_items' . "\n" ; 
   my $self = shift;

	# global app config hash
	# global app config hash
	$app_config 				= $self->app->get('AppConfig') ; 
	$objLogger 					= $self->app->get('ObjLogger');
	my $web_host 				= $app_config->{'web_host'} ;

	# get url params 
	my $rdbms_type				= $self->param('rdbms') || 'mysql' ; 
	my $table 					= $self->param('item')  || 'Issue' ;
	my $database 				= $self->param('db')		|| 'isg_pub_en' ; 
	my $url_params				= $self->req->query_params  ; 
	$url_params					= Mojo::Util::url_unescape ( $url_params->to_string ) ; 

	# save to session so that the post could fetch them
	$self->session('rdbms' 	=> $rdbms_type);
	$self->session('db' 		=> $database );
	$self->session('item' 	=> $table);
	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

	# get the data from the Model
	my $res_meta 				= $objDbHandler->list_items_meta ( $database , $table ) ;
	my $res 						= $objDbHandler->list_items ($database , $table ) ;

	# build the View
	my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objControlBuilder 	= () ; 

	# this is UGLY , but for  now ... must live with it ... 
	$objControlBuilder 		= $objControlFactory->doInstantiate ( "plain_table" ) 
		unless ( $table eq 'Position' or $table eq 'PositionHistory' ) ; 

	$objControlBuilder 		= $objControlFactory->doInstantiate ( "link_action_table" ) 
		if ( $table eq 'Position' or $table eq 'PositionHistory' ) ; 

	my $str_table 				= $objControlBuilder->doBuildControl( "$table" , $res_meta , $res );
	my ( $table_conf,$tbl_cols_vis , $table_labels) 
			= $objControlBuilder->doConfigureControl( "$table" , $res_meta );

	# and render the result
  	$self->render(
		table 			=> $table 
	 , database 		=> $database
	 , web_host 		=> $web_host
	 , str_table 		=> $str_table
	 , table_conf 		=> $table_conf
	 , tbl_cols_vis	=> $tbl_cols_vis
	 , table_labels 	=> $table_labels 
	 , url_params		=> $url_params
	);

}
#eof sub list_table 


#
# ---------------------------------------------------------
# this method is called from ajax when deleting item from list page 
# ---------------------------------------------------------
sub remove_item {
	#debug print '@ doc_pub/lib/DocPub/Controller/List.pm sub list_items' . "\n" ; 
   my $self = shift;

	# global app config hash
	$app_config 		= $self->app->get('AppConfig') ; 
	$objLogger 			= $self->app->get('ObjLogger');
	my $web_host 		= $app_config->{'web_host'} ; # get url params 
	my $url_params		= $self->req->query_params  ; 
	#$url_params					= Mojo::Util::url_unescape ( $url_params->to_string ) ; 
	my $url 				= $self->req->url ; 
	my $base 			= $url->base ; 
	my $query 			= $url->query;
	my $path 			= $url->path;
	

	my $rdbms_type		= $self->session('rdbms') || 'mysql' ; 
	my $table 			= $self->session('item')  || 'Issue' ;
	my $database 		= $self->session('db')	  || 'isg_pub_en' ; 

	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

	# get the data from the Model
	my $res_meta 				= $objDbHandler->list_items_meta ( $database , $table ) ;
	my $post_hash = $self->req->body_params->to_hash;
	# the data tables js control passes the vars in a specific format
	print "Edit.pm  remove_item after post \n" ; 
	p($post_hash ) ; 

	#my $hash = $self->req->params ; 

	# update the item - update the db with  the post vals, fetch arr ref of hash refs 
	$objDbHandler->remove_item ( $database , $table , $post_hash ) ; 
	
	my $ref_json_hash->{'data'} = []  ; 

	$self->res->headers->accept_charset('UTF-8');
	$self->res->headers->accept_language('fi, en') ; 
	$self->res->headers->content_type('application/json; charset=utf-8');
	$self->render(json => $ref_json_hash );

	p( $ref_json_hash ) ; 

	return  $ref_json_hash ; 
}
#eof sub remove_item

#
# ---------------------------------------------------------
# this method is called from ajax when updating item from list page 
# ---------------------------------------------------------
sub edit_item {
	#debug print '@ doc_pub/lib/DocPub/Controller/List.pm sub list_items' . "\n" ; 
   my $self = shift;

	# global app config hash
	# global app config hash
	$app_config 	= $self->app->get('AppConfig') ; 
	$objLogger 		= $self->app->get('ObjLogger');
	my $web_host 		= $app_config->{'web_host'} ; # get url params 
	my $url_params				= $self->req->query_params  ; 
	#$url_params					= Mojo::Util::url_unescape ( $url_params->to_string ) ; 
	my $url 				= $self->req->url ; 
	my $base 			= $url->base ; 
	my $query 			= $url->query;
	my $path 			= $url->path;
	

	my $rdbms_type		= $self->session('rdbms') || 'mysql' ; 
	my $table 			= $self->session('item')  || 'Issue' ;
	my $database 		= $self->session('db')	  || 'isg_pub_en' ; 

	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

	# get the data from the Model
	my $res_meta 				= $objDbHandler->list_items_meta ( $database , $table ) ;
	my $post_hash = $self->req->body_params->to_hash;
	# the data tables js control passes the vars in a specific format
	print "Edit.pm  edit_item after post \n" ; 
	p($post_hash ) ; 

	#my $hash = $self->req->params ; 

	# update the item - update the db with  the post vals, fetch arr ref of hash refs 
	my $ref_arr_out			= $objDbHandler->edit_item ( $database , $table , $post_hash ) ; 
	#debug print "Edit.pm::edit_item ref_arr_out" . $ref_arr_out ; 

	# start build the ActionLink as in the Control builder	
	my @arr						= @$ref_arr_out ; 
	my $data_hash				= {} ; 
	my $i = -1 ; 
	foreach my $ar_item ( @arr ) {
		$i++ ;
		next unless exists $ar_item->{'ActionButtons'} ; 
		$data_hash = $ar_item ; 
 		delete $arr[$i];
	}

	my $id 		= '' ; 
	$id = $data_hash->{ $table . 'Id' } ; 
	my $last_cell	= '' ; 
	
	$url_params = $url_params->remove('branch-id');
	$url			= $url->query("branch-id=$id" .'&' . 
			Mojo::Util::url_unescape ( $url_params->to_string)) ; 

	$last_cell   		 = '<a href="'  ;
	$last_cell  		.= "$base" . $path . '?'. $query . '">' ; 
	$last_cell  		.= $id . '</a>' ; 

	$data_hash->{ 'ActionButtons' } = $last_cell ; 
	push ( @arr , $data_hash ) ; 
	# stop  build the ActionLink as in the Control builder	
	
	# this is the format the datatables js control is expecting 
	my $ref_json_hash->{'data'} = [ @arr ]  ; 

	$self->res->headers->accept_charset('UTF-8');
	$self->res->headers->accept_language('fi, en') ; 
	$self->res->headers->content_type('application/json; charset=utf-8');
	$self->render(json => $ref_json_hash );

	#debug p( $ref_json_hash ) ; 

	return  $ref_json_hash ; 
}
#eof sub edit_item

#
# ---------------------------------------------------------
# add the showsub action in the Show controller 
# ---------------------------------------------------------
sub add_new_item {
	#debug print '@ doc_pub/lib/DocPub/Controller/List.pm sub list_items' . "\n" ; 
   my $self = shift;

	# global app config hash
	# global app config hash
	$app_config 	= $self->app->get('AppConfig') ; 
	$objLogger 		= $self->app->get('ObjLogger');
	my $web_host 		= $app_config->{'web_host'} ; # get url params 
	

	my $rdbms_type		= $self->session('rdbms') || 'mysql' ; 
	my $table 			= $self->session('item')  || 'Issue' ;
	my $database 		= $self->session('db')	  || 'isg_pub_en' ; 

	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

	# get the data from the Model
	my $res_meta 				= $objDbHandler->list_items_meta ( $database , $table ) ;


	my $hash = $self->req->params->to_hash;
	#debug p($hash ) ; 

	# update the item
	my $ref_query_output				= $objDbHandler->add_new_item ( $database , $table , $hash ) ;

	$self->res->headers->accept_charset('UTF-8');
	$self->res->headers->accept_language('fi, en') ; 
	# quickly visualize the json output @: http://json.bloople.net/
	$self->res->headers->content_type('application/json; charset=utf-8');
	
	$self->render(json => $ref_query_output );

	p($ref_query_output);

	return  $ref_query_output; 


}
#eof sub edit_item

# called from the view page only when id and value params are passed from UI
sub edit_items_description {
	my $self = shift ; 

}


1;


__END__
