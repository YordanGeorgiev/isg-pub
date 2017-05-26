package DocPub::Controller::Search ; 

use utf8 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;

use Data::Printer ; 

use DocPub::Model::DbHandlerFactory ; 
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
	my $rdbms_type				= $self->param('rdbms') || 'mysql' ; 
	my $table 					= $self->param('item')  || 'Issue' ;
	my $database 				= $self->param('db')		|| 'isg_pub_en' ; 
	my $params              = $self->req->params ; 
	my $str_to_srch			= $self->param('txt_srch') 	|| 'no text to search' ; 
	my $tag_to_srch			= $self->param('tag_srch') 	|| 'no tag to search' ; 

	# a syntax sugar
	if ( $str_to_srch =~ m/tags: /g ) {
		$tag_to_srch 			= $str_to_srch ; 
		$tag_to_srch			=~ s/tags: (.*)/$1/g ; 
		$str_to_srch			= 'no text to search' ; 
	}


	$str_to_srch				=~ s/(.*):(.*)/$2/g ; 
	my $url_params				= $self->req->query_params  ; 
	$url_params					= Mojo::Util::url_unescape ( $url_params->to_string ) ; 
	#debug print "\n\n str_to_search : \"$str_to_srch\" \n" ; 
	#debug print "\n\n tag_to_search : \"$tag_to_srch\" \n " ; 
	#debug print "\n\n params : " . $params->to_string   ; 



	my $ret						= 1 ; 
	my $msg						= '' ; 
	my $debug_msg				= '' ; 
	my $doc_control			= '' ; 
	my $left_menu_control	= '' ; 
	my $doc_control_conf		= '' ; 
	my $top_menu				= '' ; 
	my $top_menu_conf			= '' ; 
	my $objControlBuilder 	= () ; 
	my $objLeftMenuBuilder 	= () ; 
	my $objControlFactory 	= () ; 
	my $res						= {} ; 

	$self->stash('DoWhiteSpace' , $doWhiteSpace );

	# save to session so that the post could fetch them
	$self->session('rdbms' 	=> $rdbms_type);
	$self->session('db' 		=> $database );
	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );
	$objDbHandler->doGetItemViews();

	# get the data from the Model
	if ( $str_to_srch ne 'no text to search' ) {
		$res 							= $objDbHandler->doSearchNamesAndDescriptions ($str_to_srch ) ;
	}

	if ( $tag_to_srch ne 'no tag to search' ) {
		$res 							= $objDbHandler->doSearchForTag ($tag_to_srch ) ;
	}
	
	##p ( $res );
	my $rs_titles 				= $objDbHandler->doListFoldersAndDocsTitles ($database ) ;
	#debug print ($rs_titles );

	$objControlFactory 		= 'DocPub::View::ControlFactory'->new( \$self );
	$objControlBuilder 		= $objControlFactory->doInstantiate ( "srch_result" ) ;
	$objLeftMenuBuilder 		= $objControlFactory->doInstantiate ( "left_menu" ) ;
	
	# build the doc content
	$left_menu_control 		= $objLeftMenuBuilder->doBuildControl( 'view' );
	
	# build the doc content
	$doc_control 				= $objControlBuilder->doBuildControl( $res );


	$msg = '' ; 

	$self->build_view_item_doc ( 
		$msg , $web_host , $web_port , $database , $table , $doc_control , $top_menu , $left_menu_control ) ; 

}
#eof sub list_table 


sub get_view_item_doc_data {
	my $self = shift ; 

}
#sub get_view_item_doc_data {



sub build_view_item_doc {

	my $self 					= shift ; 
	my $msg 						= shift ; 
	my $web_host 				= shift ; 
	my $web_port 				= shift ; 
	my $database 				= shift ; 
	my $item 					= shift ; 
	my $control					= shift ;
	my $top_menu				= shift ;
	my $left_menu_control	= shift ;
	# todo add the structure of the search
	my $right_menu_control	= '' ; 
	my $url_params				= shift ;
	my $debug_msg		= '' ; 

	$debug_msg			= $self->stash('debug_msg' ) if $ModuleDebug == 1 ; 

	# build the View
	my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objControlBuilder 	= () ; 
	
	# and render the result
  	$self->render(
		template 		=> 'actions/search/search_items'  
	 , web_host 		=> $web_host
	 , web_port 		=> $web_port
	 , database 		=> $database
	 , doc_control		=> $control
	 , top_menu			=> $top_menu
	 ,	item 				=> $item 
	 ,	msg				=> $msg
	 ,	debug_msg		=> $msg
	 ,	url_params		=> $url_params
	 , left_menu_control		=> $left_menu_control
	 , right_menu_control		=> $right_menu_control
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
		croak "\@DocView.pm sub get TRYING to get undefined name" unless $name ;  
		croak "\@DocView.pm sub get TRYING to get undefined value" unless ( $self->{"$name"} ) ; 

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
