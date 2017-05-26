package isg_pub::Control::Utils::Logger ;

	use strict; use warnings;
	use v5.10.0;

	my $VERSION = '2.1.5';    
	#docs at the end

	require Exporter;
	our @ISA = qw(Exporter);
	use AutoLoader  ;

	use Carp qw(cluck croak);
	use File::Path;
	use isg_pub::Control::Utils::Timer ; 
	use Data::Printer ; 

	# the hash holding the vars
	our ( $confHolder, $RunDir , $LogFile ) = ();

	our $PID = "$$" ; 
	our $objTimer ; 
	our $HostName ; 
	our $LogTimeToTextSeparator ; 
	our $HumanReadableTime ; 

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use isg_pub::Control::Utils::Logger ; 

    my $foo = morphus::Logger->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS


=cut

=head2 new
# -----------------------------------------------------------------------------
# the constructor
=cut 

	sub new {

		my $class = shift;    # Class name is in the first parameter
		$confHolder = ${ shift @_ } if ( @_ );

		my $self = {};        # Anonymous hash reference holds instance attributes

		bless( $self, $class );    # Say: $self is a $class
		$self->Initialize();
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
			  "\n\n\n[FATAL] RunTime Error !!! Undefined sub $name(@_) ";
			croak ( "$self , $msg" .  "$!" ) ; 
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
		return $self->{ $name };
	}    #eof sub get


	# -----------------------------------------------------------------------------
	# set a field's value
	# -----------------------------------------------------------------------------
	sub set {

		my $self  = shift;
		my $name  = shift;
		my $value = shift;
		$self->{ $name } = $value;
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


	# -----------------------------------------------------------------------------
	# Initialize the object with the minimum data it will need to operate
	# -----------------------------------------------------------------------------
	sub Initialize {

		my $self = shift;
		$confHolder = { Foo => 'Bar', } unless ( $confHolder );

		# if the log dir does not exist create it
		my $LogDir = '';
		$LogDir = $confHolder->{ 'LogDir' };

		# define the log dir as the current dir if not configured 
		unless ( defined( $LogDir ) ) {
			$0 =~ m/^(.*)(\\|\/)(.*)\.([a-z]*)/;
			$RunDir = $1;
			$LogDir = $RunDir;
		}

		# if the log dir is configured but it does not exist 
		if ( defined( $LogDir ) && !-d "$LogDir" ) {
			$self->MkDir( "$LogDir" ) || cluck( " Cannot create the \$LogDir : $LogDir $! !!! " );
		}

		#debug print "The log file is " . $confHolder->{ 'LogFile' } ;
		$LogFile = $confHolder->{ 'LogFile' };

		#if the log file is not defined we create one
		unless ( defined ( $confHolder->{ 'LogFile' } ) ) {
			$LogFile = "$0.log";
		}


		# START set default value if value not specified =========================
		# Full debugging ....

		$confHolder->{ 'PrintConsoleMsgs' } = 1
		  unless ( defined( $confHolder->{ 'PrintConsoleMsgs' } ) );

		$confHolder->{ 'PrintErrorMsgs' } = 1
		  unless ( defined( $confHolder->{ 'PrintErrorMsgs' } ) );

		$confHolder->{ 'PrintDebugMsgs' } = 1
		  unless ( defined( $confHolder->{ 'PrintDebugMsgs' } ) );

		$confHolder->{ 'PrintInfoMsgs' } = 1
		  unless ( defined( $confHolder->{ 'PrintInfoMsgs' } ) );
		
		$confHolder->{ 'PrintTraceMsgs' } = 1
		  unless ( defined( $confHolder->{ 'PrintTraceMsgs' } ) );

		$confHolder->{ 'PrintWarningMsgs' } = 1
		  unless ( defined( $confHolder->{ 'PrintWarningMsgs' } ) );

		$confHolder->{ 'LogMsgs' } = 1
		  unless ( defined( $confHolder->{ 'LogMsgs' } ) );

		$confHolder->{ 'LogTimeToTextSeparator' } = '--'
		  unless ( defined( $confHolder->{ 'LogTimeToTextSeparator' } ) );
		
		$confHolder->{ 'TimeFormat' } = 'YYYY.MM.DD - hh:mm:ss'
		  unless ( defined( $confHolder->{ 'TimeFormat' } ) );

		$confHolder->{ 'LogToFile' } = 1
		  unless ( defined( $confHolder->{ 'LogToFile' } ) );

		$confHolder->{ 'LogToFileHandle' } = 0
		  unless ( defined( $confHolder->{ 'LogToFileHandle' } ) );

		#
		# STOP set default value if value not specified =========================

		$objTimer               = 'isg_pub::Control::Utils::Timer'->new( $confHolder->{ 'TimeFormat' } );
		$HostName					= $confHolder->{'HostName'} ; 
		$LogTimeToTextSeparator = $confHolder->{'LogTimeToTextSeparator'} ; 
	} 
	#eof sub Initialize


	# =============================================================================
	# START functions
	#

	# a nice func to improve readability when completing a certain phase
	sub flushScreen {
		my $self = shift ; 
		print "\033[2J";    
		print "\033[0;0H";
	}
	#eof sub

	#
	# -----------------------------------------------------------------------------
	# Just a wrapper around the Data::Printer 
	# with some additional logic on when what to print
	# to only print when debugging
	# call by: $objLogger->LogArray ( \@array )  ;
	# only print on global setting PrintInfoMsgs in ini file set to 1
	# call by: $objLogger->LogArray ( \@array , 'INFO' ) ; 
	# only print on global setting PrintWarningMsgs in ini file set to 1
	# call by: $objLogger->LogArray ( \@array , 'WARN' ) ; 
	# -----------------------------------------------------------------------------
	sub LogArray {

		my $self    	= shift ;
		my $refArray 	= shift ; 
		my $msg_type 	= shift ; 	

		my @array 		= @$refArray ; 
		
		# if no message type is passed ( msg_type undefined ) do set it to debug
		$msg_type 		= $msg_type // 'DEBUG' ; 

		#debug print "\$msg_type is $msg_type	\n\n\n" ; 
		# some optimization in the array is huge ... been there done that ... 
		return if ( $msg_type eq 'INFO' 	&& $confHolder->{'PrintInfoMsgs'} 		!= 1 )  ; 
		return if ( $msg_type eq 'WARN' 	&& $confHolder->{'PrintWarningMsgs'}	!= 1 )  ; 
		return if ( $msg_type eq 'ERROR' && $confHolder->{'PrintErrorMsgs'}		!= 1 )  ; 
		return if ( $msg_type eq 'TRACE' && $confHolder->{'PrintTraceMsgs'}		!= 1 )  ; 


		my $msg = p(@array);

		$self->LogMsg( $msg )        if ( $msg_type eq "SIMPLE" ) ;
		$self->LogDebugMsg( $msg )   if ( $msg_type eq "DEBUG" ) ;
		$self->LogErrorMsg( $msg )   if ( $msg_type eq "ERROR" ) ;
		$self->LogWarningMsg( $msg ) if ( $msg_type eq "WARN" ) ;
		$self->LogInfoMsg( $msg )    if ( $msg_type eq "INFO" ) ;
		$self->LogWarningMsg( $msg ) if ( $msg_type eq "TRACE" );

		
		if ( $confHolder->{'PrintConsoleMsgs'} == 1 ) {	
			p(@array ) if ( $confHolder->{'PrintDebugMsgs'} 	== 1 && $msg_type eq 'DEBUG' ) ; 	
			p(@array ) if ( $confHolder->{'PrintInfoMsgs'} 		== 1 && $msg_type eq 'INFO' ) ; 	
			p(@array ) if ( $confHolder->{'PrintErrorMsgs'} 	== 1 && $msg_type eq 'ERROR' ) ; 	
			p(@array ) if ( $confHolder->{'PrintWarningMsgs'} 	== 1 && $msg_type eq 'WARN' ) ; 	
			p(@array ) if ( $confHolder->{'PrintTraceMsgs'} 	== 1 && $msg_type eq 'TRACE' ) ; 	
		}

			
	}
	# eof sub LogArray


	#
	# -----------------------------------------------------------------------------
	# Just a wrapper around the Data::Printer 
	# with some additional logic on when what to print
	# to only print when debugging
	# call by: $objLogger->logHash ( \%hash )  ;
	# only print on global setting PrintInfoMsgs in ini file set to 1
	# call by: $objLogger->logHash ( \%hash , 'INFO' ) ; 
	# only print on global setting PrintWarningMsgs in ini file set to 1
	# call by: $objLogger->logHash ( \%hash , 'WARN' ) ; 
	# -----------------------------------------------------------------------------
	sub LogHashRef {

		my $self    	= shift ;
		my $refhash 	= shift ; 
		my $msg_type 	= shift ; 	

		my %hash 		= %{$refhash} ; 
		
		# if no message type is passed ( msg_type undefined ) do set it to debug
		$msg_type 		= $msg_type // 'DEBUG' ; 

		#debug print "\$msg_type is $msg_type	\n\n\n" ; 
		# some optimization in the hash is huge ... been there done that ... 
		return if ( $msg_type eq 'INFO' 	&& $confHolder->{'PrintInfoMsgs'} 		!= 1 )  ; 
		return if ( $msg_type eq 'WARN' 	&& $confHolder->{'PrintWarningMsgs'}	!= 1 )  ; 
		return if ( $msg_type eq 'ERROR' && $confHolder->{'PrintErrorMsgs'}		!= 1 )  ; 
		return if ( $msg_type eq 'TRACE' && $confHolder->{'PrintTraceMsgs'}		!= 1 )  ; 


		my $msg = p(%hash);

		$self->LogMsg( $msg )        if ( $msg_type eq "SIMPLE" ) ;
		$self->LogDebugMsg( $msg )   if ( $msg_type eq "DEBUG" ) ;
		$self->LogErrorMsg( $msg )   if ( $msg_type eq "ERROR" ) ;
		$self->LogWarningMsg( $msg ) if ( $msg_type eq "WARN" ) ;
		$self->LogInfoMsg( $msg )    if ( $msg_type eq "INFO" ) ;
		$self->LogWarningMsg( $msg ) if ( $msg_type eq "TRACE" );

		
		p(%hash ) if ( $confHolder->{'PrintDebugMsgs'} 	== 1 && $msg_type eq 'DEBUG' ) ; 	
		p(%hash ) if ( $confHolder->{'PrintInfoMsgs'} 		== 1 && $msg_type eq 'INFO' ) ; 	
		p(%hash ) if ( $confHolder->{'PrintErrorMsgs'} 	== 1 && $msg_type eq 'ERROR' ) ; 	
		p(%hash ) if ( $confHolder->{'PrintWarningMsgs'} 	== 1 && $msg_type eq 'WARN' ) ; 	
		p(%hash ) if ( $confHolder->{'PrintTraceMsgs'} 	== 1 && $msg_type eq 'TRACE' ) ; 	
			
	}
	# eof sub logHash


	#
	# -----------------------------------------------------------------------------
	# ALWAYS logs a fatal message
	# -----------------------------------------------------------------------------
	sub LogFatalMsg {

		my $self    = shift;
		my $msg     = "@_";
		my $msgType = '[FATAL]'; 
		
		$confHolder->{ 'PrintErrorMsgs' } = 1 ; 
		$self->LogMsg( $msgType, "$msg" ) ; 

	}
	# eof sub LogErrorMsg 


	#
	# -----------------------------------------------------------------------------
	# logs an error message
	# -----------------------------------------------------------------------------
	sub LogErrorMsg {

		my $self    = shift;
		my $msg     = "@_";
		my $msgType = '[ERROR]';

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'LogMsgs' } == 0 );

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'PrintErrorMsgs' } == 0 );

		$self->LogMsg( $msgType, "$msg" )
		  if ( $confHolder->{ 'PrintErrorMsgs' } == 1 );

	}
	# eof sub LogErrorMsg 


	#
	# -----------------------------------------------------------------------------
	# logs an error message
	# -----------------------------------------------------------------------------
	sub LogBroadCastMsg {

		my $self = shift;

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'LogMsgs' } == 0 );


		my @BroadCastTypes = ();
		my @msgs           = @_;

		#the msg is the last one of the
		my $msg = $msgs[ $#msgs ];

		foreach my $BroadCastType ( @msgs ) {

			# print "before \$BroadCastType is $BroadCastType \n" ;
			# print "before if \@BroadCastTypes is @BroadCastTypes \n" ;
			# print "before if \@msgs is @msgs \n" ;

			if (

					$BroadCastType eq "SIMPLE"
				or $BroadCastType eq "DEBUG"
				or $BroadCastType eq "ERROR"
				or $BroadCastType eq "WARN"
				or $BroadCastType eq "INFO"
				or $BroadCastType eq "TRACE"

			  )
			{

				# print "AFTER \@BroadCastTypes is @BroadCastTypes \n" ;
				# print "AFTER \@msgs is @msgs \n" ;
				push( @BroadCastTypes, $BroadCastType );

			}

		}
		#eof sub


		# do the actual "BroadCast"
		foreach my $BroadCastType ( @BroadCastTypes ) {

			$self->LogMsg( $msg )        if ( $BroadCastType eq "SIMPLE" );
			$self->LogDebugMsg( $msg )   if ( $BroadCastType eq "DEBUG" );
			$self->LogErrorMsg( $msg )   if ( $BroadCastType eq "ERROR" );
			$self->LogWarningMsg( $msg ) if ( $BroadCastType eq "WARN" );
			$self->LogInfoMsg( $msg )    if ( $BroadCastType eq "INFO" );
			$self->LogWarningMsg( $msg ) if ( $BroadCastType eq "TRACE" );

		} #eof foreach

	}
	#eof sub LogBroadCastMsg


	# -----------------------------------------------------------------------------
	# logs an warning message
	# -----------------------------------------------------------------------------
	sub LogWarningMsg {

		my $self    = shift;
		my $msg     = "@_";
		my $msgType = '[WARN ]';

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'LogMsgs' } == 0 );

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'PrintWarningMsgs' } == 0 );

		$self->LogMsg( $msgType, "$msg" )
		  if ( $confHolder->{ 'PrintWarningMsgs' } == 1 );

	}    
	#eof sub LogWarningMsg


	#
	# -----------------------------------------------------------------------------
	# logs an info message
	# -----------------------------------------------------------------------------
	sub LogInfoMsg {

		my $self = shift;

		# oldmy $msg = "@_" || "";
		my $msg = ( @_ ) ? "@_" : "";
		my $msgType = '[INFO ]';

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'LogMsgs' } == 0 );

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'PrintInfoMsgs' } == 0 );

		$self->LogMsg( $msgType, "$msg" )
		  if ( $confHolder->{ 'PrintInfoMsgs' } == 1 );

	}
	# eof sub LogInfoMsg


	#
	# -----------------------------------------------------------------------------
	# logs an trace message
	# -----------------------------------------------------------------------------
	sub LogTraceMsg {

		my $self    = shift;
		my $msg     = "@_";
		my $msgType = '[TRACE]';

		my ( $package, $filename, $line ) = caller();

		# Do not print anything if the PrintDebugMsgs = 0
		return if ( $confHolder->{ 'PrintTraceMsgs' } == 0 );

		$msg = "$msg : FROM Package: $package  FileName: $filename Line: $line  ";

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'LogMsgs' } == 0 );

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'PrintTraceMsgs' } == 0 );

		$self->LogMsg( $msgType, "$msg" )
		  if ( $confHolder->{ 'PrintTraceMsgs' } == 1 );

	}
	# eof sub LogTraceMsg
	 

	# -----------------------------------------------------------------------------
	# logs an Debug message
	# -----------------------------------------------------------------------------
	sub LogDebugMsg { 
		my $self    = shift;
		my $msg     = "@_";

		my $msgType = '[DEBUG]';

		#my ( $package, $filename, $line ) = caller();
		#$msg = "$msg : FROM Package: $package  FileName: $filename Line: $line  ";
		#print $msg ; 

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'LogMsgs' } == 0 );

		# Do not print anything if the PrintWarningMsgs = 0
		return if ( $confHolder->{ 'PrintDebugMsgs' } == 0 );

		$self->LogMsg( $msgType, "$msg" )
		  if ( $confHolder->{ 'PrintDebugMsgs' } == 1 );

	}    
	# eof sub LogDebugMsg


	#
	# -----------------------------------------------------------------------------
	# builds a nice message 
	# -----------------------------------------------------------------------------
	sub BuildMsg {

		my $self    	= shift;
		my $msgType 	= shift;
		my $msg 			= '' ; 
		
		my $HumanReadableTime      = $objTimer->GetHumanReadableTime();
			$HumanReadableTime 		= "$HumanReadableTime" ; 

		my $msgPrefix = () ; 
		$msgPrefix = " $HumanReadableTime [$PID] $LogTimeToTextSeparator"; 

		if (  $msgType eq '[WARN ]'
			|| $msgType eq '[INFO ]'
			|| $msgType eq '[DEBUG]'
			|| $msgType eq '[TRACE]' )
		{
			$msg = "$msgPrefix" . "$msgType @_ \n";
		}
		elsif ( $msgType eq '[ERROR]' ) {
			$msg = "$msgPrefix" . "$msgType @_ \n\n\n" ; 
		}
		elsif ( $msgType eq '[FATAL]' ) {
			$msg = "$msgPrefix" . "$msgType @_ \n\n\n\n\n";
		}
		else {
			$msg = "$msgPrefix" . "$msgType @_ \n";
		}

		return $msg;
	}
	# eof sub BuildMsg

	#
	# -----------------------------------------------------------------------------
	# formats a nice msg
	# -----------------------------------------------------------------------------
	sub FormatHtmlMsg {

		my $self    	= shift;
		my $msg_type	= shift ; 
		my $ref_msg 	= shift ; 


		if ( ref ( $msg_type) ) {
			$ref_msg = $msg_type ; 
			$msg_type = undef ; 
		}

		# if no message type is passed ( msg_type undefined ) do set it to debug
		$msg_type 		= $msg_type // 'DEBUG' ; 

		#debug print "\$msg_type is $msg_type	\n\n\n" ; 
		# some optimization in the array is huge ... been there done that ... 
		return if ( $msg_type eq 'INFO' 	&& $confHolder->{'PrintInfoMsgs'} 		!= 1 )  ; 
		return if ( $msg_type eq 'WARN' 	&& $confHolder->{'PrintWarningMsgs'}	!= 1 )  ; 
		return if ( $msg_type eq 'ERROR' && $confHolder->{'PrintErrorMsgs'}		!= 1 )  ; 
		return if ( $msg_type eq 'TRACE' && $confHolder->{'PrintTraceMsgs'}		!= 1 )  ; 
		return if ( $msg_type eq 'DEBUG' && $confHolder->{'PrintDebugMsgs'}		!= 1 )  ; 
		my $msg = '' ; 

		return unless ( ref ( $ref_msg ) ) ; 
		
		$msg = $self->BuildMsg ( "$msg_type" , $$ref_msg ) ; 
		my $str_html_new_line = '</br>'."\n" ; 
		$msg =~ s|\n|$str_html_new_line|g ; 
		#ok print "Logger msg: $msg" ; 
		$$ref_msg = $msg ;

	}
	# eof sub BuildMsg

	#
	# -----------------------------------------------------------------------------
	# logs a message based on the configuration settings 
	# -----------------------------------------------------------------------------
	sub LogMsg {

		my $self    = shift;
		my $msgType = shift;
		my	$msg 		= '' ;  	
		 
		$msg = $self->BuildMsg( $msgType,@_);
		

		#print to STDOUT and STDERR only if configured to print to console
		if ( $confHolder->{'PrintConsoleMsgs'} == 1 ) {
			# PRINT TO STDOUT if
			if (  $confHolder->{ 'PrintInfoMsgs' } 	== 1
				|| $confHolder->{ 'PrintDebugMsgs' } 	== 1
				|| $confHolder->{ 'PrintTraceMsgs' } 	== 1 ) {

				print STDOUT $msg unless ( $msgType eq '[ERROR]' ) ; 
			}

			if ( $confHolder->{ 'PrintErrorMsgs' } 
					&& $msgType eq '[ERROR]'	) {

				print STDERR $msg;
			}
		}
		
		# log to file only if configured so
		if ( $confHolder->{ 'LogToFile' } == 1 ) {
					$self->AppendToFile ( $LogFile, "$msg" );
		} #eof if

		# log to a file handle only if configured to
		if ( $confHolder->{ 'LogToFileHandle' } == 1 ) {
					$self->AppendToFileHandle ( "$msg" );
		} #eof if


	}
	# eof sub LogMsg


	#
	# -----------------------------------------------------------------------------
	# Appends the passed str to a file
	# -----------------------------------------------------------------------------
	sub AppendToFile {

		my $undef_file_msg	= 'Logger::AppendToFile undef file for writing passed !!!' ; 
		my $undef_str_msg 	= 'Logger::AppendTostr undef str for writing passed !!!' ; 
		my $error_msg 			= '' ; 
		my $msg 					= '' ; 

		my $self       		= shift;
		my $file 				= shift || cluck( "$undef_file_msg" );
		my $str_to_print 		= shift || cluck( "$undef_str_msg" );
		
		# do not write anything unless log file is configured or actually even passed	
		return unless ( defined ( $confHolder->{ 'LogToFile' } ) ) ;
		return unless ( $confHolder->{ 'LogToFile' } == 1 ) ; 
		return unless ( $file ) ; 
		return unless ( $str_to_print ) ; 

		$file =~ m/^(.*)([\/|\\])(.*)/g;
		my $FileDir = $1;

		# the owner of t
		$self->MkDir( $FileDir ) unless ( -d $FileDir ) ; 


		no warnings 'experimental::smartmatch';
		# the owner of the process might not be able to write to the file
		# src: http://search.cpan.org/~pjf/autodie-2.25/lib/autodie.pm	
		eval {
			use autodie ; 
			my $error_msg = "[FATAL] Logger::AppendToFile cannot open file: $file" ; 
			my $FH = () ; 
			open( $FH, ">>$file" ) || cluck( "$error_msg" ) ; 
			print $FH $str_to_print;
			close $FH ;
		};

		given ( $@ ) {
		  when (undef)   { $msg 		= "[INFO ] No error at all" ; }
		  when ('open')  { $error_msg = "[FATAL] Failed to open log file: $file" ; }
		  when (':io')   { $error_msg = "[FATAL] Non-open, IO error while openning log file: $file" ; }
		  when (':all')  { $error_msg = "[FATAL] All other autodie errors while openning log file: $file" ; }
		  default        { $msg 		= "[INFO ] No error at all" ; }
   	}
		
		if ( $error_msg ) {	
			my $solution_msg = " check the permissions of the log file : $file " ; 
			$error_msg .= $solution_msg ; 
			croak ( $error_msg ) ; 
		}	

		use warnings 'experimental::smartmatch';
		return 1 ; 
	}
	# eof sub AppendToFile

	
	#
	# -----------------------------------------------------------------------------
	# Create a dir or cluck why it can't
	# use by if ( $self->MkDir ( $dir_to_create ) ; 
	# -----------------------------------------------------------------------------
	sub MkDir {

		my $self        	= shift;
		my $dir_to_create = shift;

		my $error_msg 		= '' ; 
		my $msg 				= '' ; 	

		no warnings 'experimental::smartmatch';

		# if there is !no directory!
		unless ( -d "$dir_to_create" ) {
			eval { 
				use autodie ; 
				my $error_msg = "Logger::MkDir failed to create directory $dir_to_create $! !!!"  ; 
				mkpath( "$dir_to_create" ) || cluck( "$error_msg" ) ;  
			};

			given ( $@ ) {
				when (undef)   { $msg 			= "[INFO ] No error. Proceed " ; }
				when ('open')  { $error_msg 	= "[FATAL] failed to open the dir: $dir_to_create" ; }
				when (':io')   { $error_msg 	= "[FATAL] Non-open, IO error for the dir: $dir_to_create " ; }
				when (':all')  { $error_msg 	= "[FATAL] All other autodie errors for the dir: $dir_to_create " ; }
		  		default        { $msg 			= "[INFO ] No error at all" ; }
			}
			if ( $error_msg ) {
				my $solution_msg = " check the permissions of the dir to create: $dir_to_create " ; 
				$error_msg .= $solution_msg ; 
				croak ( $error_msg ) ; 	
				return 0 ; 
			}
			else { 
				return 1 ; 
			}

		}    
		else {
			#dir exists alles gut !!!
			return 1;
		}
		
		use warnings 'experimental::smartmatch';

	}    
	#eof sub


	# STOP functions
	# =============================================================================



1;

__END__


=head1 NAME

Logger 

=head1 SYNOPSIS

use Logger  ; 


=head1 DESCRIPTION
Provide a simple interface for dynamic logging... 

2011.06.11-13:33:11 --- this is a simple message  
2011.06.11-13:33:11 --- ERROR : This is an error message  
2011.06.11-13:33:11 --- WARN : This is a warning message  
2011.06.11-13:33:11 --- INFO : This is a info message  
2011.06.11-13:33:11 --- DEBUG : This is a debug message  
2011.06.11-13:33:11 --- TRACE : This is a trace message  : FROM Package: Morphus  

- Logger does initialize all the config values it is utilizing on Initialize if they do not exist in the config file 
- Logger understands the following type of msgs : DEBUG,ERROR,TRACE,INFO,WARN, SIMPLE
- Logger prints each type of msgs into a file if configured to do so
- The TRACE type of msg does provide a file , line of file of the caller
- When called with the LogBroadCastMsg ( "ERROR" , "INFO" , "ANYOTHERTYPE" , $msg ) ; Logger will output both the ERROR and the INFO msg 


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
2.1.6 -- 2014-08-26 09:37:36 -- ysg -- autodie and better checks in AppendToFile
2.1.5 -- 2014-08-25 21:01:58 -- ysg -- added PrintToConsole settings
2.1.4 -- 2013-03-03 20:00:58 -- ysg -- cleaned up formatting for MSG types
2.1.3 -- 2013-03-03 20:00:58 -- ysg -- added msg prefix
2.1.2 -- 2013-02-14 17:11:45 -- ysg -- re-factor 
2.1.1 -- 2013-02-13 16:36:54 -- ysg -- added LogFatalError
2.1.0 -- 2013-02-12 20:49:18 -- ysg -- log to an opened file handle
2.0.0 -- 2012-12-26 14:54:33 -- ysg -- refactoring, LogFile as our
1.9.1 -- 2012-12-24 14:37:53 -- ysg -- formatting 
1.8.0 -- 2011.08.30 12:00:00 -- ysg -- Removed dependancy from FileHandler
1.8.0 -- 2011.08.13 17:23:49 -- ysg -- new constructor
1.7.0 -- 2011.07.02 12:00:00 -- ysg -- Removed Rotate Logs 
1.6.0 -- 2011.07.02 12:00:00 -- ysg -- Added LogBroadCastMsg
1.5.2 -- 2011.07.02 12:00:00 -- ysg -- Added docs in Descrption + specs for the RotateLogs feature , Initialize
1.5.0 -- 2011.06.25 12:00:00 -- ysg -- WIP. Added RotateLogs in Initialization
1.4.0 -- 2011.06.11 12:00:00 -- ysg -- Separated actions of building and printing msgs. Total refactoring. Beta . 
1.3.0 -- 2011.06.09 12:00:00 -- ysg -- Added Initialize 
1.2.8 -- 2011.06.07 12:00:00 -- ysg -- Added LogInfoErrorMsg print both to all possible
1.2.8 -- 2011.06.07 12:00:00 -- ysg -- added default values if conf values are not set 
1.0.0 -- 2011.06.07 12:00:00 -- ysg -- Create basic methods 
1.0.0 -- 2011.06.07 12:00:00 -- ysg -- Stolen shamelessly from several places of the Perl monks ...

=cut 

