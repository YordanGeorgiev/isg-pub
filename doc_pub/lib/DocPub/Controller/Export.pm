package DocPub::Controller::Export ; 

use utf8 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;

use Data::Printer ; 

use DocPub::Model::ConverterFactory ; 
use DocPub::Model::DbHandlerFactory ; 
use DocPub::View::ControlFactory ; 
use Mojolicious::Plugin::RenderFile ; 

our $app_config  ; 
our $objLogger ; 

#
# ---------------------------------------------------------
# add the showsub action in the Show controller 
# ---------------------------------------------------------
sub export_items {
	#debug print '@ doc_pub/lib/DocPub/Controller/Export.pm sub export_items' . "\n" ; 
   my $self = shift;

	# global app config hash
	$app_config 				= $self->app->get('AppConfig') ; 
	$objLogger 					= $self->app->get('ObjLogger');
	my $web_host 				= $app_config->{'web_host'} ;
	my $web_port 				= $app_config->{'web_port'} ;
	# could be: 
	# to=pdf
	# to=xls
	# to=githubmd
	my $convert_type			= $self->param('to');  # expect 'to-xls'
	$convert_type			   = 'export-to-' . $convert_type ; 

	# get url params 
	my $rdbms_type				= $self->param('rdbms') || 'mysql' ; 
	my $table 					= $self->param('item')  || 'Issue' ;
	my $db						= $self->param('db')		|| 'isg_pub_en' ; 

	# save to session so that the post could fetch them
	$self->session('rdbms' 	=> $rdbms_type);
	$self->session('db' 		=> $db);
	$self->session('item' 	=> $table);
	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

	# get the data from the Model
	my $rs_meta 				= $objDbHandler->list_items_meta ( $db , $table ) ;
	my $rs_images				= $objDbHandler->list_images_data ( $table ) ;
	#debug ok p($rs_meta);
	my $rs 						= $objDbHandler->list_items ($db , $table ) ;
	#ok print "from doc_pub/lib/DocPub/Controller/Export.pm print rs \n" ; 
	#p($rs ) ;

	#my $rs_titles 				= $objDbHandler->doListFoldersAndDocsTitles ($db ) ;
	#debug print ($rs_titles );

	my $objConverterFactory = 'DocPub::Model::ConverterFactory'->new( \$self );
	my $objConverter 			= $objConverterFactory->doInstantiate ( "$convert_type" );

	my $file 					= $objConverter->doConvert ( $db , $table, $rs_meta , $rs , $rs_images ) ; 

	$self->render_file('filepath' => "$file" );  

}
#eof sub list_table 



1;


__END__
