package BankingApp::Controller::Account;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# GET /accounts
sub list_accounts ($self) {
    my $user_id = $self->stash('user_id');

    eval {
        my $accounts = $self->accounts->get_all_for_user($user_id);

        return $self->render(
            status => 200,
            json   => {
                success => Mojo::JSON->true,
                accounts => $accounts
            }
        );
    };

    return _server_error($self, $@) if $@;
}

# POST /accounts
sub create_account ($self) {
    my $user_id = $self->stash('user_id');

    my $payload = $self->req->json || {};

    my $type = lc($payload->{account_type} // 'checking');

    unless ($type =~ /^(checking|savings)$/) {
        return $self->render(
            status => 400,
            json   => {
                success => Mojo::JSON->false,
                error   => "account_type must be 'checking' or 'savings'"
            }
        );
    }

    eval {
        my $account_id = $self->accounts->create(
            $user_id,
            $type
        );

        return $self->render(
            status => 201,
            json   => {
                success    => Mojo::JSON->true,
                message    => 'Account created successfully',
                account_id => $account_id
            }
        );
    };

    return _server_error($self, $@) if $@;
}

# GET /accounts/:account_id
sub get_account ($self) {
    my $user_id = $self->stash('user_id');
    my $acc_id  = $self->param('account_id');

    unless (defined $acc_id && $acc_id =~ /^\d+$/) {
        return $self->render(
            status => 400,
            json   => {
                success => Mojo::JSON->false,
                error   => 'Invalid account ID'
            }
        );
    }

    eval {
        my $account = $self->accounts
            ->get_by_id_and_user($acc_id, $user_id);

        unless ($account) {
            return $self->render(
                status => 404,
                json   => {
                    success => Mojo::JSON->false,
                    error   => 'Account not found'
                }
            );
        }

        return $self->render(
            status => 200,
            json   => {
                success => Mojo::JSON->true,
                account => $account
            }
        );
    };

    return _server_error($self, $@) if $@;
}

# ----------------------------------------------------
# Private helper
# ----------------------------------------------------
sub _server_error ($self, $error) {
    $self->app->log->error($error);

    return $self->render(
        status => 500,
        json   => {
            success => Mojo::JSON->false,
            error   => 'Internal server error'
        }
    );
}

1;