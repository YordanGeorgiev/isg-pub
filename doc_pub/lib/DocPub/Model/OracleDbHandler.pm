package DocPub::Model::OracleDbHandler ; 

   use strict ; use warnings ; use utf8 ; 

   require Exporter; 
   use AutoLoader ; 
	use Encode qw( encode_utf8 is_utf8 );
   use POSIX qw(strftime);
   use DBI ; 
	use Data::Printer ; 
	use Carp ; 

	# use DBD::Oracle ; 
	# do not force the average users to install the oracle client
	# it is not worth the pain if they won't use it anyway ... 
	BEGIN {
		my $sqlplus_found = grep { -x "$_/sqlplus"}split /:/,$ENV{PATH} ; 
		if ( $sqlplus_found >= 1 ) {
			require DBD::Oracle ; 
			import DBD::Oracle ; 
			require DateTime::Format::Oracle ; 
			import DateTime::Format::Oracle ; 
		}

	}

	#use XML::XPath ;
	#use XML::XPath::XMLParser ;
	#use XML::Writer ;
	#use XML::LibXML ;
	#use XML::XPath::Node::Element ;

   our $ModuleDebug	                                    = 0 ; 
   our $IsUnitTest                                    	= 0 ; 
	our $app_config 													= q{} ; 
	our $mod_config 													= q{} ; 
	our $objLogger 													= q{} ; 
	our $objController 												= q{} ; 

	our $ora_user														= q{} ; 
	our $ora_user_pw													= q{} ; 
	our $sid 															= q{} ; 
	our $db_host														= q{} ; 
	our $db_port														= q{} ; 
	our $schema															= q{} ; 
	
   #
   # -----------------------------------------------------------------------------
	# get any data from the oracle database 
   # -----------------------------------------------------------------------------
	sub list_query_data {

		my $self 		= shift;
		my $sql			= shift ; 

		# remove the multiline comments - http://stackoverflow.com/a/27682423/65706
		$sql =~ s/\/\*([\s\S]*?)\*\///g ; 
		# remove the single line comments
		$sql =~ s/\s?\-\-([\s\S]*?)\r?\n/ /g ; 
		# remove the semicolons ; - ora dbd trows errors for those !!!
		$sql =~ s/\s?;([\s\S]*?)/ /g ; 
		$self->{'Sql'} = $sql ; 
		#$sql =~ s/\r?\n/ /mg ; 
		#debug print "running the following sql :: $sql \n\n" ; 
	
		DBI->trace(4);


		my $dbh = DBI->connect('dbi:Oracle:host=' . "$db_host" . ';sid=' . "$sid" . ';port=' . "$db_port" , 
			"$ora_user" , "$ora_user_pw", { RaiseError => 1, AutoCommit => 0 })
			|| die "Database connection not made: $DBI::errstr";

		# todo: ensure utf-8 is in use
		 $dbh->do( "alter session set nls_date_format = '" .
		 				DateTime::Format::Oracle->nls_date_format ."'"
		   );
		$dbh->do("alter session set current_schema=$schema");
		#debug print "\n\n sql:: $sql \n\n" ; 
		my $sth = $dbh->prepare( $sql ) ; 
		
		$sth->execute() ; 
		
		my $res_meta = {}  ;
		my $i = 1 ; 
		my $rfArrHeaders = $sth->{'NAME'} ; 
		foreach my $header ( @$rfArrHeaders ) {
			my $tmp = {} ; 
			$tmp->{"COLUMN_NAME"} = $header ; 
			$tmp->{'ORDINAL_POSITION'} = $i ;
			$res_meta->{$i} = $tmp ; 
			$i++ ; 
		}
		$self->set('ResMeta' , $res_meta );

		# populate the array references with hash references 
		my @query_output = () ; 
		
		while ( my $row = $sth->fetchrow_hashref ){
			push @query_output, $row;
		} 

		# close the db connection
		$dbh->disconnect();

		return \@query_output ; 	
	}
	#eof sub list_items


   #
   # -----------------------------------------------------------------------------
   # doInitialize the object with the minimum data it will need to operate 
   # -----------------------------------------------------------------------------
   sub doInitialize {

      my $self 			= shift ;
		my $objController = shift ; 
		
		# get the application configuration hash
		# global app config hash
		$app_config 	= $objController->app->get('AppConfig') ; 
		$objLogger 		= $objController->app->get('ObjLogger') ;

		my $ConfDir 			= $app_config->{'ConfDir'} ;
		my $conn_hook 			= $objController->req->param('conn') || 'dev_sor_core_kon' ;
		$schema 			= $objController->req->param('schema') || 'INFAREPO_SYS' ;
		my $conn_conf_file 	= $ConfDir . '/' . $conn_hook . '.ora.conf' ; 
		
		# get the application configuration hash
		$mod_config = $objController->app->plugin (
			'Config' , { 'file' => $conn_conf_file } 
		);
		
		$ora_user			= $mod_config->{'ora_user'}  ;
		$ora_user_pw		= $mod_config->{'ora_user_pw'}  ;
		$sid 					= $mod_config->{'sid'}  ;
		$db_host				= $mod_config->{'ora_db_host'} ; 
		$db_port				= $mod_config->{'ora_db_port'} ; 
		
		$ENV{'ORACLE_HOME'} 		= $app_config->{'ORACLE_HOME'} ; 
		$ENV{'PATH'} 				= $app_config->{'ORACLE_HOME'} . "/bin" ;
		$ENV{'LD_LIBRARY_PATH'} = $app_config->{'ORACLE_HOME'} . "/lib";
		$ENV{'TNS_ADMIN'} 		= $app_config->{'TNS_ADMIN'} ; 
		$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
		$ENV{'PROXY_USER'} 		= $ora_user ; 
		#$ENV{'CURRENT_SCHEMA'} 	= 'INFAREPO_SYS' ; 
		#$ENV{'SESSION_USER'} 	= 'INFAREPO_SYS' ; 
   }
   #eof sub doInitialize


   #
   # -----------------------------------------------------------------------------
   # the constructor # source:http://www.netalive.org/tinkering/serious-perl/#oop_constructors 
	# -----------------------------------------------------------------------------
   sub new {

      my $class            = shift ;    # Class name is in the first parameter
		$objController			= ${ ( shift @_ ) } ; 

		my @args 				= ( @_ ); 

      # Anonymous hash reference holds instance attributes
      my $self = {}; 
      bless($self, $class);     # Say: $self is a $class

      $self->doInitialize( $objController ) ; 
      return $self;
   } 
   #eof const 
	

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
	
1;


__END__


=head1 NAME

OracleDbHandler

=head1 SYNOPSIS

use DocPub::Model::OracleDbHandler
  
=head1 DESCRIPTION


=head2 EXPORT


=head1 SEE ALSO

  perldoc perlvars

  No mailing list for this module


=head1 AUTHOR

  yordan.georgiev@gmail.com

=head1 COPYRIGHT LICENSE

  Copyright (C) 2015 Yordan Georgiev

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.8.1 or,
  at your option, any later version of Perl 5 you may have available.

=cut


# 
# -----------------------------------------------------------------------------
# --  VersionHistory
# -----------------------------------------------------------------------------
#
#
# 1.0.1 -- 2015-08-28 14-22-24 -- ysg -- refactoring , mod init
# 1.0.0 -- 2015-08-24 13-22-44 -- ysg -- initial version 
#
#
# eof file: doc_pub/lib/DocPub/Model/OracleDbHandler.pm
