package DocPub::Controller::Show ; 

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
	my $left_menu_control	= '' ; 
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

	#$rs_titles = $objDbHandler->doListFoldersAndDocsTitles ($database ) ;
	#debug print ($rs_titles );
	#
	
	$rs_images				 	= $objDbHandler->list_images_data ( $table ) ;
	$objControlFactory 		= 'DocPub::View::ControlFactory'->new( \$self );
	$objControlBuilder 		= $objControlFactory->doInstantiate ( "doc" ) ;
	$objLeftMenuBuilder 		= $objControlFactory->doInstantiate ( "left_menu" ) ;
	
	# build the doc content
	$doc_control 				= $objControlBuilder->doBuildControl( $rs_meta , $rs , $rs_images);
	$left_menu_control 		= $objLeftMenuBuilder->doBuildControl( 'view' );
	$doc_control_conf 		= $objControlBuilder->doConfigureControl( $rs_meta );

	$msg = '' ; 

	$self->build_view_item_doc ( 
		$msg , $web_host , $web_port 
		, $database , $table , $doc_control 
		, $top_menu , $url_params , $left_menu_control );


	$self->req->query_params->remove('demote-id' ) if $self->param('demote-id' ) ; 
	$self->req->query_params->remove('promote-id' ) if $self->param('promote-id' ) ; 
	
	$url_params				= $self->req->query_params  ; 
	$url_params				= Mojo::Util::url_unescape ( $url_params->to_string ) ; 

	$self->redirect_to ( '/view?' . $url_params )  if $self->param('demote-id' ) ;
	$self->redirect_to ( '/view?' . $url_params )  if $self->param('promote-id' ) ;
}
#eof sub view_item_doc
#


#
# ---------------------------------------------------------
# this method is called to retrieve the content of the field 
# from db once the user clicks on the Paragraph or the Source 
# Code
# ---------------------------------------------------------
sub get_item_to_edit {

   my $self = shift;
	$app_config 				= $self->app->get('AppConfig') ; 
	$objLogger 					= $self->app->get('ObjLogger');
	my $web_host 				= $app_config->{'web_host'} ;
	my $web_port 				= $app_config->{'web_port'} ;

	# get url params 
	my $rdbms_type				= $self->param('rdbms') || 'mysql' ; 
	my $table 					= $self->param('item')  || 'Issue' ;
	my $database 				= $self->param('db')		|| 'isg_pub_en' ; 
	
	my $prgrph					= '' ; 
	my $ret						= 1 ; 
	my $msg						= '' ; 
	my $debug_msg				= '' ; 
	my $doc_control			= '' ; 
	my $doc_control_conf		= '' ; 
	my $rs = {}  ;
	my $rs_meta = {} ; 
	my $hs_seq_logical_order = {} ; 
	my $objControlBuilder 	= () ; 
	my $objLeftMenuBuilder 	= () ; 
	my $objControlFactory 	= () ; 
	my $objPrgrphControlBuilder 	= () ; 
	my $objPrgrphControlFactory 	= () ; 
	my $objSrcCodeControlBuilder 	= () ; 
	my $objSrcCodeControlFactory 	= () ; 
	my $objDocTitleControlFactory = () ; 
	my $objDocTitleControlBuilder = (); 

	$objPrgrphControlFactory 		= 'DocPub::View::ControlFactory'->new( \$self);
	$objPrgrphControlBuilder 		= $objPrgrphControlFactory->doInstantiate ( 'doc_prgrph' ) ;
	$objSrcCodeControlFactory 		= 'DocPub::View::ControlFactory'->new( \$self);
	$objSrcCodeControlBuilder 		= $objSrcCodeControlFactory->doInstantiate ( 'src_code' ) ;
	$objDocTitleControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self);
	$objDocTitleControlBuilder 	= $objDocTitleControlFactory->doInstantiate ( 'doc_title' ) ;


	$self->stash('DoWhiteSpace' , $doWhiteSpace );
	
	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );
	$objDbHandler->doGetItemViews();
	#p($self->stash('RefItemViews') ); 
	
	my $row						= {} ; 
	my $field_name				= '' ; 
	# fetch from db
	( $row , $field_name ) 	= $objDbHandler->get_field_content_for_edit ($self);
	$prgrph = $row->{ $field_name } ; 

	#print 'DocView.pm :: load the content AFTER click :: field_name :: ' . "$field_name " ; 
	#print 'DocView.pm :: load the content AFTER click :: $prgrph :: ' . "$prgrph " ; 
	#debug p($row); 

	$self->res->headers->accept_charset('UTF-8');
	$self->render(text=> $prgrph );

}
#eof sub get_item_to_edit


#
# ---------------------------------------------------------
# this method is called to SAVE the content from the SrcCode
# UI and the Parapgraph 
# ---------------------------------------------------------
sub post_item_to_edit {

   my $self = shift;
	$objLogger 					= $self->app->get('ObjLogger');
	
	print 'DocView.pm :: post_item_to_edit :: saving the content after TYPING :: ' . "\n" ;  
	# get url params 

	my $rdbms_type				= $self->param('rdbms') || 'mysql' ; 
	my $database 				= $self->param('db')		|| 'isg_pub_en' ; 
	my $table					= $self->param('item')	|| 'Issue' ; 
	my $url_params				= $self->req->query_params ; 
	my $ret						= 1 ; 
	my $msg						= '' ; 
	my $debug_msg				= '' ; 
	my $rs 						= {} ; 
	my $rs_titles 				= {} ; 

	$self->stash('DoWhiteSpace' , $doWhiteSpace );
	my $objPrgrphControlFactory 		= 'DocPub::View::ControlFactory'->new( \$self );
	my $objPrgrphControlBuilder 		= $objPrgrphControlFactory->doInstantiate ( 'doc_prgrph' ) ;
	my $objSrcCodeControlFactory 		= 'DocPub::View::ControlFactory'->new( \$self );
	my $objSrcCodeControlBuilder 		= $objSrcCodeControlFactory->doInstantiate ( 'src_code' ) ;
	my $objDocTitleControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objDocTitleControlBuilder		= $objDocTitleControlFactory->doInstantiate ( 'doc_title' ); 
	my $objDocBuilderControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objDocBuilderControlBuilder	= $objDocBuilderControlFactory->doInstantiate ( 'doc' ); 

	my $objDbHandlerFactory 			= 'DocPub::Model::DbHandlerFactory'->new( \$self );
	my $objDbHandler 						= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );
	$objDbHandler->doGetItemViews();
	my $rs_meta 							= $objDbHandler->list_items_meta ( $database , $table ) ;
	
	#2 ways of retrieving a doc - top bottom and bottom top in hierarchy
	if ( $self->param('path-id' ) ) {
		$rs = $objDbHandler->list_doc_items_bottom_up ($database , $table ) ;
	}
	else {
		$rs = $objDbHandler->list_doc_items ($database , $table ) ;
	}
	
	
	my $hs_seq_logical_order 			= {} ; 

	# update the item
	my $row									= {} ; 
	my $field_name							= '' ; 
	( $row , $field_name)  				= $objDbHandler->save_field_content_from_edit ($self);
	#debug print 'DocView.pm :: post_item_to_edit :: field_name :: ' . $field_name ; 
	my $control								= $row->{ $field_name } ; 

	$self->res->headers->accept_charset('UTF-8');
	#$self->res->headers->content_type('application/text; charset=utf-8');
	if ( $field_name eq 'Description' ) {
		$control = $objPrgrphControlBuilder->doBuildControl( 
				$rs_meta , $hs_seq_logical_order , $rs , $row );
	}
	elsif ( $field_name eq 'Name' ) {
		$hs_seq_logical_order = 
			$objDocBuilderControlBuilder->doBuildLogicalOrderHash( $table, $rs )  ;
		$control = $objDocTitleControlBuilder->doBuildControl( 
				$rs_meta , $hs_seq_logical_order , $rs , $row );
	}
	else {
		$control = $objSrcCodeControlBuilder->doBuildControl ( 
			$rs_meta , $rs , $row );
	}
	
	$self->render(text=>$control );

}
#eof sub edit_item_field



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
	my $left_menu_control 	= shift ;

	# build the View
	my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
	my $objControlBuilder 	= () ; 
	
	$self->res->headers->accept_charset('UTF-8');

#	$left_menu_control = '' ;
	$top_menu 			 = '' ; 

	# and render the result
  	$self->render(
		template 				=> 'actions/show/doc_page'
#
	 , web_host 				=> $web_host
	 , web_port 				=> $web_port
	 , database 				=> $database
	 , doc_control				=> $doc_control
	 , top_menu					=> $top_menu
	 ,	item 						=> $item 
	 , url_params				=> $url_params
	 ,	msg						=> $msg
	 , left_menu_control		=> $left_menu_control
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
