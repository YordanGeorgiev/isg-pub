use Mojolicious;
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Data::Printer ; 

use lib '../lib' ; 


my $t = Test::Mojo->new('DocPub');
my $app = $t->app;

print 'START === testing the home page ' . "\n" ; 
my $url = '/view?db=isg_pub_en&branch-id=2&item=Home&order-by=SeqId&filter-by=Level&filter-value=0,1,2,3,4,5,6' ; 

$t->get_ok("$url")->status_is(200)->content_like(qr/HELLO WORLD/i);
print 'STOP  === testing the home page ' . "\n" ; 


done_testing();

# VersionHistory 
# ---------------------------------------------------------
# 1.0.1 -- 2015-07-25 21:18:29 -- added showroute test
# 1.0.0 -- 2015-07-25 21:18:29 -- orig 
