package DocPub::Controller::List ; 

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
	my $web_port 				= $app_config->{'web_port'} ;

	# get url params 
	my $rdbms_type				= $self->param('rdbms') || 'mysql' ; 
	my $table 					= $self->param('item')  || 'Issue' ;
	my $database 				= $self->param('db')		|| 'isg_pub_en' ; 
	my $url_params				= $self->req->query_params  ; 
	$url_params					= Mojo::Util::url_unescape ( $url_params->to_string ) ; 
	my $left_menu_control	= '' ; 
	#todo_remove my $rs_titles				= {} ; 
	my $item						= $table ; 

	# save to session so that the post could fetch them
	$self->session('rdbms' 	=> $rdbms_type);
	$self->session('db' 		=> $database );
	$self->session('item' 	=> $table);
	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );
	# get the logical structure of the application e.g. all the pages
	$objDbHandler->doGetItemViews();

	# get the data from the Model
	my $res_meta 				= $objDbHandler->list_items_meta ( $database , $table ) ;
	my $res 						= $objDbHandler->list_items ($database , $table ) ;
	#todo_remove $rs_titles 					= $objDbHandler->doListFoldersAndDocsTitles ($database ); 


	# build the View
	my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objControlBuilder 	= () ; 
	my $objLeftMenuBuilder  = () ;
	my $debug_msg 				= '' ; 

	$debug_msg					= $self->stash('debug_msg') || '' ; 


	# this is UGLY , but for  now ... must live with it ... 
	$objControlBuilder 		= $objControlFactory->doInstantiate ( "plain_table" ) 
		unless ( $table eq 'Position' or $table eq 'PositionHistory' ) ; 

	$objControlBuilder 		= $objControlFactory->doInstantiate ( "link_action_table" ) 
		if ( $table eq 'Position' or $table eq 'PositionHistory' ) ; 

	$objLeftMenuBuilder  	= $objControlFactory->doInstantiate ( "left_menu" ) ;

	my $str_table 				= $objControlBuilder->doBuildControl( "$table" , $res_meta , $res , 'list' );
	my ( $table_conf,$tbl_cols_vis , $table_labels) 
			= $objControlBuilder->doConfigureControl( "$table" , $res_meta );
	

	# build the doc content
	$left_menu_control 		= $objLeftMenuBuilder->doBuildControl( 'list' );

	# and render the result
  	$self->render(
		template 				=> 'actions/list/page/status/status_page'  
	 , table 					=> $table 
	 , item 						=> $item
	 , database 				=> $database
	 , web_host 				=> $web_host
	 , web_port 				=> $web_port
	 , str_table 				=> $str_table
	 , table_conf 				=> $table_conf
	 , tbl_cols_vis			=> $tbl_cols_vis
	 , table_labels 			=> $table_labels 
	 , url_params 				=> $url_params
	 , debug_msg				=> $debug_msg
	 , left_menu_control		=> $left_menu_control
	);

}
#eof sub list_table 

#
# ---------------------------------------------------------
# add the showsub action in the Show controller 
# ---------------------------------------------------------
sub edit_item {
	print '@ doc_pub/lib/DocPub/Controller/List.pm sub edit_item' . "\n" ; 
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
	p($hash ) ; 

	#foreach my $key ( keys ( %{$hash} ) ) {
		#print "key" . "\n" ; 
		#p($key ) ; 
		#print "value" . "\n" ; 
		#p($hash->{"$key"} ) ; 
	#}
	#eof foreach key

	# update the item
	my $ref_query_output				= $objDbHandler->edit_item ( $database , $table , $hash ) ;


	$self->res->headers->accept_charset('UTF-8');
	# quickly visualize the json output @: http://json.bloople.net/
	$self->res->headers->content_type('application/json; charset=utf-8');
	
	$self->render(json => $ref_query_output );

	p($ref_query_output);

	return  $ref_query_output; 

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
	#$url_params		= Mojo::Util::url_unescape ( $url_params->to_string ) ; 
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
	my $res_meta 		= $objDbHandler->list_items_meta ( $database , $table ) ;
	my $post_hash 		= $self->req->body_params->to_hash;
	# the data tables js control passes the vars in a specific format
	print "List.pm  remove_item after post \n" ; 
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

1;


__END__
