use strict;
use warnings;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'sqlite';
}

use Test::More;

use lib 't/lib';
use TestApp;
use Test::Deploy;

use Dancer2 appname => 'TestApp';
use File::Temp;

my $tempfile = File::Temp->new(
    TEMPLATE => 'ic6s_test_XXXXX',
    EXLOCK   => 0,
    TMPDIR   => 1,
);
my $dbfile = $tempfile->filename;
my $dsn = "dbi:SQLite:dbname=$dbfile";

Test::Deploy::deploy($dsn);
Test::Cart::run_tests();
Test::DSL::run_tests();
Test::Routes::run_tests();

done_testing;
