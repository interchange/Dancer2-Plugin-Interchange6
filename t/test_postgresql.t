use strict;
use warnings;

use Test::More;
use Class::Load qw/try_load_class/;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'postgresql';

    try_load_class('DateTime::Format::Pg')
      or plan skip_all => "DateTime::Format::Pg required to run these tests";

    try_load_class('DBD::Pg')
      or plan skip_all => "DBD::Pg required to run these tests";

    try_load_class('Test::PostgreSQL')
      or plan skip_all => "Test::PostgreSQL required to run these tests";
}

use lib 't/lib';
use TestApp;
use Test::Deploy;

use Dancer2 appname => 'TestApp';
use File::Temp;

my $tempdir = File::Temp::tempdir(
    CLEANUP  => 1,
    TEMPLATE => 'ic6s_test_XXXXX',
    TMPDIR   => 1,
);

no warnings 'once';    # prevent: "Test::PostgreSQL::errstr" used only once
my $pgsql = Test::PostgreSQL->new(
    base_dir => $tempdir,
) or plan skip_all => "Test::PostgreSQL died: " . $Test::PostgreSQL::errstr;
use warnings 'once';

my $dsn = $pgsql->dsn( dbname => 'test' );

Test::Deploy::deploy($dsn);
Test::Cart::run_tests();
Test::DSL::run_tests();
Test::Routes::run_tests();

done_testing;
