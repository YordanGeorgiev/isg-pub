package DocPub;
# this package could access all the methods and attributes of the base mojo app
use Mojo::Base 'Mojolicious';
use utf8 ; 
use Mojo::Log;
use Mojolicious::Sessions;
use Mojolicious::Static;

use DocPub::Utils::Initiator ; 
use DocPub::View::ControlFactory ; 
use DocPub::Controller::Initializer ; 


our $app_config  		= q{} ; 
our $objLogger 		= q{} ; 
our $objInitiator ; 
our $redis_client    = q{} ; 

my %ItemViews        = ();
my $refItemViews     = {} ; 


	# This method will run once at server start
	sub startup {
		my $self = shift;
		
		$self->doInitialize () ; 


		# get the router Router
		# the app instance has routes attribute - a router you can use
		# to generate route structures, they match in the same order in which they were defined.
		my $r = $self->routes;
		
		# ui rest call
		# http://localhost:3000/view?rdbms=mysql
		$r->get('/')->to(
		  controller 	=> 'doc_view'
		, action 		=> 'view_item_doc'
		);

		# ui rest call
		# http://localhost:3000/view?rdbms=mysql
		$r->get('/present')->to(
		  controller 	=> 'present_view'
		, action 		=> 'view_item_doc'
		);

		# ui rest call
		# http://web_host:3000/list?item=Issue
		$r->get('/list')->to(
				  controller => 'list'
				, action => 'list_items'
			);
		# ui post call
		# http://web_host:3000/list?item=Issue
		$r->post('/list')->to(
				  controller => 'list'
				, action => 'edit_item'
			);
		$r->delete('/list')->to(
		  controller 	=> 'list'
		, action 		=> 'remove_item'
		);

		# ui rest call
		# http://localhost:3000/view?rdbms=mysql
		$r->get('/view')->to(
		  controller 	=> 'doc_view'
		, action 		=> 'view_item_doc'
		);
		
		# ui rest call
		# http://localhost:3000/view?rdbms=mysql
		$r->get('/render')->to(
		  controller 	=> 'Renderer'
		, action 		=> 'render_control'
		);
		
		# ui rest call
		# http://localhost:3000/view?rdbms=mysql
		$r->get('/viewpdf')->to(
		  controller 	=> 'pdf_view'
		, action 		=> 'view_item_doc'
		);
		
		
		# ui rest call
		# http://localhost:3000/view?rdbms=mysql
		$r->get('/show')->to(
		  controller 	=> 'Show'
		, action 		=> 'view_item_doc'
		);

		# used by the jeditable 
		$r->get('/get_item_to_edit')->to(
		  controller 	=> 'doc_view'
		, action 		=> 'get_item_to_edit'
		);
		
		# when editing from view
		# http://localhost:3000/view?id=the_id&value=the_value
		$r->post('/post_item_to_edit')->to(
		  controller 	=> 'doc_view'
		, action 		=> 'post_item_to_edit'
		);
		
		# when reshuffling items
		$r->post('/post_item_to_reshuffle')->to(
		  controller 	=> 'doc_view'
		, action 		=> 'post_item_to_reshuffle'
		);
	
		# search from names and descriptions or by meta tags
		$r->get('/search')->to(
		  controller 	=> 'search'
		, action 		=> 'view_item_doc'
		, template 		=> 'view/view_item_doc'
		);

		# search from names and descriptions or by meta tags
		$r->post('/search')->to(
		  controller 	=> 'search'
		, action 		=> 'view_item_doc'
		, template 		=> 'view/view_item_doc'
		);
		
		$r->get('/search_autocomplete')->to(
		  controller 	=> 'search_autocomplete'
		, action 		=> 'search_items'
		);


		# list first the items 
		# http://web_host:3000/edit?item=Issue
		$r->get('/edit')->to(
		  controller 	=> 'edit'
		, action 		=> 'list_items'
		);


		# http://web_host:3000/list_json?item=Issue
		$r->post('/edit')->to(
		  controller 	=> 'edit'
		, action 		=> 'edit_item'
		);

		$r->post('/add_new')->to(
		  controller 	=> 'edit'
		, action 		=> 'add_new_item'
		);
		$r->delete('/remove')->to(
		  controller 	=> 'edit'
		, action 		=> 'remove_item'
		);

		# backend json call 
		# http://web_host:3000/list_json?item=Issue
		$r->get('/list_json')->to(controller => 'list', action => 'list_items_json');
		
		# ui rest call
		# http://web_host:3000/list?item=Issue
		$r->get('/query')->to(
			controller => 'query'
			, action => 'show_query_ui'
		);
		# backend json call 
		# http://web_host:3000/query_json?item=Issue
		$r->post('/query')->to(
				controller => 'query'
				, action => 'list_query_data'
			);
		
		
		# backend json call 
		$r->get('/show_json')->to(
			controller => 'show',
			action => 'show_item_json'
		);
		
		# ui rest call
		$r->get('/edit')->to(
			controller => 'edit', 
			action => 'edit_item');

		# backend json call 
		$r->get('/edit_json')->to(
			controller => 'edit',
			action => 'edit_item_json');

		# ui rest call
		# http://web_host:3000/list?item=Issue
		$r->get('/export')->to(
				  controller => 'Export'
				, action => 'export_items'
			);

		# ui rest call
		# http://web_host:3000/list?item=Issue
		$r->get('/list1')->to(controller => 'list1', action => 'list_items');
		# backend json call 
		# http://web_host:3000/list_json?item=Issue
		$r->get('/list_json1')->to(controller => 'list1', action => 'list_items_json');

		$r->get('/')->to('example#welcome');
		#$r->get('/display')->to('display#welcome');

		# Normal route to controller
		# The minimal route above will load and instantiate the class 
		#
		#

	}
	# eof startup

	
	#
	# ------------------------------------------------------
	# configure the routes of the app
	# ------------------------------------------------------
	sub doInitialize {
		my $self = shift ; 
		
		$objInitiator = new DocPub::Utils::Initiator();
		my $app_conf_file 		= $objInitiator->get('ConfFile') ; 
		my $product_version_dir = $objInitiator->get('ProductVersionDir') ; 

		#print "DocPub.pm app_conf_file ::: $app_conf_file " . "\n" ; 

		# get the application configuration hash
		$app_config = $self->plugin ('Config' 
			, { "file" => $app_conf_file } 
		);
		$self->set('AppConfig' , $app_config );

		$app_conf_file =~ s/(.*)\/(.*)/$1/g ; 	
		$app_config->{'ConfDir'} = $app_conf_file ;
	
		$objLogger 				= $objInitiator->doInitializeLogger () ; 	
		$self->set('ObjLogger', $objLogger );

		$objLogger->debug( "the database is : " . $app_config->{'database'} );
		$objLogger->debug( "the db_user is : " . $app_config->{'db_user'} );
		$objLogger->debug( "the db_user_pw is : " . $app_config->{'db_user_pw'} );

      
		my $sessions = Mojolicious::Sessions->new;
		$sessions->cookie_name('doc_pub');
		$sessions->default_expiration(86400);
      
      # use Redis::Client;
      ##  $redis_client = 'Redis::Client'->new( host => 'localhost', port => 6379 );

	   $self->plugin('RenderFile');
      
	}
	#eof sub doInitialize




   # called only on request
   sub getAppStructureData {

      my $self             = shift ; 
      my $objController    = ${ shift @_ } ; 
      my $app_name         = shift ; 
      my $key              = $app_name . '.RefItemViews' ; 

      my $refItemViews = $self->get( $key ) ; 
      #debug print "KEY IS $key !!! \n\n" ; 
   
      unless ( $refItemViews ) {
         my $objInializer = 'DocPub::Controller::Initializer'->new ( \$objController ) ; 
         $refItemViews = $objInializer->doLoadAppPages ; 

         $self->set ( $key , $refItemViews ) ; 
      } 
       
      return $refItemViews ; 

   } # sub getAppStructureData 

	
	#
	# ------------------------------------------------------
	# configure the routes of the app
	# ------------------------------------------------------
	sub doConfigureRendering {
		my $self = shift ; 
		
		#ensure the app is using utf-8 encoding by default
		$self->renderer->encoding('utf-8');
		$self->renderer->default_format('html');

		$self->types->type(txt => 'text/plain; charset=utf-8');
		$self->types->type(json => 'text/plain; charset=utf-8');
		# Documentation browser under "/perldoc"
		$self->plugin('PODRenderer');
	}
	#eof sub doInitialize
	
	
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
1;

# VersionHistory 
# ---------------------------------------------------------
# 1.0.1 -- 2015-07-25 21:24:47 -- ysg -- 
# 1.0.0 -- 2015-07-25 21:24:04 -- mojo -- orig
#
