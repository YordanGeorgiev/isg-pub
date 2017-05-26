package DocPub::Controller::SearchAutocomplete ; 

use utf8 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;

use Data::Printer ; 

use DocPub::Model::DbHandlerFactory ; 
use DocPub::View::ControlFactory ; 

our $app_config  		= q{} ; 
our $objLogger 		= q{} ; 

#
# ---------------------------------------------------------
# add the showsub action in the Show controller 
# ---------------------------------------------------------
sub search_items {
	#debug print '@ doc_pub/lib/DocPub/Controller/List.pm sub list_items' . "\n" ; 
   my $self = shift;

	# global app config hash
	$app_config 			= $self->app->get('AppConfig') ; 
	$objLogger 				= $self->app->get('ObjLogger');
	my $web_host 			= $app_config->{'web_host'} ;
	my $web_app				= $app_config->{'web_app'} ; 

	# get url params 
	my $rdbms_type			= $self->param('rdbms') || 'mysql' ; 
	my $lang		 			= $self->param('lang')  || 'en' ; 
	my $database 			= $self->param('db')		|| 'isg_pub' . '_' . $lang ; 
	my $str_to_srch		= $self->param('term')	|| ' ' ; 

	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

	# get the data from the Model
	my $ref_query_output 						= q{} ; 

	if ( $str_to_srch 	=~ m/table/gi ) {
		$str_to_srch		=~ s/table\://gi ; 
		$ref_query_output = $objDbHandler->search_table_items_autocomplete ( $str_to_srch ) ;
	}
	else {
		$ref_query_output = $objDbHandler->search_items_names_and_descs_autocomplete ( $str_to_srch ) ;
		#$ref_query_output = { 'boo' => 'Bar' }  ;
	}

	$self->render(json => $ref_query_output );

}
#eof sub list_table 


1;


__END__
