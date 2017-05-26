package DocPub::View::ControlFactory ; 

	use strict; use warnings;
	
	use Data::Printer ; 
	use DocPub::Controller::DocView ; 

	use DocPub::View::NiceTableBuilder ; 
	use DocPub::View::PlainTableBuilder ; 
	use DocPub::View::NiceSTableBuilder ; 
	use DocPub::View::LinkActionTableBuilder ; 
	use DocPub::View::LeftMenuBuilder ; 
	use DocPub::View::DocTitleBuilder ; 
	use DocPub::View::DocSrcCodeBuilder ; 
	use DocPub::View::DocPrgrphBuilder ; 
	use DocPub::View::PdfDocTitleBuilder ; 
	use DocPub::View::PdfDocSrcCodeBuilder ; 
	use DocPub::View::PdfDocPrgrphBuilder ; 
	use DocPub::View::SrchResultTitleBuilder ; 
	use DocPub::View::SrchResultPrgrphBuilder ; 
	use DocPub::View::InlineTableControlBuilder ; 
	use DocPub::View::PresentTitleBuilder ; 
	use DocPub::View::PresentPrgrphBuilder ; 
	use DocPub::View::PresentBuilder ; 

	our $confHolder 				= {} ; 
	our $lang_code 				= 'en' ; # the default language is english ...
	our $Project					= 'doc-pub' ; 
	our $objItem					= {} ; 
	our $objController 			= {} ; 
	our $app_config 				= q{} ;
	our $objLogger 				= q{} ;


	#
	# -----------------------------------------------------------------------------
	# fabricates different page  object 
	# -----------------------------------------------------------------------------
	sub doInstantiate {

		my $self 					= shift ; 	
		my $control_type			= shift  ; 

		my @args 					= ( @_ ) ; 
		my $ControlBuilder 		= {}   ; 

		# global app config hash
		$app_config 				= $objController->app->get('AppConfig') ; 
		$objLogger 					= $objController->app->get('ObjLogger') ;

		# debug ok
		# foreach my $key ( keys ( %$app_config ) ) {
		#	my $msg = "key_:$key , val: " . $app_config->{"$key"} ;
		#	$objLogger->debug ( $msg ) ; 
		# }
	

		if ( $control_type 	 eq 'nice_table' ) {
			$ControlBuilder 		= 'NiceTableBuilder' ; 
		}
		elsif ( $control_type eq 'link_action_table' ) {
			$ControlBuilder 		= 'LinkActionTableBuilder' ; 
		}
		elsif ( $control_type eq 'nice_s_table' ) {
			$ControlBuilder 		= 'NiceSTableBuilder' ; 
		}
		elsif ( $control_type eq 'plain_table' ) {
			$ControlBuilder 		= 'PlainTableBuilder' ; 
		}
		elsif ( $control_type eq 'inline_table' ) {
			$ControlBuilder 		= 'InlineTableControlBuilder' ; 
		}
		elsif ( $control_type eq 'doc' ) {
			$ControlBuilder 		= 'DocBuilder' ; 
		}
		elsif ( $control_type eq 'pdfdoc' ) {
			$ControlBuilder 		= 'PdfDocBuilder' ; 
		}
		elsif ( $control_type eq 'left_menu' ) {
			$ControlBuilder 		= 'LeftMenuBuilder' ; 
		}
		elsif ( $control_type eq 'right_menu' ) {
			$ControlBuilder 		= 'RightMenuBuilder' ; 
		}
		elsif ( $control_type eq 'presentation' ) {
			$ControlBuilder 		= 'PresentBuilder' ; 
		}
		elsif ( $control_type eq 'srch_result' ) {
			$ControlBuilder 		= 'SrchResultBuilder' ; 
		}
		elsif ( $control_type eq 'doc_title' ) {
			$ControlBuilder 		= 'DocTitleBuilder' ; 
		}
		elsif ( $control_type eq 'pdf_doc_title' ) {
			$ControlBuilder 		= 'PdfDocTitleBuilder' ; 
		}
		elsif ( $control_type eq 'doc_prgrph' ) {
			$ControlBuilder 		= 'DocPrgrphBuilder' ; 
		}
		elsif ( $control_type eq 'pdf_doc_prgrph' ) {
			$ControlBuilder 		= 'PdfDocPrgrphBuilder' ; 
		}
		elsif ( $control_type eq 'present_title' ) {
			$ControlBuilder 		= 'PresentTitleBuilder' ; 
		}
		elsif ( $control_type eq 'present_prgrph' ) {
			$ControlBuilder 		= 'PresentPrgrphBuilder' ; 
		}
		elsif ( $control_type eq 'src_code' ) {
			$ControlBuilder 		= 'DocSrcCodeBuilder' ; 
		}
		elsif ( $control_type eq 'pdf_src_code' ) {
			$ControlBuilder 		= 'PdfDocSrcCodeBuilder' ; 
		}
		elsif ( $control_type eq 'srch_title' ) {
			$ControlBuilder 		= 'SrchResultTitleBuilder' ; 
		}
		elsif ( $control_type eq 'srch_prgrph' ) {
			$ControlBuilder 		= 'SrchResultPrgrphBuilder' ; 
		}
		else {
		# future support for different controls should be added here ...
			$ControlBuilder 		= 'NiceTableBuilder' ; 
		}
		#eof else 

		my $package_file     	= "DocPub/View/$ControlBuilder.pm";
		my $obj    	      		= "DocPub::View::$ControlBuilder";

		require $package_file;

		return $obj->new( \$objController , @args);
	}
	# eof sub doInstantiate
	#


	#
	# -----------------------------------------------------------------------------
	# the constructor 
	# -----------------------------------------------------------------------------
	sub new {
		
		my $invocant 			= shift ;    
		$objController			= ${ ( shift )  } ; 
		
		# might be class or object, but in both cases invocant
		my $class = ref ( $invocant ) || $invocant ; 

		my $self = {};        # Anonymous hash reference holds instance attributes
		
		bless( $self, $class );    # Say: $self is a $class
		return $self;
	}   
	#eof const


1;


__END__
