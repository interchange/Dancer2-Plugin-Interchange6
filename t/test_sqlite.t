#!perl

use strict;
use warnings;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'sqlite';
}

use Test::More;
use Test::WWW::Mechanize::PSGI;

use lib 't/lib';
use TestApp;
use Test::Cart;
use Test::DSL;
use Test::Routes;

use Dancer2 appname => 'TestApp';
use Dancer2::Plugin::DBIC;
use File::Temp;

my $tempfile = File::Temp->new(
    TEMPLATE => 'ic6s_test_XXXXX',
    EXLOCK   => 0,
    TMPDIR   => 1,
);
my $dbfile = $tempfile->filename;
my $dsn = "dbi:SQLite:dbname=$dbfile";
my $config = config;
$config->{plugins}->{DBIC}->{default}->{dsn} = $dsn;
$config->{plugins}->{DBIC}->{shop2}->{dsn} = $dsn;

schema->deploy;
my $fixtures = Fixtures->new( ic6s_schema => schema );
$fixtures->load_all_fixtures;

my $mech = Test::WWW::Mechanize::PSGI->new( app => TestApp->to_app );
my $trap = dancer_app->logger_engine->trapper;

$mech->get_ok( '/logout', "make sure we're logged out" );

$mech->get_ok( '/ergo-roller', "GET /ergo-roller (product route via uri)" )
  or diag explain $trap->read;

#Test::DSL::run_tests();
#Test::Cart::run_tests();
Test::Routes::run_tests();

done_testing;
