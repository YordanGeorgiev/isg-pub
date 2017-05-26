package DocPub::Controller::PdfView; 
use utf8 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;

use Data::Printer ; 

use DocPub::Model::DbHandlerFactory ; 
use DocPub::View::HtmlHandler ; 
use Carp ; 

our $app_config  ; 
our $objLogger ; 
our $doWhiteSpace = 1 ; 
our $ModuleDebug	= 1 ; 


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
	my $rdbms_type				= $self->param('rdbms') 		|| 'mysql' ; 
	my $table 					= $self->param('item')  		|| 'Issue' ;
	my $path_id 				= $self->param('path-id')  	|| '1' ;
	my $branch_id 				= $self->param('branch-id')  	|| '1' ;
	my $promote_id 			= $self->param('promote-id')  || undef ; 
	my $demote_id 				= $self->param('demote-id')  	|| undef ; 
	my $database 				= $self->param('db')				|| 'isg_pub_en' ; 
	my $url_params				= $self->req->query_params  ; 
	$url_params					= Mojo::Util::url_unescape ( $url_params->to_string ) ; 

	my $ret						= 1 ; 
	my $msg						= '' ; 
	my $rs_titles				= {} ; 
	my $debug_msg				= '' ; 
	my $doc_control			= '' ; 
	my $doc_control_conf		= '' ; 
	my $top_menu				= '' ; 
	my $top_menu_conf			= '' ; 
	my $objControlBuilder 	= () ; 
	my $objLeftMenuBuilder 	= () ; 
	my $objControlFactory 	= () ; 

	$self->stash('DoWhiteSpace' , $doWhiteSpace );

	# save to session so that the post could fetch them
	$self->session('rdbms' 	=> $rdbms_type);
	$self->session('db' 		=> $database );
	$self->session('item' 	=> $table);
	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );


	if ( $demote_id or $promote_id ) {
		$objDbHandler->doUpdateItemLevel( $promote_id , $demote_id);
	}

	$objDbHandler->doGetItemViews();

	# get the data from the Model
	my $rs_meta 				= $objDbHandler->list_items_meta ( $database , $table ) ;
	my $rs 						= () ; 
	my $rs_images 				= () ; 
	
	#2 ways of retrieving a doc - top bottom and bottom top in hierarchy
	if ( $self->param('path-id' ) ) {
		$rs = $objDbHandler->list_doc_items_bottom_up ($database , $table ) ;
	}
	else {
		$rs = $objDbHandler->list_doc_items ($database , $table ) ;
	}

	$rs_titles = $objDbHandler->doListFoldersAndDocsTitles ($database ) ;
	#debug print ($rs_titles );
	#
	
	$rs_images				 	= $objDbHandler->list_images_data ( $table ) ;
	$objControlFactory 		= 'DocPub::View::ControlFactory'->new( \$self );
	$objControlBuilder 		= $objControlFactory->doInstantiate ( "pdfdoc" ) ;
	
	# build the doc content
	$doc_control 				= $objControlBuilder->doBuildControl( $rs_meta , $rs , $rs_images);
	$doc_control_conf 		= $objControlBuilder->doConfigureControl( $rs_meta );

	$msg = '' ; 

	$self->build_view_item_doc ( 
		$msg , $web_host , $web_port 
		, $database , $table , $doc_control 
		, $top_menu , $url_params  );


	
	$url_params				= $self->req->query_params  ; 
	$url_params				= Mojo::Util::url_unescape ( $url_params->to_string ) ; 

}
#eof sub view_item_doc
#


sub build_view_item_doc {

	my $self 					= shift ; 
	my $msg 						= shift ; 
	my $web_host 				= shift ; 
	my $web_port 				= shift ; 
	my $database 				= shift ; 
	my $item 					= shift ; 
	my $doc_control			= shift ;
	my $top_menu				= shift ;
	my $url_params				= shift ;
	my $debug_msg				= '' ; 
	$debug_msg 					= $self->stash('debug_msg') if $ModuleDebug == 1  ; 

	# build the View
	my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objControlBuilder 	= () ; 
	
	$self->res->headers->accept_charset('UTF-8');

	$top_menu 			 = '' ; 

	# and render the result
  	$self->render(
		template 				=> 'actions/viewpdf/doc_page'
	 , web_host 				=> $web_host
	 , web_port 				=> $web_port
	 , database 				=> $database
	 , doc_control				=> $doc_control
	 ,	item 						=> $item 
	 , url_params				=> $url_params
	 ,	msg						=> $msg
	 ,	debug_msg				=> $debug_msg
	);

}
# sub build_view_item_doc 

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
		croak "\@PdfView.pm sub get TRYING to get undefined name" unless $name ;  
		croak "\@PdfView.pm sub get TRYING to get undefined value" unless ( $self->{"$name"} ) ; 

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
