package DocPub::Controller::Renderer ; 
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
	# called when dragging and dropping items drop event calls
	# for rendering of the control type passed as url param
	# ---------------------------------------------------------
	sub render_control {

		my $self = shift;
		$objLogger 					= $self->app->get('ObjLogger');
		
		#debug print 'Renderer.pm :: render_control :: render control called !!!:: ' . "\n" ;  
		# get url params 

		my $rdbms_type				= $self->param('rdbms') || 'mysql' ; 
		my $db						= $self->param('db')		|| 'isg_pub_en' ; 
		my $table					= $self->param('item')	|| 'Issue' ; 
		my $draggable_id			= $self->param('draggableid' ) ; 
		my $droppable_id			= $self->param('droppableid' )  ; 
		my $control					= $self->param('control');

		# string the control type prefixes to get the seqId's
		$draggable_id				=~ s/(.*)(\-)(\d{1,6})/$3/g ; 
		$droppable_id				=~ s/(.*)(\-)(\d{1,6})/$3/g ; 

		#debug print "passed the following draggable_id " . $draggable_id . "\n" ; 
		#debug print "passed the following droppable_id " . $droppable_id . "\n" ; 

		my $right_menu_control 	= shift ;
		my $url_params				= $self->req->query_params ; 
		my $ret						= 1 ; 
		my $msg						= '' ; 
		my $debug_msg				= '' ; 
		my $rs 						= {} ; 
		my $objRightMenuBuilder = () ; 
		my $objControlFactory 	= 'DocPub::View::ControlFactory'->new( \$self );
		my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$self );
		my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );
		my $rs_meta 				= $objDbHandler->list_items_meta ( $db , $table ) ;
		my $doc_control			= '<div class="inner_tube">' ; 


		# first Action to db as well !!! 
		$objDbHandler->do_reshuffle ( $db , $table , $draggable_id , $droppable_id ) 
			if ( $control eq 'doc' ) ; 

		#2 ways of retrieving a doc - top bottom and bottom top in hierarchy
		if ( $self->param('path-id' ) ) {
			$rs = $objDbHandler->list_doc_items_bottom_up ($db , $table ) ;
		}
		else {
			$rs = $objDbHandler->list_doc_items ($db , $table ) ;
		}
		$objRightMenuBuilder 	= $objControlFactory->doInstantiate ( $control ) ;
		$doc_control 				= $objRightMenuBuilder->doBuildControl( $rs_meta , $rs );
		$doc_control				.= '</div>' ; 

		$self->render( text=>$doc_control );

	}
	#eof sub render_control




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


	#
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
