package DocPub::Controller::List1 ; 
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Parameters;
use DBI;
use DBD::mysql;
use JSON;
use Data::Printer ; 
use utf8 ; 
use Encode qw( encode_utf8 is_utf8 );
use JSON   qw( decode_json );

# add the showsub action in the Get controller 
sub list_items_json {
  my $self = shift;

	#   
	# CONFIG VARIABLES
	my $database = $self->param('db') || 'isg_pub_en'  ;
	my $host = "localhost";
	my $port = "13306";
	my $user = "root";
	my $pw = "0024plapla";
	my $table = $self->param('item')  ;
	my $filter_field = $self->req->query_params->param('filter-by')  ;
	my $filter_value = $self->param('filter-val')  ;
	# debug my $term = 'search' ;     

	# DATA SOURCE NAME
	my $dsn = "dbi:mysql:$database:localhost:$port";

	# PERL DBI CONNECT
	my $connect = DBI->connect($dsn, $user, $pw);
	# obs 1 the db handle MUST be utf8 aware 
	$connect->{'mysql_enable_utf8'} = 1;
	#my $connect = DBI->connect($dsn, $user, $pw , {mysql_enable_utf8 => 1});
		  
	my $sql = '' ; 
	$sql .= "SELECT * FROM $table " if $table ; 
	$sql .= "WHERE 1=1 " ; 

	my $query_handle = $connect->prepare( "$sql" ) ; 
	$query_handle->execute ( $database ) ; 

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

	# quickly visualize the json output @: http://json.bloople.net/
	#$self->render(json => {$table => \@query_output});
	# print "Content-type: application/json; ;charset=utf-8\n\n";
	$self->res->headers->content_type('application/json; charset=utf-8');
	$self->res->headers->accept_charset('UTF-8');
	$self->res->headers->accept_language('fi, en') ; 
	#utf8::encode( @query_output );
	# p(@query_output) ;

	#use utf8;

	# my $data_json = \@query_output ; 
	#my $data = decode_json(encode_utf8($data_json));

	#my $ref_query_output = encode_json ( \@query_output , 'utf-8' );
	#$self->render(json => \@query_output , charset=> 'utf-8');
	$self->render(json => \@query_output );
	#my $str_out = p( @query_output ) ; 
	#$self->render(text => \@query_output);
}




# add the showsub action in the Show controller 
sub list_items {
   my $self = shift;

	#   
	# CONFIG VARIABLES
	my $database = $self->param('db') || 'isg_pub_en'  ;
	my $proj_db = 'isg_pub_en' ; 
	my $host = "localhost";
	my $port = "13306";
	my $user = "root";
	my $pw = "0024plapla";
	my $table = $self->param('item')  ;
	# package vars 
	my $td_list = '' ; 
	my $th_list = '' ; 
	#my $filter_field = $self->req->query_params->param('filter-by')  ;
	#my $filter_value = $self->param('filter-val')  ;
	# debug my $term = 'search' ;     

	# DATA SOURCE NAME
	my $dsn = "dbi:mysql:$database:localhost:$port";

	# PERL DBI CONNECT
	my $connect = DBI->connect($dsn, $user, $pw);
		  
	my $sql = '' ; 
	$sql .= "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE 1=1 AND TABLE_NAME='" ; 
	$sql .= "$table" . "'"  ; 
	$sql .= " AND TABLE_SCHEMA='" . "$proj_db" . "'" . ';' ; 

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
	);


}
#eof sub list_table 

1;

__END__
