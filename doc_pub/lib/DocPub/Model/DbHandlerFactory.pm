package DocPub::Model::DbHandlerFactory ; 

	use strict; use warnings;
	use Mojo::Base 'Mojolicious::Controller';
	
	use Data::Printer ; 
	
	# use DocPub::Model::OracleDbHandler ; 
	# do not force the average users to install the oracle client
	# it is not worth the pain if they won't use it anyway ... 
	BEGIN {
		my $sqlplus_found = grep { -x "$_/sqlplus"}split /:/,$ENV{PATH} ; 
		if ( $sqlplus_found >= 1 ) {
			require DocPub::Model::OracleDbHandler ; 
			import DocPub::Model::OracleDbHandler ; 
		}

	}

	our $confHolder 		= {} ; 
	our $lang_code 		= 'en' ; # the default language is english ...
	our $Project			= 'doc-pub' ; 
	our $db_type			= 'mysql' ; 
	our $objItem			= {} ; 
	our $objController 	= {} ; 



	#
	# -----------------------------------------------------------------------------
	# fabricates different page  object 
	# -----------------------------------------------------------------------------
	sub doInstantiate {

		my $self 			= shift ; 	
		my $db_type			= shift // $db_type ; 

		my @args 			= ( @_ ) ; 
		my $DbHandler 		= {}   ; 

		# get the application configuration hash
		# global app config hash

		if ( $db_type eq 'mysql' ) {
			$DbHandler 				= 'MariaDbHandler' ; 
		}
		if ( $db_type eq 'ora' ) {
			$DbHandler 				= 'OracleDbHandler' ; 
		}
		else {
			# future support for different RDBMS 's should be added here ...
			$DbHandler 				= 'MariaDbHandler' ; 
		}
		

		my $package_file     	= "DocPub/Model/$DbHandler.pm";
		my $obj    	      		= "DocPub::Model::$DbHandler";

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
		$objController			= ${ shift @_   } ; 
		
		# might be class or object, but in both cases invocant
		my $class = ref ( $invocant ) || $invocant ; 

		my $self = {};        # Anonymous hash reference holds instance attributes
		
		bless( $self, $class );    # Say: $self is a $class
		return $self;
	}   
	#eof const


1;


__END__
