# NAME

Dancer2::Plugin::Interchange6 - Interchange6 Shop Plugin for Dancer2

# VERSION

Version 0.202

# REQUIREMENTS

All Interchange6 Dancer2 applications need to use the [Dancer2::Session::DBIC](https://metacpan.org/pod/Dancer2::Session::DBIC)
engine.

The easiest way to configure this is in your `config.yml` (or whatever other
configuration file you prefer):

    plugins
      DBIC:
        default:
          schema_class: Interchange6::Schema
          # ... other DBIC plugin config here
    engines:
      session:
        DBIC:
          db_connection_name: default # connection name from DBIC plugin
    session: DBIC

# CONFIGURATION

Available configuration options:

    plugins:
      Interchange6:
        cart_class: MyApp::Cart
        carts_var_name: some_other_var

- cart\_class

    If you wish to subclass the cart you can have ["shop\_cart"](#shop_cart) return your
    subclassed cart instead. You set the cart class via `cart_class`.
    Defaults to [Dancer2::Plugin::Interchange6::Cart](https://metacpan.org/pod/Dancer2::Plugin::Interchange6::Cart).

- carts\_var\_name

    The plugin caches carts in a ["var" in Dancer2](https://metacpan.org/pod/Dancer2#var) and the name of the var used can
    be set via `carts_var_name`. Defaults to `ic6_carts`.

# ROUTES

You can use the [Dancer2::Plugin::Interchange6::Routes](https://metacpan.org/pod/Dancer2::Plugin::Interchange6::Routes) plugin bundled with this
plugin to setup standard routes for:

- product listing
- product display
- cart display
- checkout form

To enable these routes, you put the `shop_setup_routes` keyword at the end
of your main module:

    package MyShop;

    use Dancer2;
    use Dancer2::Plugin::Interchange6;
    use Dancer2::Plugin::Interchange6::Routes;

    get '/shop' => sub {
        ...
    };

    ...

    shop_setup_routes;

    true;

Please refer to [Dancer2::Plugin::Interchange6::Routes](https://metacpan.org/pod/Dancer2::Plugin::Interchange6::Routes) for configuration
options and further information.

# KEYWORDS

## shop\_cart

Returns [Dancer2::Plugin::Interchange6::Cart](https://metacpan.org/pod/Dancer2::Plugin::Interchange6::Cart) object.

## shop\_charge

Creates payment order and authorizes amount.

## shop\_redirect

Calls ["redirect" in Interchange6::Schema::ResultSet::UriRedirect](https://metacpan.org/pod/Interchange6::Schema::ResultSet::UriRedirect#redirect) with given args.

## shop\_schema

Returns [Interchange6::Schema](https://metacpan.org/pod/Interchange6::Schema) object.

## shop\_...

Accessors for [Interchange6::Schema](https://metacpan.org/pod/Interchange6::Schema) result classes. You can use it
to retrieve a single object or the corresponding result set.

    shop_product('F0001')->uri;

    shop_navigation->search({type => 'manufacturer',
                             active => 1});

Available accessors are:

- `shop_address`
- `shop_attribute`
- `shop_country`
- `shop_message`
- `shop_navigation`
- `shop_order`
- `shop_product`
- `shop_state`
- `shop_user`

# HOOKS

This plugin installs the following hooks:

## Add to cart

The functions registered for these hooks receive the cart object
and the item to be added as parameters.

- before\_cart\_add\_validate

    Triggered before item is validated for adding to the cart.

- before\_cart\_add

    Triggered before item is added to the cart.

- after\_cart\_add

    Triggered after item is added to the cart.
    Used by DBI backend to save item to the database.

## Update cart

The functions registered for these hooks receive the cart object,
the current item in the cart and the updated item.

- before\_cart\_update

    Triggered before cart item is updated (changing quantity).

- after\_cart\_update

    Triggered after cart item is updated (changing quantity).
    Used by DBI backend to update item to the database.

## Remove from cart

The functions registered for these hooks receive the cart object
and the item to be added as parameters.

- before\_cart\_remove\_validate

    Triggered before item is validated for removal.
    Receives cart object and item SKU.

- before\_cart\_remove

    Triggered before item is removed from the cart.
    Receives cart object and item.

- after\_cart\_remove

    Triggered after item is removed from the cart.
    Used by DBI backend to delete item from the database.
    Receives cart object and item.

## Clear cart

- before\_cart\_clear

    Triggered before cart is cleared.

- after\_cart\_clear

    Triggered after cart is cleared.

## Rename cart

The functions registered for these hooks receive the cart object,
the old name and the new name.

- before\_cart\_rename

    Triggered before cart is renamed.

- after\_cart\_rename

    Triggered after cart is renamed.

- before\_cart\_set\_users\_id

    Triggered before users\_id is set for the cart.

- after\_cart\_set\_users\_id

    Triggered after users\_id is set for the cart.

- before\_cart\_set\_sessions\_id

    Triggered before sessions\_id is set for the cart.

- after\_cart\_set\_sessions\_id

    Triggered after sessions\_id is set for the cart.

# EXPIRE DBIC SESSIONS

This command expires/manages DBIC sessions and carts.  NOTE: For proper
functionality please copy/link to Dancer2 App/bin directory.

    interchange6-expire-sessions

# ACKNOWLEDGEMENTS

The [Dancer2](https://metacpan.org/pod/Dancer2) developers and community for their great application framework
and for their quick and competent support.

Peter Mottram for his patches and conversion of this plugin to Dancer2.

# LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

# SEE ALSO

[Interchange6](https://metacpan.org/pod/Interchange6), [Interchange6::Schema](https://metacpan.org/pod/Interchange6::Schema)
