package Dancer2::Plugin::Interchange6::Routes::Account;

use strict;
use warnings;

use Moo;
use Dancer2::Plugin2;
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Auth::Extensible;

=head1 NAME

Dancer2::Plugin::Interchange6::Routes::Account - Account routes for Interchange6 Shop Machine

=head1 DESCRIPTION

The Interchange6 account routes module installs Dancer2 routes for
login and logout

=cut

#register_hook 'before_login_display';

has auth_extensible => (
    is => 'ro',
    lazy => 1,
    default => sub {
        # if the app already has the 'DBIC' plugin loaded, it'll return
        # it. If not, it'll load it in the app, and then return it.
        $_[0]->app->with_plugin( 'Auth::Extensible' )
    },
    handles => { 'logged_in_user' => 'logged_in_user' },
);

has shop => (
    is => 'ro',
    lazy => 1,
    default => sub {
        # if the app already has the 'Interchange6' plugin loaded, it'll return
        # it. If not, it'll load it in the app, and then return it.
        $_[0]->app->with_plugin( 'Interchange6' )
    },
    handles => { 'shop_cart' => 'shop_cart' },
);

=head1 FUNCTIONS

=head2 account_routes

Returns the account routes based on the passed routes configuration.

=cut

sub account_routes {
    my ($plugin, $routes_config) = @_;
    my %routes;

    $routes{login}->{get} = sub {
        my $app = shift;
        my $auth_extensible;
        
        return $app->redirect('/') if $plugin->logged_in_user;

        my %values;

        if ( $app->request->vars->{login_failed} ) {
            $values{error} = "Login failed";
        }

        # record return_url in template tokens
        if (my $return_url = $app->request->param('return_url')) {
            $values{return_url} = $return_url;
        }

        # call before_login_display route so template tokens
        # can be injected
        execute_hook('before_login_display', \%values);

        # record return_url in the session to reuse it in post route
        $app->session->write( return_url => $values{return_url} );

        template $routes_config->{account}->{login}->{template}, \%values;
    };

    $routes{login}->{post} = sub {
        my $app = shift;

        return $app->redirect('/') if $plugin->auth_extensible->logged_in_user;

        my $login_route = '/' . $routes_config->{account}->{login}->{uri};

        my $user = $plugin->shop->shop_user->find({
            username => $app->request->params->{username}
        });

        my ($success, $realm, $current_cart);

        if ($user) {
            # remember current cart object
            $current_cart = $app->shop_cart;

            ($success, $realm) = authenticate_user(
                $app->request->params->{username},
                $app->request->params->{password}
            );
        }

        if ($success) {
            $app->session->write(logged_in_user => $user->username);
            $app->session->write(logged_in_user_id => $user->id);
            $app->session->write(logged_in_user_realm => $realm);

            if (! $current_cart->users_id) {
                $current_cart->users_id($user->id);
            }

            # now pull back in old cart items from previous authenticated
            # sessions were sessions_id is undef in db cart
            $current_cart->load_saved_products;

            if ( $app->session->read('return_url') ) {
                my $url = $app->session->read('return_url');
                $app->session->delete('return_url');
                return $app->redirect($url);
            }
            else {
                return $app->redirect(
                    '/' . $routes_config->{account}->{login}->{success_uri});
            }
        } else {
            $app->log('debug', 'Authentication failed for ',
                      $app->request->params->{username}
                  );

            $app->request->var(login_failed => 1);

            return $app->forward( $login_route, {
                return_url => $app->request->params->{return_url}
            }, { method => 'get' }
            );
        }
    };

    $routes{logout}->{any} = sub {
        my $app = shift;
        my $cart = $app->shop_cart;
        if ( $cart->count > 0 ) {
            # save our items for next login
            shop_cart->sessions_id(undef);
        }
        # any empty cart with sessions_id matching our session id will be
        # destroyed here
        $app->session->destroy;
        return $app->redirect('/');
    };

    return \%routes;
}

1;
