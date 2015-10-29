package TestApp;

use strict;
use warnings;

use Data::Dumper;

BEGIN {
    use Dancer2;
    set views => "t/routes/views";
    set log => 'info';

set plugins => {
    'Auth::Extensible' => {
        realms => {
            users => {
                provider => 'DBIC',
            }
        }
    },
    'DBIC' => {
        default => {
            dsn          => "DBI:SQLite:" . ${main::filename},
            schema_class => 'Interchange6::Schema',
        }
    },
    };
}

use Interchange6::Schema;
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Interchange6::Routes;
use Dancer2::Plugin::Interchange6::Routes::Cart;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;

my $schema;
my $filename;

( undef, $filename ) = File::Temp::tempfile;

package TestApp;
    
my ( $resp, $sessionid, %form, $logs );

set appdir => File::Spec->catdir( 't', 'routes' );

set plugins => {
    DBIC => {
        default => {
            dsn          => "DBI:SQLite:" . $filename,
            schema_class => 'Interchange6::Schema',
        }
    },
};


# we need to deploy our schema

my $schema_class = 'Interchange6::Schema';

$schema =
  $schema_class->connect( "DBI:SQLite:$filename", '', '',
    { sqlite_unicode => 1 } )
  or die "failed to connect to DBI:SQLite:$filename ($schema_class)";

$schema->deploy( { add_drop_table => 1 } );

# now add some db content

shop_product->create(
    {
        sku               => 'BAN001',
        name              => 'bananas',
        price             => 5.34,
        uri               => 'kilo-of-bananas',
        short_description => 'Fresh bananas from Colombia',
        description       => 'The best bananas money can buy',
        active            => 1,
    }
);
shop_product->create(
    {
        sku               => 'ORA001',
        name              => 'oranges',
        price             => 6.45,
        uri               => 'kilo-of-oranges',
        short_description => 'California oranges',
        description       => 'Organic California navel oranges',
        active            => 1,
    }
);
shop_product->create(
    {
        sku               => 'CAR002',
        name              => 'carrots',
        price             => 3.23,
        uri               => 'kilo-of-carrots',
        short_description => 'Local carrots',
        description       => 'Carrots from our local organic farm',
        active            => 1,
    }
);
shop_product->create(
    {
        sku               => 'POT002',
        name              => 'potatoes',
        price             => 10.15,
        uri               => 'kilo-of-potatoes',
        short_description => 'Maltese potatoes',
        description       => 'The best new potatoes in the world',
        active            => 1,
    }
);

my $nav_fruit = shop_navigation->create(
    {
        uri       => 'fruit',
        type      => 'nav',
        scope     => 'main-menu',
        name      => 'Fruit',
        parent_id => 0,
        active    => 1,
    }
);
my $nav_veg = shop_navigation->create(
    {
        uri       => 'vegetables',
        type      => 'nav',
        scope     => 'main-menu',
        name      => 'Vegetables',
        parent_id => 0,
        active    => 1,
    }
);

$schema->resultset('NavigationProduct')
  ->create( { sku => 'BAN001', navigation_id => $nav_fruit->navigation_id } );
$schema->resultset('NavigationProduct')
  ->create( { sku => 'ORA001', navigation_id => $nav_fruit->navigation_id } );
$schema->resultset('NavigationProduct')
  ->create( { sku => 'CAR002', navigation_id => $nav_veg->navigation_id } );
$schema->resultset('NavigationProduct')
  ->create( { sku => 'POT002', navigation_id => $nav_veg->navigation_id } );

shop_user->create(
    {
        username => 'testuser',
        email    => 'user@example.com',
        password => 'mypassword'
    }
);

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

# hook 'plugin.interchange6_routes_cart.before_cart_display' => sub {
#      my $tokens = shift;

#      $tokens->{cart} = join(
#          ",",
#          sort map {
#              join( ':', $_->{sku}, $_->{name}, $_->{quantity}, $_->{price} )
#          } @{ $tokens->{cart} }
#      );
# };

hook 'plugin.interchange6_routes_cart.before_checkout_display' => sub {
    my $tokens = shift;

    $tokens->{cart} = join(
        ",",
        sort map {
            join( ':', $_->{sku}, $_->{name}, $_->{quantity}, $_->{price} )
        } @{ $tokens->{cart} }
    );
};

hook 'plugin.interchange6_routes.before_product_display' => sub {
    my $tokens = shift;

    $tokens->{name} = $tokens->{product}->name;
};

hook 'plugin.interchange6_routes.before_navigation_display' => sub {
    my $tokens = shift;

    $tokens->{name} = $tokens->{navigation}->name;
    $tokens->{products} =
      join( ",", sort map { $_->name } @{ $tokens->{products} } );
};

hook 'plugin.interchange6_routes.before_template_display' => sub {
    my $tokens = shift;


};

shop_setup_routes;

1;
