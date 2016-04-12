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
use File::Temp;
use Module::Find;
use TestApp;
use Deploy;

use Dancer2 appname => 'TestApp';

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

Deploy::deploy($dsn);

my @test_classes;
if ( $ENV{TEST_CLASS_ONLY} ) {
    push @test_classes, map { "Test::$_" } split( /,/, $ENV{TEST_CLASS_ONLY} );
}
else {
    my @old_inc = @INC;
    setmoduledirs('t/lib');
    @test_classes = sort { $a cmp $b } findsubmod Test;
    setmoduledirs(@old_inc);
}
foreach my $class (@test_classes) {
    eval "use $class";
    $class->run_tests();
}

done_testing;
