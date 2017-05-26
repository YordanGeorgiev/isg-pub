package DocPub::Controller::PresentView; 

use utf8 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;

use Data::Printer ; 

use DocPub::Model::DbHandlerFactory ; 
use Carp ; 

our $app_config  ; 
our $objLogger ; 
our $doWhiteSpace = 1 ; 


#
# ---------------------------------------------------------
# add the showsub action in the Show controller 
# ---------------------------------------------------------
sub view_item_doc {
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

	my $ret						= 1 ; 
	my $msg						= '' ; 
	my $debug_msg				= '' ; 
	my $doc_control			= '' ; 
	my $doc_control_conf		= '' ; 
	my $top_menu				= '' ; 
	my $top_menu_conf			= '' ; 
	my $objControlBuilder 	= () ; 
	my $objControlFactory 	= () ; 

	$self->stash('DoWhiteSpace' , $doWhiteSpace );

	# save to session so that the post could fetch them
	$self->session('rdbms' 	=> $rdbms_type);
	$self->session('db' 		=> $database );
	$self->session('item' 	=> $table);
	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

	# get the data from the Model
	my $res_meta 				= $objDbHandler->list_items_meta ( $database , $table ) ;
	my $res 						= () ; 
	
	#2 ways of retrieving a doc - top bottom and bottom top in hierarchy
	if ( $self->param('path-id' ) ) {
		$res = $objDbHandler->list_doc_items_bottom_up ($database , $table ) ;
	}
	else {
		$res = $objDbHandler->list_doc_items ($database , $table ) ;
	}

	$objControlFactory 		= 'DocPub::View::ControlFactory'->new( \$self );
	$objControlBuilder 		= $objControlFactory->doInstantiate ( "presentation" ) ;
	
	# build the doc content
	$doc_control 				= $objControlBuilder->doBuildControl( $res_meta , $res );
	$doc_control_conf 		= $objControlBuilder->doConfigureControl( $res_meta );


	
	$msg = '' ; 

	$self->build_present_item_doc ( $msg , $web_host , $web_port , $database , $table , $doc_control , $top_menu ) ; 

}
#eof sub list_table 


sub get_view_item_doc_data {
	my $self = shift ; 

}
#sub get_view_item_doc_data {



sub build_present_item_doc {

	my $self 			= shift ; 
	my $msg 				= shift ; 
	my $web_host 		= shift ; 
	my $web_port 		= shift ; 
	my $database 		= shift ; 
	my $item 			= shift ; 
	my $control			= shift ;
	my $top_menu		= shift ;

	# build the View
	my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objControlBuilder 	= () ; 
	
	# and render the result
  	$self->render(
		template 		=> 'actions/present/page/doc/doc_page'  
	 , web_host 		=> $web_host
	 , web_port 		=> $web_port
	 , database 		=> $database
	 , doc_control		=> $control
	 , top_menu			=> $top_menu
	 ,	item 				=> $item 
	 ,	msg				=> $msg
	);

}
# sub build_present_item_doc 

	sub AUTOLOAD {

		my $self = shift;
		no strict 'refs';
		my $name = our $AUTOLOAD;
		*$AUTOLOAD = sub {
			my $msg =
			  "BOOM! BOOM! BOOM! \n RunTime Error !!! \n Undefined Function $name(@_) \n ";
			croak "$self , $msg $!";
		};
		goto &$AUTOLOAD;    # Restart the new routine.
	}   
	# eof sub AUTOLOAD


	# -----------------------------------------------------------------------------
	# return a field's value
	# -----------------------------------------------------------------------------
	sub get {

		my $self = shift;
		my $name = shift;
		croak "\@PresentView.pm sub get TRYING to get undefined name" unless $name ;  
		croak "\@PresentView.pm sub get TRYING to get undefined value" unless ( $self->{"$name"} ) ; 

		return $self->{ $name };
	}    #eof sub get


	# -----------------------------------------------------------------------------
	# set a field's value
	# -----------------------------------------------------------------------------
	sub set {

		my $self  = shift;
		my $name  = shift;
		my $value = shift;
		$self->{ "$name" } = $value;
	}
	# eof sub set


	# -----------------------------------------------------------------------------
	# return the fields of this obj instance
	# -----------------------------------------------------------------------------
	sub dumpFields {
		my $self      = shift;
		my $strFields = ();
		foreach my $key ( keys %$self ) {
			$strFields .= " $key = $self->{$key} \n ";
		}

		return $strFields;
	}    
	# eof sub dumpFields
		

	# -----------------------------------------------------------------------------
	# wrap any logic here on clean up for this class
	# -----------------------------------------------------------------------------
	sub RunBeforeExit {

		my $self = shift;

		#debug print "%$self RunBeforeExit ! \n";
	}
	#eof sub RunBeforeExit


	# -----------------------------------------------------------------------------
	# called automatically by perl's garbage collector use to know when
	# -----------------------------------------------------------------------------
	sub DESTROY {
		my $self = shift;

		#debug print "the DESTRUCTOR is called  \n" ;
		$self->RunBeforeExit();
		return;
	}   
	#eof sub DESTROY
	#


1;

__END__
