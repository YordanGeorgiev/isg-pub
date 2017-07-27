package DocPub::Controller::Initializer ; 
use utf8 ; 
use Mojo::Base 'Mojolicious::Controller';


use Data::Printer ; 

use DocPub::Model::DbHandlerFactory ; 
use Carp ; 


our $app_config  ; 
our $objLogger ; 
our $doWhiteSpace = 1 ; 
our $ModuleDebug	= 0 ; 
our $objCallController = q{} ; 

sub doLoadAppPages {

   my $self                = shift ; 

	my $rdbms_type				= $objCallController->param('rdbms') 		|| 'mysql' ; 

	my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new( \$objCallController );
	my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );

   
   my $refItemViews        = $objDbHandler->doLoadAppPagesData() ; 
   
   return $refItemViews ; 
   
}
# eof sub doLoadItemViews


	#
	# -----------------------------------------------------------------------------
	# the constructor 
	# -----------------------------------------------------------------------------
	sub new {
		
		my $invocant 			   = shift ;    
      $objCallController      = ${ shift @_ } ;  
		
		# might be class or object, but in both cases invocant
		my $class = ref ( $invocant ) || $invocant ; 

		my $self = {};        # Anonymous hash reference holds instance attributes
		
		bless( $self, $class );    # Say: $self is a $class
		return $self;
	}   
	#eof const


1;

__END__
