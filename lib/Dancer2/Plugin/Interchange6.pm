package Dancer2::Plugin::Interchange6;

use strict;
use warnings;

use Dancer2::Plugin;

#use Dancer2 qw(:syntax !before !after);
use Dancer2::Plugin::DBIC;
#use Dancer2::Plugin::Auth::Extensible;

use Dancer2::Plugin::Interchange6::Cart;
#use Dancer2::Plugin::Interchange6::Business::OnlinePayment;

=head1 NAME

Dancer2::Plugin::Interchange6 - Interchange6 Shop Plugin for Dancer2

=head1 VERSION

Version 0.040

=cut

our $VERSION = '0.040';

=head1 REQUIREMENTS

All Interchange6 Dancer2 applications need to use the L<Dancer2::Session::DBIC>
engine.

The easiest way to configure this is in your main module, just after all
the C<use> statements:

   set session => 'DBIC';
   set session_options => {schema => schema};

=head1 ROUTES

You can use the L<Dancer2::Plugin::Interchange6::Routes> plugin bundled with this
plugin to setup standard routes for:

=over 4

=item product listing

=item product display

=item cart display

=item checkout form

=back

To enable these routes, you put the C<shop_setup_routes> keyword at the end
of your main module:

    package MyShop;

    use Dancer2 ':syntax';
    use Dancer2::Plugin::Interchange6;
    use Dancer2::Plugin::Interchange6::Routes;

    get '/shop' => sub {
        ...
    };

    ...

    shop_setup_routes;

    true;

Please refer to L<Dancer2::Plugin::Interchange6::Routes> for configuration options
and further information.

=head1 HOOKS

This plugin installs the following hooks:

=head2 Add to cart

The functions registered for these hooks receive the cart object
and the item to be added as parameters.

=over 4

=item before_cart_add_validate

Triggered before item is validated for adding to the cart.

=item before_cart_add

Triggered before item is added to the cart.

=item after_cart_add

Triggered after item is added to the cart.
Used by DBI backend to save item to the database.

=back

=head2 Update cart

The functions registered for these hooks receive the cart object,
the current item in the cart and the updated item.

=over 4

=item before_cart_update

Triggered before cart item is updated (changing quantity).

=item after_cart_update

Triggered after cart item is updated (changing quantity).
Used by DBI backend to update item to the database.

=back

=head2 Remove from cart

The functions registered for these hooks receive the cart object
and the item to be added as parameters.

=over 4

=item before_cart_remove_validate

Triggered before item is validated for removal.
Receives cart object and item SKU.

=item before_cart_remove

Triggered before item is removed from the cart.
Receives cart object and item.

=item after_cart_remove

Triggered after item is removed from the cart.
Used by DBI backend to delete item from the database.
Receives cart object and item.

=back

=head2 Clear cart

=over 4

=item before_cart_clear

Triggered before cart is cleared.

=item after_cart_clear

Triggered after cart is cleared.

=back

=head2 Rename cart

The functions registered for these hooks receive the cart object,
the old name and the new name.

=over 4

=item before_cart_rename

Triggered before cart is renamed.

=item after_cart_rename

Triggered after cart is renamed.

=item before_cart_set_users_id

Triggered before users_id is set for the cart.

=item after_cart_set_users_id

Triggered after users_id is set for the cart.

=item before_cart_set_sessions_id

Triggered before sessions_id is set for the cart.

=item after_cart_set_sessions_id

Triggered after sessions_id is set for the cart.

=back

=head1 EXPIRE DBIC SESSIONS

This command expires/manages DBIC sessions and carts.  NOTE: For proper
functionality please copy/link to Dancer2 App/bin directory.

    interchange6-expire-sessions

=cut

plugin_hooks (qw/before_cart_add_validate
                 before_cart_add after_cart_add
                 before_cart_update after_cart_update
                 before_cart_remove_validate
                 before_cart_remove after_cart_remove
                 before_cart_rename after_cart_rename
                 before_cart_clear after_cart_clear
                 before_cart_set_users_id after_cart_set_users_id
                 before_cart_set_sessions_id after_cart_set_sessions_id
                /);

plugin_keywords qw/shop_schema
                   shop_resultset
                   shop_address
                   shop_attribute
                   shop_country
                   shop_navigation
                   shop_order
                   shop_product
                   shop_review
                   shop_user
                   shop_cart
                   cart
                  /;

has dbic => (
    is => 'ro',
    lazy => 1,
    default => sub {
        # if the app already has the 'DBIC' plugin loaded, it'll return
        # it. If not, it'll load it in the app, and then return it.
        $_[0]->app->with_plugin( 'DBIC' )
    },
    handles => { 'schema' => 'schema',
                 'resultset' => 'resultset',
             },
);

has auth_extensible => (
    is => 'ro',
    lazy => 1,
    default => sub {
        # if the app already has the 'Auth::Extensible' plugin loaded, it'll return
        # it. If not, it'll load it in the app, and then return it.
        $_[0]->app->with_plugin( 'Auth::Extensible' )
    },
    handles => { 'logged_in_user' => 'logged_in_user' },
);

sub shop_schema {
    my $plugin = shift;
    $plugin->_shop_schema(@_);
};

sub shop_address {
    my $plugin = shift;
    $plugin->shop_resultset('Address', @_);
};

sub shop_attribute {
    my $plugin = shift;
    $plugin->shop_resultset('Attribute', @_);
};

sub shop_country {
    my $plugin = shift;
    $plugin->shop_resultset('Country', @_);
};

sub shop_navigation {
    my $plugin = shift;
    $plugin->shop_resultset('Navigation', @_);
};

sub shop_order {
    my $plugin = shift;
    $plugin->shop_resultset('Order', @_);
};

sub shop_product {
    my $plugin = shift;
    $plugin->shop_resultset('Product', @_);
};

sub shop_review {
    my $plugin = shift;
    $plugin->shop_resultset('Review', @_);
};

sub shop_user {
    my $plugin = shift;
    $plugin->shop_resultset('User', @_);
};

sub shop_charge {
	my ($self, %args) = @_;
	my ($schema, $bop_object, $payment_settings, $provider, $provider_settings);

	$payment_settings = $self->config->payment;

    # determine payment provider
    if (exists $args{provider} && $args{provider}) {
        $provider = $args{provider};
    }
    else {
        $provider = $payment_settings->{default_provider};
    }

    if (exists $payment_settings->{providers}->{$provider}) {
        $provider_settings = $payment_settings->{providers}->{$provider};
    }
    else {
        die "Settings for provider $provider missing.";
    }

    my %payment_data = (payment_mode => $provider,
                        status => 'request',
                        sessions_id => session->id,
                        payment_action => 'charge',
                        amount => $args{amount},
                        users_id => session('logged_in_user_id'),
                        );

    # create payment order
    $schema = _shop_schema();

    my $payment_order = $schema->resultset('PaymentOrder')->create(\%payment_data);

    # create BOP object wrapper with provider settings
	$bop_object = Dancer2::Plugin::Interchange6::Business::OnlinePayment->new($provider, %$provider_settings);

    $bop_object->payment_order($payment_order);

    # call charge method
    $self->log ( 'debug', "Charging with the following parameters: ", \%args );

    $bop_object->charge(%args);

    if ($bop_object->is_success) {
        $payment_order->update({
            status => 'success',
            auth_code => $bop_object->authorization,
        });
    }
    else {
        $payment_order->update({
            status => 'failure',
	    payment_error_code => $bop_object->error_code,
	    payment_error_message => $bop_object->error_message,
        });
    }

	return $bop_object;
};

sub cart {
    _shop_cart(@_);
}

sub shop_cart {
    _shop_cart(@_);
}

sub _shop_cart {
    my ($plugin, $app, %args, $user_ref);

    $plugin = shift;
    $app = $plugin->app;

    %args = (
        sessions_id => $app->session->id,
        execute_hook => sub {execute_hook(@_)},
    );

    # we have a cart name
    $args{name} = $_[0] if @_ == 1;

    if ($user_ref = $plugin->logged_in_user) {
        # user is logged in
        $args{users_id} = $user_ref->users_id;
    }

    return Dancer2::Plugin::Interchange6::Cart->new( %args );
};

sub _shop_schema {
    my $plugin = shift;
    my $schema_key;

    if (@_) {
        $schema_key = $_[0];
    }
    else {
        $schema_key = 'default';
    }

    return $plugin->schema($schema_key);
};

sub shop_resultset {
    my ($plugin, $name, $key) = @_;

    if (defined $key) {
        return $plugin->resultset($name)->find($key);
    }

    return $plugin->resultset($name);
};

=head1 ACKNOWLEDGEMENTS

The L<Dancer2> developers and community for their great application framework
and for their quick and competent support.

Peter Mottram for his patches.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Interchange6>, L<Interchange6::Schema>

=cut

1;
