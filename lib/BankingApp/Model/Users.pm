package BankingApp::Model::Users;
use Mojo::Base -base, -signatures;

has 'sqlite';

sub add ($self, $username, $password_hash, $email) {
  my $db = $self->sqlite->db;
  return eval {
    $db->insert('users', {
      username      => $username,
      password_hash => $password_hash,
      email         => $email
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

# Change 4: Update email for a given user
sub update_email ($self, $user_id, $new_email) {
  my $db = $self->sqlite->db;
  return $db->update('users', { email => $new_email }, { id => $user_id })->rows;
}

# Change 4: Update password hash for a given user
sub update_password ($self, $user_id, $new_hash) {
  my $db = $self->sqlite->db;
  return $db->update('users', { password_hash => $new_hash }, { id => $user_id })->rows;
}

1;
