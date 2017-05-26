package isg_pub::Control::Utils::Initiator ; 
	use strict; use warnings;

	my $VERSION = '1.2.0';    #docs at the end

	require Exporter;
	our @ISA = qw(Exporter);
	our $AUTOLOAD =();
	our $ModuleDebug = 0 ; 
	use AutoLoader;


	use Cwd qw/abs_path/;
	use File::Path qw(make_path) ;
	use File::Find ; 
	use File::Copy;
	use File::Copy::Recursive ; 
	use Sys::Hostname;
	use Carp qw /cluck confess shortmess croak carp/ ; 
	
	our $confHolder					= {} ; 
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
	our $IniFile 						= '' ; 

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
		my $levels_up = 5 ; 

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
		$confHolder->{'ProductBaseDir'} 	= $ProductBaseDir ; 
		$self->{'confHolder'} 				= $confHolder; 

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
		$confHolder->{'ProductDir'} 	= $ProductDir ; 
		$self->{'confHolder'} 				= $confHolder; 
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
		my $levels_up = 3 ; 

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
			#debug print "\@DirParts : @DirParts \n" ; 
		}
		
		$product_version_dir 					= join( '/' , @DirParts );
		$ProductVersionDir 						= $product_version_dir ; 
		$product_version_dir 					= $self->untaint ( $product_version_dir); 
		$ProductVersionDir 						= $self->untaint ( $product_version_dir); 
		$self->{'ProductVersionDir'} 			= $ProductVersionDir ; 
		$confHolder->{'ProductVersionDir'} 	= $ProductVersionDir ; 
		$self->{'confHolder'} 				= $confHolder; 

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

		$confHolder->{ 'EnvironmentName' } 		= $EnvironmentName ; 
		$self->{'confHolder'} 				= $confHolder; 
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

		$confHolder->{ 'ProductName' } 			= $ProductName ; 
		$self->{'confHolder'} 				= $confHolder; 
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
		
		$confHolder->{ 'ProductVersion' } 		= $ProductVersion ; 
		$self->{'confHolder'} 				= $confHolder; 
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

		$confHolder->{ 'ProductType' } 			= $ProductType ; 
		$self->{ 'ProductType' } 			= $ProductType ; 
		$self->{'confHolder'} 				= $confHolder; 

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

		$confHolder->{ 'ProductOwner' } 			= $ProductOwner ; 
		$self->{'confHolder'} 				= $confHolder; 
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
		$confHolder->{ 'HostName' }	= $HostName ; 
		$self->{'confHolder'} 				= $confHolder; 
		return $HostName;
	}
	#eof sub doResolveMyHostName

	#
	# ---------------------------------------------------------
	# if the current host does not have configuration file 
	# bootstrap the one from the hostname host
	# ---------------------------------------------------------
	sub doBootStrap {
		#if we do not have host configuration we are "bootstraping"
	
		my $self 					= shift ; 
		my @root_dirs 				= qw (conf );
		
		my $HostName 				= $self->doResolveMyHostName();
		my $ProductVersionDir 	= $self->doResolveMyProductVersionDir();


		foreach my $root_dir ( @root_dirs ) {

			my $src_dir = '' ; 
			$src_dir = "$ProductVersionDir/$root_dir/hosts/doc-pub-host" ; 
			shortmess "src_dir is $src_dir \n" ; 

		 	unless (-d "$src_dir") {
			  make_path("$src_dir", ,{mode => 0777} )
				 || cluck("Cannot create \$src_dir $src_dir $! !!!");
			}

			croak ( "undef src_dir" ) unless ( $src_dir ) ; 
			$src_dir = $self->untaint ( "$src_dir" ) ; 
			croak ( "undef src_dir" ) unless ( $src_dir ) ; 

			my $tgt_dir = '' ; 
			$tgt_dir = "$ProductVersionDir/$root_dir/hosts/$HostName" ;

		 	unless (-d "$tgt_dir") {
			  make_path("$tgt_dir", ,{mode => 0777} )
				 || cluck("Cannot create \$tgt_dir $tgt_dir $! !!!");
			}

			croak ( "undef tgt_dir" ) unless ( $tgt_dir ) ; 
			# the hostname dir 
			File::Copy::Recursive::rcopy ( "$src_dir" , "$tgt_dir" ) ; 
			$tgt_dir = $self->untaint ( $tgt_dir ) ; 
			
			my @dirs = () ; 
			File::Find::find(
				sub { 
					return unless -d ; 
					my $dir = $File::Find::name ;
					push @dirs, $dir ; 
				},
					$tgt_dir);

			my @files = () ; 
			File::Find::find(
				sub {
					return unless -f ; 
					my $file = $File::Find::name ;
					push @files, $file ; 
			},
				$tgt_dir);


			# mv firs the dirs
			foreach my $dir ( @dirs ) { 
				my $renamed_dir= $dir ; 
				$renamed_dir =~ s/doc-pub-host/$HostName/g ;
				move ( "$dir" , "$renamed_dir" ) ; 
			}
			
			# mv than the files
			foreach my $file ( @files ) { 
				my $renamed_file= $file ; 
				$renamed_file =~ s/doc-pub-host/$HostName/g ;
				move ( "$file" , "$renamed_file" ) ; 
			}
			
		} #eof foreach my $root_dir
		
	}
	#eof sub bootstrap 



	#
	# ---------------------------------------------------------
	# returns the host name of currently running host
	# by using the Sys::IniFile perl module
	# ---------------------------------------------------------
	sub doResolveMyIniFile {

		my $self 						= shift;
		my $msg  						= ();
		
		my $ProductVersionDir		= $self->doResolveMyProductVersionDir();
		my $HostName					= $self->doResolveMyHostName();

		# set the default IniFile path if no cmd argument is provided
		$IniFile = "$ProductVersionDir/conf/hosts/$HostName/ini/$ProductName.$HostName.ini" ; 

		$self->set('IniFile' , $IniFile) ; 
		$confHolder->{'IniFile'} 	= $IniFile ; 
		$self->{'confHolder'} 		= $confHolder; 

		$self->doBootStrap() unless ( -f "$IniFile" ) ; 
		 
		return $IniFile;
	}
	#eof sub doResolveMyIniFile


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
		$IniFile 					= $self->doResolveMyIniFile();

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




# ---------------------------------------------------------
# VersionHistory: 
# ---------------------------------------------------------
#
1.2.0 --- 2014-09-11 20:44:26 -- tests on Windows 
1.1.0 --- 2014-08-27 11:29:25 -- tests passed with Test::More
1.0.0 --- 2014-08-25 08:25:15 -- refactored away from main calling script

=cut 

