use strict;
use warnings;

use Test::More;
use Class::Load qw/try_load_class/;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'mysql';

    try_load_class('DateTime::Format::MySQL')
      or plan skip_all => "DateTime::Format::MySQL required to run these tests";

    try_load_class('DBD::mysql')
      or plan skip_all => "DBD::mysql required to run these tests";

    try_load_class('Test::mysqld')
      or plan skip_all => "Test::mysqld required to run these tests";
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

no warnings 'once';    # prevent: "Test::mysqld::errstr" used only once
my $mysqld = Test::mysqld->new(
    base_dir => $tempdir,
    my_cnf   => {
        'character-set-server' => 'utf8',
        'collation-server'     => 'utf8_unicode_ci',
        'skip-networking'      => '',
    }
) or plan skip_all => "Test::mysqld died: " . $Test::mysqld::errstr;
use warnings 'once';

my $dsn = $mysqld->dsn( dbname => 'test' );

Test::Deploy::deploy($dsn);
Test::Cart::run_tests();
Test::DSL::run_tests();
Test::Routes::run_tests();

done_testing;
