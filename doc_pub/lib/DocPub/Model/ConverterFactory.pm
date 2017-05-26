package DocPub::Model::ConverterFactory ; 

	use strict; use warnings;
	
	use Data::Printer ; 
	use DocPub::Model::RsToXlsConverter; 

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
		my $converter_type			= shift  ; 

		my @args 					= ( @_ ) ; 
		my $Converter 		= {}   ; 

		# global app config hash
		$app_config 				= $objController->app->get('AppConfig') ; 
		$objLogger 					= $objController->app->get('ObjLogger') ;

		# debug ok
		# foreach my $key ( keys ( %$app_config ) ) {
		#	my $msg = "key_:$key , val: " . $app_config->{"$key"} ;
		#	$objLogger->debug ( $msg ) ; 
		# }
	

		if ( $converter_type 	eq 'export-to-xls' ) {
			$Converter 		= 'RsToXlsConverter' ; 
		}
		elsif ( $converter_type eq 'export-to-pdf' ) {
			$Converter 		= 'HtmlToPdfConverter' ; 
		}
		elsif ( $converter_type eq 'export-to-githubmd' ) {
			$Converter 		= 'RsToGitHubMdConverter' ; 
		}
		elsif ( $converter_type eq 'export-to-bitbucketmd' ) {
			$Converter 		= 'RsToBitBucketMdConverter' ; 
		}
		else {
			$Converter 		= 'RsToXlsConverter' ; 
		}
		#eof else 

		my $package_file     	= "DocPub/Model/$Converter.pm";
		my $obj    	      		= "DocPub::Model::$Converter";

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
