package BankingApp::Model::Loans;
use Mojo::Base -base, -signatures;

has 'sqlite';

sub apply_for_loan ($self, $user_id, $amount) {
  my $db = $self->sqlite->db;
  
  # The global flat bank interest rate is set at 5.5%
  my $interest_rate = 5.50; 
  
  return $db->insert('loans', {
    user_id => $user_id,
    amount => $amount,
    interest_rate => $interest_rate,
    status => 'pending'
  })->last_insert_id;
}

sub get_all_for_user ($self, $user_id) {
  my $db = $self->sqlite->db;
  return $db->select('loans', '*', {user_id => $user_id})->hashes->to_array;
}

1;
