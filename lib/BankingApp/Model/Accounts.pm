package BankingApp::Model::Accounts;
use Mojo::Base -base, -signatures;

has 'sqlite';

sub create ($self, $user_id, $type) {
  my $db = $self->sqlite->db;
  my $acc_num = sprintf("%010d", int(rand(9999999999)));
  
  return $db->insert('accounts', {
    user_id => $user_id,
    account_number => $acc_num,
    account_type => $type,
    balance => 0.00
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

1;
