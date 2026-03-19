package BankingApp::Model::Users;
use Mojo::Base -base, -signatures;

has 'sqlite';

sub add ($self, $username, $password_hash, $email) {
  my $db = $self->sqlite->db;
  return eval {
    $db->insert('users', {
      username => $username,
      password_hash => $password_hash,
      email => $email
    })->last_insert_id;
  } || undef;
}

sub verify ($self, $username) {
  my $db = $self->sqlite->db;
  return $db->select('users', ['id', 'password_hash'], {username => $username})->hash;
}

sub get_by_id ($self, $user_id) {
  my $db = $self->sqlite->db;
  return $db->select('users', ['id', 'username', 'email', 'created_at'], {id => $user_id})->hash;
}

1;
