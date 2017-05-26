package DocPub::Controller::List2 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;
use DBI;
use DBD::mysql;
use JSON;
use Data::Printer ; 
use utf8 ; 
use Encode qw( encode_utf8 is_utf8 );
use JSON   qw( decode_json );
use Data::Printer ; 

our $app_config ; 
our $objLogger ; 

# add the showsub action in the Get controller 
sub list_items_json {
  	my $self = shift;

	# get the application configuration hash
	# global app config hash
	$app_config 	= $self->app->get('AppConfig') ; 
	$objLogger 		= $self->app->get('ObjLogger') ; 

	$objLogger->debug( "from list_items_json the database is : " . $app_config->{'database'} );
	$objLogger->debug( "from list_items_json the db_user is : " . $app_config->{'db_user'} );
	$objLogger->debug( "from list_items_json the db_user_pw is : " . $app_config->{'db_user_pw'} );


	# CONFIG VARIABLES
	my $database = $self->param('db') || $app_config->{'database'} ; 
	my $db_host = $app_config->{'db_host'} || 'localhost' ;
	my $db_port = $app_config->{'db_port'} || '13306' ; 
	my $db_user = $app_config->{'db_user'} || '13306' ; 
	my $db_user_pw = $app_config->{'db_user_pw'} || '13306' ; 

	my $table = $self->param('item')  ;
	
	my $filter_name = '' ; 
	my $filter_value = '' ; 

	my $ref_filter_names = $self->every_param('filter-by')  ;
	my $ref_filter_values = $self->every_param('filter-value')  ;
	
	print "\@list: filter_values\n" ; 
	p($ref_filter_values) ;
	print "\@list: filter_names\n" ; 
	p($ref_filter_names) ;

	my $optional_url_params = ' ' ; 

	$optional_url_params .= ' , "db": "' . $database . '"' 
	if ( defined ( $database ) ) ; 

	if ( @$ref_filter_names and @$ref_filter_names ) {

		for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

			$filter_value = $ref_filter_names->["$i"] ; 	
			$filter_name = $ref_filter_names->["$i"] ; 	

			$filter_value =~ s/(^|_)./uc($&)/ge;s/_//g ;
		}
	}

	# DATA SOURCE NAME
	my $dsn = "dbi:mysql:$database:localhost:$db_port";

	# PERL DBI CONNECT
	my $connect = DBI->connect($dsn, $db_user, $db_user_pw);
	# obs 1 the db handle MUST be utf8 aware 
	$connect->{'mysql_enable_utf8'} = 1;
	#my $connect = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1});
		  
	my $sql = '' ; 
	$sql .= "SELECT * FROM $database" . '.' . "$table " if $table ; 
	$sql .= "WHERE 1=1 " ; 

	if ( @$ref_filter_names and @$ref_filter_names ) {

		for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

			$filter_value = $ref_filter_values->["$i"] ; 	
			$filter_name = $ref_filter_names->["$i"] ; 	
			
			$objLogger->debug ( "List::list filter_name: $filter_name ");
			$objLogger->debug ( "List::list filter_value: $filter_value ");
			#$filter_name =~ s/(^|_)./uc($&)/ge;s/_//g ;
			$filter_value =~ s/(^|_)./uc($&)/ge;s/_//g ;

			$sql .= "AND lower($filter_name) LIKE '%" . $filter_value . "%' \n" 
				if ( defined ( $filter_value ) and defined ( $filter_name ) );
		}
	}
	
	$objLogger->debug ( "List::list_items_json sql : $sql" ) ; 


	my $query_handle = $connect->prepare( "$sql" ) ; 
	$query_handle->execute () ; 

	# EXECUTE THE QUERY
	$query_handle->execute();

	my @query_output = () ; 
	# LOOP THROUGH RESULTS
	use utf8 ; 
	while ( my $row = $query_handle->fetchrow_hashref ){
		 my %hash = %$row ; 
		 #for my $key ( sort keys %hash ) {
		  	# say "UTF8 flag is turned on in the STRING $key" if is_utf8( $hash{$key} );
			#say "UTF8 flag is NOT turned on in the STRING $key" if not is_utf8( $hash{$key} );
		 # }
		 push @query_output, $row;
	} #eof while

	# CLOSE THE DATABASE CONNECTION
	$connect->disconnect();

	$self->res->headers->accept_charset('UTF-8');
	$self->res->headers->accept_language('fi, en') ; 
	# quickly visualize the json output @: http://json.bloople.net/
	$self->res->headers->content_type('application/json; charset=utf-8');
	#utf8::encode( @query_output );
	# p(@query_output) ;

	#my $ref_query_output = encode_json ( \@query_output , 'utf-8' );
	#$self->render(json => \@query_output , charset=> 'utf-8');
	$self->render(json => \@query_output );
}
#eof sub



# add the showsub action in the Show controller 
sub list_items {
   my $self = shift;

	# get the application configuration hash
	# global app config hash
	$app_config 	= $self->app->get('AppConfig') ; 
	$objLogger 		= $self->app->get('ObjLogger') ;

	$objLogger->debug( "from list_items the database is : " . $app_config->{'database'} );
	$objLogger->debug( "from list_items the db_user is : " . $app_config->{'db_user'} );
	$objLogger->debug( "from list_items the db_user_pw is : " . $app_config->{'db_user_pw'} );


	# CONFIG VARIABLES
	my $database = $self->param('db') || $app_config->{'database'} ; 
	my $db_host = $app_config->{'db_host'} || 'localhost' ;
	my $web_host = $app_config->{'web_host'} || 'localhost' ;
	my $db_port = $app_config->{'db_port'} || '13306' ; 
	my $db_user = $app_config->{'db_user'} || '13306' ; 
	my $db_user_pw = $app_config->{'db_user_pw'} || '13306' ; 
	#my $values = $self->every_param('foo');
	my $table = $self->param('item')  ;
	# package vars 
	my $td_list = '' ; 
	my $th_list = '' ; 

	my $filter_name = '' ; 
	my $filter_value = '' ; 

	my $ref_filter_names = $self->every_param('filter-by')  ;
	my $ref_filter_values = $self->every_param('filter-value')  ;
	
	print "\@list_items: filter_values\n" ; 
	p($ref_filter_values) ;
	print "\@list_items: filter_names\n" ; 
	p($ref_filter_names) ;
	
	my $optional_url_params = ' ' ; 

	$optional_url_params .= ' , "db": "' . $database . '"' 
	if ( defined ( $database ) ) ; 

	if ( @$ref_filter_names and @$ref_filter_names ) {

		my $filter_by_arr = '[' ; 
		my $filter_val_arr = '[' ; 

		for ( my $i = 0 ; $i < scalar ( @$ref_filter_names ) ; $i++ ) {

			$filter_value = $ref_filter_values->["$i"] ; 	
			$filter_name = $ref_filter_names->["$i"] ; 	

			$filter_name =~ s/(^|_)./uc($&)/ge;s/_//g ;
			$filter_value =~ s/(^|_)./uc($&)/ge;s/_//g ;
			# var params = {};
			#  params.someParmName = ['value1', 'value2'];
			$filter_by_arr .= "'" . $filter_name . "' , " ; 
			$filter_val_arr .= "'" . $filter_value . "' , " ; 
		} #eof for

			$filter_by_arr =~ s/ , $//g ;
			$filter_val_arr =~ s/ , $//g ;

			$filter_by_arr .= ']' ; 
			$filter_val_arr .= ']' ; 

			$optional_url_params .= ' , "filter-by": ' . $filter_by_arr  ; 
			$optional_url_params .= ' , "filter-value": ' . $filter_val_arr  ; 

	}
	#eof if

	# DATA SOURCE NAME
	my $dsn = "dbi:mysql:$database:localhost:$db_port";

	# PERL DBI CONNECT
	my $connect = DBI->connect($dsn, $db_user, $db_user_pw);
		  
	my $sql = '' ; 
	$sql .= "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE 1=1 AND TABLE_NAME='" ; 
	$sql .= "$table" . "'"  ; 
	$sql .= " AND TABLE_SCHEMA='" . "$database" . "'" . ';' ; 

	# print "sql: $sql \n" ; 
	my $sth = () ; 
	$sth = $connect->prepare( "$sql" ) or die $sth->errstr ; 
	my @query_output = () ; 

	my $res = $sth->execute() or die $sth->errstr ; 
	my @row = () ;
	while ( @row = $sth->fetchrow_array() ){
		 push @query_output, $row[0];
		 $th_list .=	'<th>' . $row[0] . '</th>' ."\n" ; 
		 $td_list .=	'<td>{{' . $table . '.' .  $row[0] . '}}</td>' . "\n" ; 
		 # print join(", ", @row), "\n";
		 # print "col " . $row[0] . "\n" ; 

	} #eof while
	
	#print "th_list $th_list \n" ; 
	#print "td_list $td_list \n" ; 
	$res = $sth->finish();

	# CLOSE THE DATABASE CONNECTION
	$connect->disconnect();

	#$self->stash(table => $table);
	#$self->stash(th_list => $th_list );
	#$self->stash(td_list => $td_list );
	
	#print "th_list $th_list \n" ; 

  	$self->render(
		table => $table 
	 , database => $database
	 , th_list => $th_list 
	 , td_list => $td_list 
	 , optional_url_params => $optional_url_params
	 , web_host => $web_host 
	);


}
#eof sub list_table 

1;

__END__
