use Mojolicious;
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Data::Printer ; 
use FindBin;
use lib "$FindBin::Bin/../lib";


my $t = Test::Mojo->new('DocPub');
my $app = $t->app;

#doParseIniEnvVars sfw/sh/isg-pub/isg-pub.mini-nz.doc-pub-host.conf
my $database = $ENV{'project_db'} || 'isg_pub_en' ; 
#debug print $ENV{'project_db'} ; 

my $rdbms_type = 'mysql' ; 
#my $req = Mojo::Message::Request->new;

my $objDocViewCotroller = $t->app->build_controller ( DocPub::Controller::DocView->new )  ;
$objDocViewCotroller     = $objDocViewCotroller->tx(Mojo::Transaction::HTTP->new);

my $objDbHandlerFactory = 'DocPub::Model::DbHandlerFactory'->new(\$objDocViewCotroller);
my $objDbHandler 			= $objDbHandlerFactory->doInstantiate ( "$rdbms_type" );
$objDbHandler->set('Db' , $database ) ; 

my $refItemViews = $objDbHandler->doGetItemViews();
my @page_types = qw ( view list viewpdf ) ; 

p($refItemViews ) ; 

		my @sorted_data_keys = 
			sort { $refItemViews->{$a}{'SeqId'} <=> $refItemViews->{$b}{'SeqId'} } keys %$refItemViews;
      my $TableName = '' ; 

		#debug print "doc_pub/lib/DocPub/Model/MariaDbHandler.pm sub doListFoldersAndDocsTitles \n" ; 
      foreach my $page_type ( @page_types ) {
			foreach my $key ( @sorted_data_keys ) {
				next if $refItemViews->{"$key"}->{'Type' } eq 'folder' ; 
				my $Name				= $refItemViews->{"$key"}->{'Name'} ; 
				$Name					= lc ( $Name ) ; 
				my $Description	= $refItemViews->{"$key"}->{'Description'} ; 
				my $do				= $refItemViews->{"$key"}->{'doGenerateLeftMenu'} ; 
				my $Type				= $refItemViews->{"$key"}->{'Type'} ; 
				my $TableName		= $refItemViews->{"$key"}->{'TableName'} ; 
				my $ItemViewId		= $refItemViews->{"$key"}->{'ItemViewId'} ; 
				my $BranchId		= $refItemViews->{"$key"}->{'BranchId'} ; 
				my $TableNameLC	= $refItemViews->{"$key"}->{'TableNameLC'} ; 
				my $Level 			= $refItemViews->{"$key"}->{'Level' } ; 
				my $folder_key		= $key*1000 ; 
				my $itm_ctn_id		= $refItemViews->{"$key"}->{'ItemControllerId' } ;
				
				next if $Level == 0 ; 
				next if $do 	!= 1 ; 

				my $link	 		= '/' . $page_type . '?db=' . $database ; 
				$link 			.= '&branch-id=' . $BranchId ; 
				$link 			.= '&item=' . $TableName ; 
				$link				.= '&order-by=SeqId&filter-by=Level&filter-value=0,1,2,3,4,5,6' ; 
				
				print "testing the following page : \"" . $Name . "\" \n" ; 
				$t->get_ok("$link")->status_is(200) ; 
			}
		}

done_testing();

# VersionHistory 
# ---------------------------------------------------------
# 1.0.1 -- 2015-07-25 21:18:29 -- added showroute test
# 1.0.0 -- 2015-07-25 21:18:29 -- orig 
