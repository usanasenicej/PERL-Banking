package BankingApp::Controller::Transaction;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw(true false);

use constant MAX_AMOUNT => 1_000_000;

# -------------------------------------------------------
# Private helpers
# -------------------------------------------------------

# Validates that an amount is a positive number with at most 2 decimal places
# and does not exceed the per-transaction maximum.
sub _valid_amount ($amount) {
  return 0 unless defined $amount && $amount =~ /^\d+(?:\.\d{1,2})?$/ && $amount > 0;
  return 0 if $amount > MAX_AMOUNT;
  return 1;
}

# Wraps a code block in eval, logs + returns 500 on unhandled exceptions.
# Returns the result of the block on success, or undef on error.
sub _try ($self, $code) {
  my $result = eval { $code->() };
  if ($@) {
    $self->app->log->error($@);
    $self->render(json => { success => false, error => 'Internal server error' }, status => 500);
    return undef;
  }
  return $result;
}

# -------------------------------------------------------
# Actions
# -------------------------------------------------------

sub deposit ($self) {
  my $user_id = $self->stash('user_id');
  my $req     = $self->req->json;

  my $acc_id = $req->{account_id};
  my $amount = $req->{amount};

  unless ($acc_id && _valid_amount($amount)) {
    return $self->render(json => { success => false, error => 'Invalid deposit parameters. Amount must be between 0.01 and 1,000,000 with up to 2 decimal places.' }, status => 400);
  }

  _try($self, sub {
    my $acc = $self->accounts->get_by_id_and_user($acc_id, $user_id);
    unless ($acc) {
      return $self->render(json => { success => false, error => 'Account not found or access denied' }, status => 403);
    }

    my $tx_id = $self->transactions->deposit($acc_id, $amount);
    $self->render(json => { success => true, message => 'Deposit successful', transaction_id => $tx_id });
  });
}

sub withdraw ($self) {
  my $user_id = $self->stash('user_id');
  my $req     = $self->req->json;

  my $acc_id = $req->{account_id};
  my $amount = $req->{amount};

  unless ($acc_id && _valid_amount($amount)) {
    return $self->render(json => { success => false, error => 'Invalid withdrawal parameters. Amount must be between 0.01 and 1,000,000 with up to 2 decimal places.' }, status => 400);
  }

  _try($self, sub {
    my $acc = $self->accounts->get_by_id_and_user($acc_id, $user_id);
    unless ($acc) {
      return $self->render(json => { success => false, error => 'Account not found or access denied' }, status => 403);
    }

    my $tx_id = $self->transactions->withdraw($acc_id, $amount);
    if ($tx_id) {
      $self->render(json => { success => true, message => 'Withdrawal successful', transaction_id => $tx_id });
    } else {
      $self->render(json => { success => false, error => 'Insufficient funds' }, status => 400);
    }
  });
}

sub transfer ($self) {
  my $user_id = $self->stash('user_id');
  my $req     = $self->req->json;

  my $from_id = $req->{from_account_id};
  my $to_id   = $req->{to_account_id};
  my $amount  = $req->{amount};

  unless ($from_id && $to_id && _valid_amount($amount)) {
    return $self->render(json => { success => false, error => 'Invalid transfer parameters. Amount must be between 0.01 and 1,000,000 with up to 2 decimal places.' }, status => 400);
  }

  if ($from_id == $to_id) {
    return $self->render(json => { success => false, error => 'Cannot transfer to the same account' }, status => 400);
  }

  _try($self, sub {
    my $acc = $self->accounts->get_by_id_and_user($from_id, $user_id);
    unless ($acc) {
      return $self->render(json => { success => false, error => 'Source account not found or access denied' }, status => 403);
    }

    my $dest_acc = $self->accounts->get_by_id($to_id);
    unless ($dest_acc) {
      return $self->render(json => { success => false, error => 'Destination account not found' }, status => 404);
    }

    my $tx_id = $self->transactions->transfer($from_id, $to_id, $amount);
    if ($tx_id) {
      $self->render(json => { success => true, message => 'Transfer successful (1.00 fee applied)', transaction_id => $tx_id });
    } else {
      $self->render(json => { success => false, error => 'Insufficient funds (remember: a $1.00 transfer fee applies)' }, status => 400);
    }
  });
}

sub history ($self) {
  my $user_id = $self->stash('user_id');
  my $acc_id  = $self->param('account_id');

  # Clamp pagination params in the controller before forwarding to the model
  my $page  = $self->param('page')  || 1;
  my $limit = $self->param('limit') || 20;
  $page  = 1  if $page  < 1;
  $limit = 20 if $limit < 1 || $limit > 100;

  unless (defined $acc_id && $acc_id =~ /^\d+$/) {
    return $self->render(json => { success => false, error => 'Invalid account ID' }, status => 400);
  }

  _try($self, sub {
    my $acc = $self->accounts->get_by_id_and_user($acc_id, $user_id);
    unless ($acc) {
      return $self->render(json => { success => false, error => 'Account not found or access denied' }, status => 404);
    }

    my $result = $self->transactions->history($acc_id, $page, $limit);
    $self->render(json => { success => true, %$result });
  });
}

# GET /accounts/:account_id/summary
sub summary ($self) {
  my $user_id = $self->stash('user_id');
  my $acc_id  = $self->param('account_id');

  unless (defined $acc_id && $acc_id =~ /^\d+$/) {
    return $self->render(json => { success => false, error => 'Invalid account ID' }, status => 400);
  }

  _try($self, sub {
    my $acc = $self->accounts->get_by_id_and_user($acc_id, $user_id);
    unless ($acc) {
      return $self->render(json => { success => false, error => 'Account not found or access denied' }, status => 404);
    }

    my $stats = $self->transactions->summary($acc_id);
    $self->render(json => {
      success    => true,
      account_id => $acc_id + 0,
      balance    => $acc->{balance} + 0,
      %$stats
    });
  });
}

1;
