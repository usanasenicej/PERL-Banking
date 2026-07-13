package BankingApp::Model::Transactions;
use Mojo::Base -base, -signatures;

has 'sqlite';

sub deposit ($self, $account_id, $amount) {
  my $db = $self->sqlite->db;
  my $tx = $db->begin;
  
  $db->query('UPDATE accounts SET balance = balance + ? WHERE id = ?', $amount, $account_id);
  
  my $tx_id = $db->insert('transactions', {
    to_account_id => $account_id,
    amount => $amount,
    transaction_type => 'deposit'
  })->last_insert_id;
  
  $tx->commit;
  return $tx_id;
}

sub withdraw ($self, $account_id, $amount) {
  my $db = $self->sqlite->db;
  my $tx = $db->begin;
  
  my $res = $db->query('UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?', $amount, $account_id, $amount);
  
  if ($res->rows == 0) {
    return undef;
  }
  
  my $tx_id = $db->insert('transactions', {
    from_account_id => $account_id,
    amount => $amount,
    transaction_type => 'withdrawal'
  })->last_insert_id;
  
  $tx->commit;
  return $tx_id;
}

sub transfer ($self, $from_account_id, $to_account_id, $amount) {
  my $db = $self->sqlite->db;
  my $tx = $db->begin;
  
  my $fee = 1.00;
  my $total_deduction = $amount + $fee;
  
  my $res = $db->query('UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?', $total_deduction, $from_account_id, $total_deduction);
  if ($res->rows == 0) {
    return undef;
  }
  
  $db->query('UPDATE accounts SET balance = balance + ? WHERE id = ?', $amount, $to_account_id);
  
  my $tx_id = $db->insert('transactions', {
    from_account_id => $from_account_id,
    to_account_id => $to_account_id,
    amount => $amount,
    transaction_type => 'transfer'
  })->last_insert_id;
  
  $tx->commit;
  return $tx_id;
}

sub history ($self, $account_id) {
  my $db = $self->sqlite->db;
  return $db->query('
    SELECT * FROM transactions 
    WHERE from_account_id = ? OR to_account_id = ? 
    ORDER BY created_at DESC', 
    $account_id, $account_id
  )->hashes->to_array;
}

1;
