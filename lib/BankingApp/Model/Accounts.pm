package BankingApp::Model::Accounts;
use Mojo::Base -base, -signatures;

has 'sqlite';

sub create ($self, $user_id, $type) {
  my $db = $self->sqlite->db;

  # Retry loop to avoid account number collisions
  my $acc_num;
  my $attempts = 0;
  while ($attempts++ < 10) {
    my $candidate = sprintf("%010d", int(rand(9999999999)));
    my $existing = $db->select('accounts', ['id'], {account_number => $candidate})->hash;
    unless ($existing) {
      $acc_num = $candidate;
      last;
    }
  }
  die "Could not generate a unique account number after 10 attempts\n" unless $acc_num;

  return $db->insert('accounts', {
    user_id        => $user_id,
    account_number => $acc_num,
    account_type   => $type,
    balance        => 0.00
  })->last_insert_id;
}

sub get_all_for_user ($self, $user_id) {
  my $db = $self->sqlite->db;
  return $db->select('accounts', '*', {user_id => $user_id})->hashes->to_array;
}

sub get_by_id_and_user ($self, $account_id, $user_id) {
  my $db = $self->sqlite->db;
  return $db->select('accounts', '*', {id => $account_id, user_id => $user_id})->hash;
}

sub get_by_id ($self, $account_id) {
  my $db = $self->sqlite->db;
  return $db->select('accounts', '*', {id => $account_id})->hash;
}

sub delete ($self, $account_id) {
  my $db = $self->sqlite->db;
  return $db->delete('accounts', {id => $account_id})->rows;
}

1;
