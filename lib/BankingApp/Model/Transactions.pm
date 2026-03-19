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
  
  my $acc = $db->select('accounts', ['balance'], {id => $account_id})->hash;
  if (!$acc || $acc->{balance} < $amount) {
    return undef;
  }
  
  $db->query('UPDATE accounts SET balance = balance - ? WHERE id = ?', $amount, $account_id);
  
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
  
  my $acc = $db->select('accounts', ['balance'], {id => $from_account_id})->hash;
  if (!$acc || $acc->{balance} < $amount) {
    return undef;
  }
  
  $db->query('UPDATE accounts SET balance = balance - ? WHERE id = ?', $amount, $from_account_id);
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
