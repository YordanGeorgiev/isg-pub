package isg_pub::Control::Utils::ETL::Loader  ; 
use strict ; use warnings ; 

	require Exporter ; 
	our @ISA = qw(Exporter);
	our %EXPORT_TAGS = ( 'all' => [ qw() ] );
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
	our @EXPORT = qw() ; 
	our $AUTOLOAD =();

	use AutoLoader;
	use Carp;

	use isg_pub::Control::Utils::Logger ; 
	use isg_pub::Control::Utils::Configurator ; 


	our $ModuleDebug 		= 0 ;	 # change this if something is terribly wrong  
	our $confHolder		= {} ; # the global app settings hash reference	
	our $Msg 				= '' ; # this is the msg to be shown to the end-users
	our $DebugMsg 			= '' ; # this is the msg for debugging purposes 
	our $sub_class 		= '' ; # the calling sub_class 
	our $ModuleIniFile 	= '' ; # the config ini file of this module
	our $Project 			= 'isg-pub' ; 
	our $confHolderOfObj = {} ; 
	our $objConfigurator = {} ; 	
	our $objLogger 		= {} ; 
	our $HostName 			= '' ; 
	our $ProductVersionDir = q{} ; 
	our $ConfDir			= q{} ; 



	#
	#-------------------------------------------------------
	# initialize the vars for this module
	#-------------------------------------------------------
	sub doInitialize{

	
		my $self 			= shift ; 
		$ModuleIniFile 	= shift ; 		
		$confHolder       = ${ shift @_ } if ( @_ ) ;

		$objConfigurator = 
			"isg_pub::Control::Utils::Configurator"->clone( $ModuleIniFile ,  $confHolder ) ;

		# get the hash having the vars
		$confHolderOfObj = $objConfigurator->getConfHolder();
		print	$objConfigurator->dumpIni();

		$self->set('confHolderOfObj' , $confHolderOfObj);

		if ( $ModuleDebug == 1 ) { 
			foreach my $key ( keys ( %$confHolderOfObj ) ) {
				print "Loader.pm key:$key , val: " . $confHolderOfObj->{"$key"} . " \n" ; 
			}
		}

		$objLogger = 'isg_pub::Control::Utils::Logger'->new ( \$confHolder );
		$self->set( 'objLogger', $objLogger );
		$objLogger->LogDebugMsg ( "Loader::Initialize");
		
		my $ActionName			= ref ( $self ) ; 
		$ActionName 		=~ s|(.*)[[:punct:]]{2}([a-zA-Z0-9_]*)|$2|g ; 

		print "ActionName " . ref($self) . " $ActionName" ; 

		if ( $ModuleDebug == 1 ) {

			my $msg = "Loader == START == ini file" ;
			$objLogger->LogDebugMsg ( "$msg" ) ; 
			
			$msg = "\$ActionName is $ActionName";
			$objLogger->LogDebugMsg( "$msg" ) ;
		}
		
		$ProductVersionDir 			= $confHolder->{ 'ProductVersionDir' };
		$HostName          			= $confHolder->{ 'HostName' }; 
		$ConfDir           			= "$ProductVersionDir/conf/hosts/$HostName/ini";


		#debug print "\n Loader.pm : 63 \$ModuleIniFile: $ModuleIniFile \n" ; 
		# set the default file module config if not passed
		unless ( $ModuleIniFile or -r $ModuleIniFile ) {
			$ModuleIniFile = 
					"$ConfDir/" . $ActionName . '.' . $HostName . '.ini'
		}

		#debug print "\n Loader.pm : 69 \$ModuleIniFile: $ModuleIniFile \n" ; 

		# if there is not a config file for this module just set empty hash
		unless ( -r $ModuleIniFile ) {

			$confHolderOfObj = {} ;
			$self->set( 'confHolderOfObj', $confHolderOfObj );

			my $error_msg = "\n\n[FATAL] Loader does no have configuration ini file: "; 
			$error_msg .= " $ModuleIniFile" ; 
			$error_msg .= " \n\n\n" ; 
			croak $error_msg ; 
			return ; 
		}
		
		$self->set('ModuleIniFile' , $ModuleIniFile ) ; 

		my $msg = "\$ModuleIniFile : \n $ModuleIniFile " ; 
		$objLogger->LogInfoMsg( "$msg" ) if $ModuleDebug == 1 ; 
		

		if ( defined $confHolderOfObj->{ 'DoSetAllIniVarsToEnvironmentVars' } ) {
			$objConfigurator->SetAllIniVarsToEnvironmentVars()
			  if ( $confHolderOfObj->{ 'DoSetAllIniVarsToEnvironmentVars' } == 1 );
		}
		$self->set( 'confHolderOfObj', $confHolderOfObj );
		$objLogger->LogDebugMsg( "CLASS TEMPLATE END OF INTI" ) if $ModuleDebug == 1 ; 

	}
	#eof sub Initialize


	#
	# -----------------------------------------------------------------------------
	# the constructor 
	# -----------------------------------------------------------------------------
	sub new {
		
		my $invocant 		= shift;    
		$ModuleIniFile 	= ${ shift @_ } if ( @_ ) ; 
		$confHolder    	= ${ shift @_ } if ( @_ ) ;

		my @args 			= ( @_ ) ; 
		# might be class or object, but in both cases invocant
		my $class = $invocant ; 
		$sub_class = $class ; 

		my $self = {};        # Anonymous hash reference holds instance attributes
		bless( $self, $class );    # Say: $self is a $class

		$self->doInitialize( $ModuleIniFile , \$confHolder , @args ) ;

		return $self;
	}   
	#eof const
	#
	
	
	#
	# -----------------------------------------------------------------------------
	# perldoc autoloader
	# -----------------------------------------------------------------------------
    sub AUTOLOAD {
		  my $self = shift ; 
        my $sub = $AUTOLOAD;
        (my $constname = $sub) =~ s/.*:://;
        my $val = constant($constname, @_ ? $_[0] : 0);
					my $msg =
					  "BOOM! BOOM! BOOM! \n RunTime Error !!!\nUndefined Function $val(@_)\n";
                croak "Your vendor has not defined constant $constname";
        if ($! != 0) {
            if ($! =~ /Invalid/ || $!{EINVAL}) {
                $AutoLoader::AUTOLOAD = $sub;
                goto &AutoLoader::AUTOLOAD;
            }
            else {
					my $msg =
					  "BOOM! BOOM! BOOM! \n RunTime Error !!!\nUndefined Function $val(@_)\n";
                croak "Your vendor has not defined constant $constname";
            }
        }
        *$sub = sub { $val }; # same as: eval "sub $sub { $val }";
        goto &$sub;
    }
	 #eof sub AUTOLOAD


	#
	# -----------------------------------------------------------------------------
	# return a field's value
	# -----------------------------------------------------------------------------
	sub get {

		my $self = shift;
		my $name = shift;
		return $self->{ $name };
	}    #eof sub get


	
	#
	# -----------------------------------------------------------------------------
	# set a field's value
	# -----------------------------------------------------------------------------
	sub set {

		my $self  = shift;
		my $name  = shift;
		my $value = shift;
		#debug print "setting var:$name with val:$value" ; 
		$self->{ $name } = $value;
	}  
	#eof sub set

	
	#
	# -----------------------------------------------------------------------------
	# a kind of virtual method - the sub classes must implement getSubClassVar
	# -----------------------------------------------------------------------------
	sub getSubClassVar {

		my $self = shift ; 
		my $var_name = shift ; 
		my $sub_class = ref($self) ;
		if ( $sub_class ne __PACKAGE__ ) {
			croak "do not call $sub_class\::SUPER->getSubClassVar";
		}
		else {
			croak "getSubClassVar must be implemented by subclass";
		}
		return $self->getSubClassVar($var_name);
	}
	#eof sub getSubClassVar

	
	#
	# -----------------------------------------------------------------------------
	# return the fields of this obj instance
	# -----------------------------------------------------------------------------
	sub dumpFields {
		my $self = shift;

		my $strFields = ();
		foreach my $key ( keys %$self ) {
			$strFields .= "$key = $self->{$key}\n";
		}

		return $strFields;
	}    #eof sub dumpFields

	
1;


__END__
