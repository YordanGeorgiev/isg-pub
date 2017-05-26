package DocPub::Controller::Remove ;  

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
sub delete_item {
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

	my $hash = $self->req->params->to_hash;
	# update the item
	my $ref_query_output		= $objDbHandler->delete_item ( $database , $table , $hash ) ;
	
	
	# get the data from the Model
	my $res_meta 				= $objDbHandler->list_items_meta ( $database , $table ) ;


	#p($hash ) ; 


	$self->res->headers->accept_charset('UTF-8');
	$self->res->headers->accept_language('fi, en') ; 
	# quickly visualize the json output @: http://json.bloople.net/
	$self->res->headers->content_type('application/json; charset=utf-8');
	
	$self->render(json => $ref_query_output );

	#debug p($ref_query_output);

	return  $ref_query_output; 


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
