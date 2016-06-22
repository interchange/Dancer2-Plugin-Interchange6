package Dancer2::Plugin::Interchange6::API;

=head1 NAME

Dancer2::Plugin::Interchange6::API - api routes for Interchange6

=cut

use warnings;
use strict;
use Dancer2::Core::Types qw/Dancer2Prefix Str/;
use Dancer2::Plugin;

# config attributes

has prefix => (
    is          => 'ro',
    isa         => Dancer2Prefix,
    from_config => sub { '/api' },
);

has serializer => (
    is          => 'ro',
    isa         => Str,
    from_config => sub { 'JSON' },
);

my $cart_sub = sub {
    my $app = shift;
    my $plugin = $app->with_plugin(__PACKAGE__);

    # do some stuff

    $app->send_as( $plugin->serializer, {} );
};

my $navigation_sub = sub {
    my $app = shift;
    my $plugin = $app->with_plugin(__PACKAGE__);

    # do some stuff

    $app->send_as( $plugin->serializer, {} );
};

my $product_sub = sub {
    my $app = shift;
    my $plugin = $app->with_plugin(__PACKAGE__);
    my $sku = $app->request->route_parameters->get('sku');

    # do some stuff

    my $data = { sku => $sku };

    $app->send_as( $plugin->serializer, $data );
};

sub BUILD {
    my $plugin = shift;

    $plugin->app->add_route(
        method => 'get',
        regexp => $plugin->prefix . '/cart',
        code   => $cart_sub,
    );

    $plugin->app->add_route(
        method => 'get',
        regexp => qr{$plugin->prefix/navigation/(?<path>.+)},
        code   => $navigation_sub,
    );

    $plugin->app->add_route(
        method => 'get',
        regexp => $plugin->prefix . '/product/:sku',
        code   => $product_sub,
    );

}

1;
