#package isg_pub::Control::Utils::Initiator ; 
package DocPub::Utils::Initiator;

use Mojo::Log ; 

	use strict; use warnings;

	my $VERSION = '1.1.1';    #docs at the end

	require Exporter;
	our @ISA = qw(Exporter);
	our $AUTOLOAD =();
	our $ModuleDebug = 0 ; 


	use Cwd qw/abs_path/;
	use File::Path qw(make_path) ;
	use Sys::Hostname;
	use Carp qw /cluck confess shortmess croak carp/ ; 
	#use ExtUtils::Command ; -- touch did not work ... 
	
	our $mod_config					= {} ; 
	our $RunDir 						= '' ; 
	our $ProductBaseDir 				= '' ; 
	our $ProductDir 					= '' ; 
	our $ProductVersionDir 			= ''; 
	our $EnvironmentName 			= '' ; 
	our $ProductName 					= '' ; 
	our $ProductType 					= '' ; 
	our $ProductVersion 				= ''; 
	our $ProductOwner 				= '' ; 
	our $HostName 						= '' ; 
	our $ConfFile 						= '' ; 
	our $LogFile 						= '' ; 

=head1 SYNOPSIS

	doResolves the product version and base dirs , bootstraps config files if needed

		 use Initiator;
		 my $objInitiator = new Initiator () ; 

	=head1 EXPORT

	A list of functions that can be exported.  You can delete this section
	if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS


=cut

	#
	# ---------------------------------------------------------
	# the product base dir is the dir under which all the product
	# instances are installed 
	# ---------------------------------------------------------
	sub doResolveMyProductBaseDir {

		my $self = shift;
		my $msg  = ();
		# the product base dir is 5 levels above the path of 
		# this script dir
		my $levels_up = 3 ; 

		#doResolve the run dir where this scripts is placed
		my $my_absolute_path = abs_path( $0 );
		my $product_base_dir = '' ; 

		#debug print "\$my_absolute_path is $my_absolute_path \n" ;
		$my_absolute_path =~ m/^(.*)(\\|\/)(.*)/;
		$my_absolute_path = $1;

		$my_absolute_path =~ tr|\\|/| if ( $^O eq 'MSWin32' );
		my @DirParts = split( '/' , $my_absolute_path );
		for ( my $count = 0; $count < $levels_up ; $count++ ){ 
			pop @DirParts; 
			#debug print "ok \@DirParts : @DirParts \n" ; 
		}
		
		$product_base_dir = join( '/', @DirParts );
		#untainting ...
		$ProductBaseDir 						= $product_base_dir ; 
		$product_base_dir 					= $self->untaint ( $product_base_dir); 
		$ProductBaseDir 						= $self->untaint ( $product_base_dir); 
		$self->{'ProductBaseDir'} 			= $ProductBaseDir ; 
		$mod_config->{'ProductBaseDir'} 	= $ProductBaseDir ; 
		$self->{'ModConfig'} 				= $mod_config; 

		#deebug print "ProductBaseDir: $ProductBaseDir \n" ; 
		return $ProductBaseDir;
	}
	#eof sub doResolveMyProductBaseDir
	

	#
	# ---------------------------------------------------------
	# the product version dir is the dir where this product 
	# instance is situated
	# ---------------------------------------------------------
	sub doResolveMyProductDir {

		my $self = shift;
		my $msg  = ();
		my $levels_up = 4 ; # the product dir is 4 steps above 
		#doResolve the run dir where this scripts is placed
		my $my_absolute_path = abs_path( $0 );
		my $product_dir = '' ; 

		$my_absolute_path =~ tr|\\|/| if ( $^O eq 'MSWin32' );
		#debug print "\$my_absolute_path is $my_absolute_path \n" ;
		$my_absolute_path =~ m/^(.*)(\\|\/)(.*)/;
		$my_absolute_path = $1;


		my @DirParts = split( '/' , $my_absolute_path );
		for ( my $count = 0; $count < $levels_up ; $count++ ){ 
			pop @DirParts; 
			#debug print "ok \@DirParts : @DirParts \n" ; 
		}
		
		$product_dir = join( '/' , @DirParts );
		#untainting ...
		$ProductDir 						= $product_dir ; 
		$product_dir 						= $self->untaint ( $product_dir); 
		$ProductDir 						= $self->untaint ( $product_dir); 
		$self->{'ProductDir'} 			= $ProductDir ; 
		$mod_config->{'ProductDir'} 	= $ProductDir ; 
		$self->{'ModConfig'} 			= $mod_config; 
		return $ProductDir;
	}
	#eof sub doResolveMyProductDir
	

	#
	# ---------------------------------------------------------
	# the product version dir is the dir where this product 
	# instance is situated
	# ---------------------------------------------------------
	sub doResolveMyProductVersionDir {

		my $self = shift;
		my $msg  = ();
		my $levels_up = 2 ; 

		#doResolve the run dir where this scripts is placed
		my $my_absolute_path = abs_path( $0 );
		my $product_version_dir = '' ; 

		#debug print "\$my_absolute_path is $my_absolute_path \n" ;
		$my_absolute_path =~ m/^(.*)(\\|\/)(.*)/;
		$my_absolute_path = $1;
		$my_absolute_path =~ tr|\\|/| if ( $^O eq 'MSWin32' );

		my @DirParts = split( '/' , $my_absolute_path );
		for ( my $count = 0; $count < "$levels_up" ; $count++ ){ 
			pop @DirParts; 
			#print "\@DirParts : @DirParts \n" ; 
		}
		
		$product_version_dir 					= join( '/' , @DirParts );
		$ProductVersionDir 						= $product_version_dir ; 
		$product_version_dir 					= $self->untaint ( $product_version_dir); 
		$ProductVersionDir 						= $self->untaint ( $product_version_dir); 
		$self->{'ProductVersionDir'} 			= $ProductVersionDir ; 
		$mod_config->{'ProductVersionDir'} 	= $ProductVersionDir ; 
		$self->{'ModConfig'}	 				= $mod_config; 

		return $ProductVersionDir;
	}
	#eof sub doResolveMyProductVersionDir

	#
	# ---------------------------------------------------------
	# the environment name is the dir identifying this product 
	# instance from other product instances 
	# ---------------------------------------------------------
	sub doResolveMyEnvironmentName {

		my $self = shift;
		my $msg  = ();

		my $ProductVersionDir 	= $self->doResolveMyProductVersionDir();
		$EnvironmentName 			= $ProductVersionDir ; 
		$EnvironmentName 			=~ s#$ProductBaseDir\/##g ;
		$EnvironmentName 			=~ s#(.*?)(\/|\\)(.*)#$3#g ;
		$EnvironmentName 			= $self->untaint ( $EnvironmentName ); 

		$mod_config->{ 'EnvironmentName' } 		= $EnvironmentName ; 
		$self->{'ModConfig'} 				= $mod_config; 
		return $EnvironmentName;
	}
	#eof sub doResolveMyEnvironmentName

	#
	# ---------------------------------------------------------
	# the Product name is the name by which this Product is 
	# identified 
	# ---------------------------------------------------------
	sub doResolveMyProductName {

		my $self = shift;
		my $msg  = ();

		my $EnvironmentName = $self->doResolveMyEnvironmentName();

		#fetch the the product name from the dir struct
		my @tokens = split /\./ , $EnvironmentName ; 
		$ProductName = $tokens[0] ; 

		$mod_config->{ 'ProductName' } 			= $ProductName ; 
		$self->{'ModConfig'} 				= $mod_config; 
		return $ProductName;
	}
	#eof sub doResolveMyProductName


	#
	# ---------------------------------------------------------
	# the Product Version is a number identifying the stage 
	# of the evolution of this product 
	# ---------------------------------------------------------
	sub doResolveMyProductVersion {

		my $self = shift;
		my $msg  = ();
		
		my $ProductVersion	= '' ;
		my $ProductVersionDir 		= $self->doResolveMyProductVersionDir();
		my $EnvironmentName 			= $self->doResolveMyEnvironmentName();
		

		my @tokens 			= split /\./ , $EnvironmentName ; 
		$tokens [1] = $tokens [1] // '' ; 
		$tokens [2] = $tokens [2] // '' ; 
		$tokens [3] = $tokens [3] // '' ; 
		$ProductVersion 	= $tokens[1] . '.' . $tokens[2] . '.' . $tokens[3] ; 
		#debug print "\n\n ProductVersion : $ProductVersion " ; 
		
		$mod_config->{ 'ProductVersion' } 		= $ProductVersion ; 
		$self->{'ModConfig'} 				= $mod_config; 
		return $ProductVersion;
	}
	#eof sub doResolveMyProductVersion

	#
	# ---------------------------------------------------------
	# the Product Type could be :
	# dev -> this product instance is used for development
	# tst -> this product instance is used for testing 
	# qas -> this product instance is used for quality assurance
	# prd -> this product instance is used for production
	# Of course you could define you own abbreviations like ...
	# fub -> full backup
	# ---------------------------------------------------------
	sub doResolveMyProductType {

		my $self = shift;
		my $msg  = ();

		my $EnvironmentName = $self->doResolveMyEnvironmentName();

		my @tokens = split /\./ , $EnvironmentName ; 
		# the type of this environment - dev , test , dev , fb , prod next_line_is_templatized
		my $ProductType = $tokens[4] ; 
		#debug print "\n\n ProductType : $ProductType " ; 

		$mod_config->{ 'ProductType' } 			= $ProductType ; 
		$self->{ 'ProductType' } 			= $ProductType ; 
		$self->{'ModConfig'} 				= $mod_config; 

		return $ProductType;
	}
	#eof sub doResolveMyProductType



	#
	# ---------------------------------------------------------
	# the Product Owner is the string identifying the main 
	# responsible person for operating the current product 
	# instance 
	# ---------------------------------------------------------
	sub doResolveMyProductOwner {

		my $self = shift;
		my $msg  = ();

		my $EnvironmentName = $self->doResolveMyEnvironmentName();

		my @tokens = split /\./ , $EnvironmentName ; 
		# the Owner of this environment - dev , test , dev , fb , prod next_line_is_templatized
		# The username of the person developin this environment 
		$ProductOwner = $tokens[5] ; 
		#debug print "\n\n ProductOwner : $ProductOwner " ; 

		$mod_config->{ 'ProductOwner' } 			= $ProductOwner ; 
		$self->{'ModConfig'} 				= $mod_config; 
		return $ProductOwner;
	}
	#eof sub doResolveMyProductOwner


	#
	# ---------------------------------------------------------
	# returns the host name of currently running host
	# by using the Sys::hostname perl module
	# ---------------------------------------------------------
	sub doResolveMyHostName {

		my $self = shift;
		my $msg  = ();

		$HostName = hostname ; 
		$self->set ( 'HostName' , $HostName );
		$mod_config->{ 'HostName' }	= $HostName ; 
	# 	$self->{'ModConfig'} 				= $mod_config; 
		return $HostName;
	}
	#eof sub doResolveMyHostName



	#
	# ---------------------------------------------------------
	# return the host specific configuration file
	# ---------------------------------------------------------
	sub doResolveMyConfFile {

		my $self 						= shift;
		my $msg  						= ();
		
		my $ProductVersionDir		= $self->doResolveMyProductVersionDir();
		my $HostName					= $self->doResolveMyHostName();
		
		my $DefaultConfFile 			= "$ProductVersionDir/doc_pub/doc_pub.conf" ; 
		# set the default ConfFile path if no cmd argument is provided
		$ConfFile = "$ProductVersionDir/doc_pub/doc_pub.$HostName.conf" ; 

		# if there is no a host specific configuration file take the default one 
		$ConfFile = $DefaultConfFile unless -f $ConfFile ; 

		$self->set('ConfFile' , $ConfFile) ; 
		$mod_config->{'ConfFile'} 	= $ConfFile ; 
		$self->{'ModConfig'} 		= $mod_config; 
		 
		return $ConfFile;
	}
	#eof sub doResolveMyConfFile


	#
	# ---------------------------------------------------------
	# returns the log file in the data log dir 
	# ---------------------------------------------------------
	sub doResolveMyLogFile {

		my $self 						= shift;
		my $msg  						= ();
		
		my $ProductVersionDir		= $self->doResolveMyProductVersionDir();
		my $HostName					= $self->doResolveMyHostName();
		
		my $DefaultLogFile 			= "/var/log/doc_pub.log" ; 
		my $LogDir						= "$ProductVersionDir/doc_pub/data/log" ; 
		unless (-d "$LogDir") {
			  make_path("$LogDir", ,{mode => 0775} )
				 || say ("Cannot create \$LogDir $LogDir $! !!!");
		}
		#debug ok print ("LogDir: $LogDir \n" );

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = $self->GetTimeUnits(); 
		# set the default LogFile path if no cmd argument is provided
		$LogFile = "$LogDir/doc_pub.". "$year" . '-' . "$mon" . ".log" ; 

		open my $file, '>', $LogFile or print "error opening $LogFile $!" ;
		print $file "\n" ; close $file ; 

		# if something is wrong return the default one ...
		$LogFile = $DefaultLogFile unless -f $LogFile ; 

		$self->set('LogFile' , $LogFile) ; 
		$mod_config->{'LogFile'} 	= $LogFile ; 
		$self->{'ModConfig'} 		= $mod_config; 
		#debug print ("doResolveMyLogFile LogFile: $LogFile \n" );
		 
		return $LogFile;
	}
	#eof sub doResolveMyLogFile



	#
	# ---------------------------------------------------------
	# returns the Mojo logger 
	# ---------------------------------------------------------
	sub doInitializeLogger {

		my $self = shift ; 
		
		my $LogFile	  = $self->doResolveMyLogFile();
		# Customize log file location and minimum log level
		my $objLogger = Mojo::Log->new( "path" => "$LogFile", "level" => 'all');

		$objLogger = $objLogger->level('error');
		$objLogger = $objLogger->level('warn');
		$objLogger = $objLogger->level('debug');

		$objLogger->format ( sub {
			my ($time, $level, @lines) = @_;
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = GetTimeUnits(); 
			$time = "$year-$mon-$mday $hour:$min:$sec"; 
			
			return "\n $time [$level] " . join ( " " , @lines );
			}
		);

		return $objLogger ; 

	}
	#eof sub doInitializeLogger

	
	#
	# -----------------------------------------------------------------------------
	# get time units 
	# my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = $self-> GetTimeUnits(); 
	# -----------------------------------------------------------------------------
	sub GetTimeUnits {

		my $self = shift ; 

		# Purpose: returns the time in yyyymmdd-format 
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
		#---- change 'month'- and 'year'-values to correct format ---- 
		$sec = "0$sec" if ($sec < 10); 
		$min = "0$min" if ($min < 10); 
		$hour = "0$hour" if ($hour < 10);
		$mon = $mon + 1;
		$mon = "0$mon" if ($mon < 10); 
		$year = $year + 1900;
		$mday = "0$mday" if ($mday < 10); 

		return ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) ; 

	} #eof sub 



=head2 new
	# -----------------------------------------------------------------------------
	# the constructor
=cut 

	# -----------------------------------------------------------------------------
	# the constructor 
	# -----------------------------------------------------------------------------
	sub new {
		
		my $invocant = shift;    
		# might be class or object, but in both cases invocant
		my $class = ref ( $invocant ) || $invocant ; 

		my $self = {};        # Anonymous hash reference holds instance attributes
		bless( $self, $class );    # Say: $self is a $class

		$ProductBaseDir 			= $self->doResolveMyProductBaseDir();
		$ProductVersionDir 		= $self->doResolveMyProductVersionDir();
		$EnvironmentName 			= $self->doResolveMyEnvironmentName();
		$ProductName 				= $self->doResolveMyProductName();
		$ProductVersion 			= $self->doResolveMyProductVersion();
		$ProductType 				= $self->doResolveMyProductType();
		$ProductOwner 				= $self->doResolveMyProductOwner();
		$HostName 					= $self->doResolveMyHostName();
		$ConfFile 					= $self->doResolveMyConfFile();
		#debug print "ConfFile ::: $ConfFile" . "\n" ; 
		$LogFile 					= $self->doResolveMyLogFile();

		#debug print $self->dumpFields();

		return $self;
	}  
	#eof const

=head2
	# -----------------------------------------------------------------------------
	# overrided autoloader prints - a run-time error - perldoc AutoLoader
	# -----------------------------------------------------------------------------
=cut
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
		croak "\@Initiator.pm sub get TRYING to get undefined name" unless $name ;  
		croak "\@Initiator.pm sub get TRYING to get undefined value" unless ( $self->{"$name"} ) ; 

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


	# STOP functions
	# =============================================================================

	# -----------------------------------------------------------------------------
	# cleans potentially suspicious dirs and files for the perl -T call
	# -----------------------------------------------------------------------------
	sub untaint {
		

		# Don't pollute caller's value.
  		local $@;   

		my $self 		= shift ; 
		my $file			= '' ; 
		$file 			= shift ; 
		
		# it just does not work under Windows ... 
		return $file if ( $^O eq 'MSWin32' ) ; 

		#debug print ( "undef file" ) unless ( $file ) ; 
		#debug print ( "BEFORE untaint -- file: $file " ) ; 
		
		unless ( $self->is_tainted ( $file ) ) {
			
			$file =~ /([\/_\-\@\w.]+)/ ;
			#debug print "Initiator::untaint \$1 is $1 \n" ; 
			$file = $1; 			
			#$data should be now untainted
			#debug print "file : $file is not tainted \n" ; 
			#debug print ( "AFTER untaint -- file: $file " ) ; 
			return $1 ; 
		} else {
			carp "Bad data in file path: '$file'"; 	
		}
		
	}
	#eof sub untaint
	

	# -----------------------------------------------------------------------------
	# src:http://perldoc.perl.org/functions/local.html
	# src:http://perldoc.perl.org/perlsec.html#Laundering-and-Detecting-Tainted-Data
	# -----------------------------------------------------------------------------
	sub is_tainted {
		my $self = shift ; 
  		local $@;   # Don't pollute caller's value.
		return ! eval { eval("#" . substr(join("", @_), 0, 0)); 1 };
	}


sub register {
  my ($self, $app) = @_;
		$app->helper('my_helpers.Initiator' => sub {
		my ($c, @args) = @_;
		$c->res->headers->header('X-Mojo' => 'I <3 Mojolicious!');
		$c->render(@args);
	});
}

1;

__END__

=head1 NAME

Initiator 

=head1 SYNOPSIS

use Initiator  ; 


=head1 DESCRIPTION
the main purpose is to initiate minimum needed environment for the operation 
of the whole application - man app config hash 

=head2 EXPORT


=head1 SEE ALSO

perldoc perlvars

No mailing list for this module


=head1 AUTHOR

yordan.georgiev@gmail.com

=head1 



#
# ---------------------------------------------------------
# VersionHistory: 
# ---------------------------------------------------------
#


1.1.1 --- 2015-08-25 09-27-02 -- ysg -- touch does not work , replaced with open file , write to file
1.1.0 --- 2015-08-24 09-14-47 -- ysg -- doResolveMyLogFile  , doInitializeLogger  , GetTimeUnits  , new 
1.0.0 --- 2015-08-21 08-14-47 -- ysg -- copied from isg-pub app - subs added doResolveMyProductBaseDir  , doResolveMyProductDir  , doResolveMyProductVersionDir  , doResolveMyEnvironmentName  , doResolveMyProductName  , doResolveMyProductVersion  , doResolveMyProductType  , doResolveMyProductOwner  , doResolveMyHostName 

=cut 

