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
use File::Temp;
use File::Temp;
use TestApp;
use Deploy;

use Dancer2 appname => 'TestApp';

my $tempdir = File::Temp::tempdir(
    CLEANUP  => 1,
    TEMPLATE => 'ic6s_test_XXXXX',
    TMPDIR   => 1,
);

no warnings 'once';    # prevent: "Test::PostgreSQL::errstr" used only once
my $pgsql = Test::PostgreSQL->new( base_dir => $tempdir, )
  or plan skip_all => "Test::PostgreSQL died: " . $Test::PostgreSQL::errstr;
use warnings 'once';

my $dsn = $pgsql->dsn( dbname => 'test' );

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
