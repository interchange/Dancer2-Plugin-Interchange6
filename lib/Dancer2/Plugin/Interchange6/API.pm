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

# plugins we use

has plugin_interchange6 => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->app->with_plugin('Dancer2::Plugin::Interchange6');
    },
    handles => [
        'shop_address',    'shop_attribute',
        'shop_cart',       'shop_charge',
        'shop_country',    'shop_message',
        'shop_navigation', 'shop_order',
        'shop_product',    'shop_redirect',
        'shop_schema',     'shop_state',
        'shop_user',
    ],
);

my $cart_sub = sub {
    my $app    = shift;
    my $plugin = $app->with_plugin(__PACKAGE__);

    # do some stuff

    $app->send_as( $plugin->serializer, {} );
};

my $navigation_sub = sub {
    my $app    = shift;
    my $plugin = $app->with_plugin(__PACKAGE__);

    # do some stuff

    $app->send_as( $plugin->serializer, {} );
};

my $product_sub = sub {
    my $app    = shift;
    my $plugin = $app->with_plugin(__PACKAGE__);
    my $sku    = $app->request->route_parameters->get('sku');

    my $product =
      $plugin->shop_product->with_lowest_selling_price->with_quantity_in_stock
      ->with_variant_count->with_average_rating->hri->find( { sku => $sku } );

    $app->send_error( "Not Found", 404 ) unless $product;

    my $data = { sku => $sku };

    $app->send_as( $plugin->serializer, $product );
};

sub BUILD {
    my $plugin = shift;

    $plugin->app->add_route(
        method => 'get',
        regexp => $plugin->prefix . '/cart',
        code   => $cart_sub,
    );

    foreach my $method (qw/get post/) {
        $plugin->app->add_route(
            method => $method,
            regexp => $plugin->prefix . '/cart/add/:sku',
            code   => $cart_sub,
        );
    }

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
