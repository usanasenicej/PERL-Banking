package BankingApp::Controller::Transaction;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub deposit ($self) {
  my $user_id = $self->stash('user_id');
  my $req = $self->req->json;
  
  my $acc_id = $req->{account_id};
  my $amount = $req->{amount};
  
  if (!$acc_id || !$amount || $amount <= 0) {
    return $self->render(json => { error => 'Invalid deposit parameters' }, status => 400);
  }

  my $acc = $self->accounts->get_by_id_and_user($acc_id, $user_id);
  if (!$acc) {
    return $self->render(json => { error => 'Invalid account' }, status => 403);
  }

  my $tx_id = $self->transactions->deposit($acc_id, $amount);
  $self->render(json => { message => 'Deposit successful', transaction_id => $tx_id });
}

sub withdraw ($self) {
  my $user_id = $self->stash('user_id');
  my $req = $self->req->json;
  
  my $acc_id = $req->{account_id};
  my $amount = $req->{amount};
  
  if (!$acc_id || !$amount || $amount <= 0) {
    return $self->render(json => { error => 'Invalid withdraw parameters' }, status => 400);
  }

  my $acc = $self->accounts->get_by_id_and_user($acc_id, $user_id);
  if (!$acc) {
    return $self->render(json => { error => 'Invalid account' }, status => 403);
  }

  my $tx_id = $self->transactions->withdraw($acc_id, $amount);
  if ($tx_id) {
    $self->render(json => { message => 'Withdrawal successful', transaction_id => $tx_id });
  } else {
    $self->render(json => { error => 'Insufficient funds' }, status => 400);
  }
}

sub transfer ($self) {
  my $user_id = $self->stash('user_id');
  my $req = $self->req->json;
  
  my $from_id = $req->{from_account_id};
  my $to_id = $req->{to_account_id};
  my $amount = $req->{amount};
  
  if (!$from_id || !$to_id || !$amount || $amount <= 0) {
    return $self->render(json => { error => 'Invalid transfer parameters' }, status => 400);
  }

  if ($from_id eq $to_id) {
    return $self->render(json => { error => 'Cannot transfer to identical account' }, status => 400);
  }

  my $acc = $self->accounts->get_by_id_and_user($from_id, $user_id);
  if (!$acc) {
    return $self->render(json => { error => 'Invalid source account' }, status => 403);
  }
  
  my $dest_acc = $self->accounts->get_by_id($to_id);
  if (!$dest_acc) {
    return $self->render(json => { error => 'Invalid destination account' }, status => 404);
  }

  my $tx_id = $self->transactions->transfer($from_id, $to_id, $amount);
  if ($tx_id) {
    $self->render(json => { message => 'Transfer successful', transaction_id => $tx_id });
  } else {
    $self->render(json => { error => 'Insufficient funds' }, status => 400);
  }
}

sub history ($self) {
  my $user_id = $self->stash('user_id');
  my $acc_id = $self->param('account_id');
  
  my $acc = $self->accounts->get_by_id_and_user($acc_id, $user_id);
  if (!$acc) {
    return $self->render(json => { error => 'Account not found or access denied' }, status => 404);
  }

  my $history = $self->transactions->history($acc_id);
  $self->render(json => { transactions => $history });
}

1;
