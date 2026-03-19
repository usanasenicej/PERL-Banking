package BankingApp::Controller::Account;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub list_accounts ($self) {
  my $user_id = $self->stash('user_id');
  my $accounts = $self->accounts->get_all_for_user($user_id);
  
  $self->render(json => { accounts => $accounts });
}

sub create_account ($self) {
  my $user_id = $self->stash('user_id');
  my $type = $self->req->json->{account_type} // 'checking';
  
  if ($type ne 'checking' && $type ne 'savings') {
    return $self->render(json => { error => "Invalid account_type. Must be 'checking' or 'savings'" }, status => 400);
  }

  my $acc_id = $self->accounts->create($user_id, $type);
  $self->render(json => { message => 'Account created successfully', account_id => $acc_id }, status => 201);
}

sub get_account ($self) {
  my $user_id = $self->stash('user_id');
  my $acc_id = $self->param('account_id');
  
  my $acc = $self->accounts->get_by_id_and_user($acc_id, $user_id);
  if ($acc) {
    $self->render(json => $acc);
  } else {
    $self->render(json => { error => 'Account not found or access denied' }, status => 404);
  }
}

1;
