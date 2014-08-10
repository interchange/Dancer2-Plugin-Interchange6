package TestApp;

use strict;
use warnings;

use Data::Dumper;
use Dancer2 ':syntax';
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Interchange6::Routes;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;

get '/' => sub {
    return 'Home page';
};

get '/login/denied' => sub {
    return 'Denied';
};

get '/private' => require_login sub {
    return 'Private page';
};

get '/sessionid' => sub {
    return session->id;
};

hook before_cart_display => sub {
    my $tokens = shift;

    $tokens->{cart} = join(
        ",",
        sort map {
            join( ':', $_->{sku}, $_->{name}, $_->{quantity}, $_->{price} )
        } @{ $tokens->{cart} }
    );
};

hook before_checkout_display => sub {
    my $tokens = shift;

    $tokens->{cart} = join(
        ",",
        sort map {
            join( ':', $_->{sku}, $_->{name}, $_->{quantity}, $_->{price} )
        } @{ $tokens->{cart} }
    );
};

hook before_product_display => sub {
    my $tokens = shift;

    $tokens->{name} = $tokens->{product}->name;
};

hook before_navigation_display => sub {
    my $tokens = shift;

    $tokens->{name} = $tokens->{navigation}->name;
    $tokens->{products} =
      join( ",", sort map { $_->name } @{ $tokens->{products} } );
};

hook before_template_display => sub {
    my $tokens = shift;



};

shop_setup_routes;

1;
