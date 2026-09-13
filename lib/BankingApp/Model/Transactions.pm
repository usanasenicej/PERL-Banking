package BankingApp::Model::Transactions;
use Mojo::Base -base, -signatures;

has 'sqlite';

sub deposit ($self, $account_id, $amount) {
  my $db = $self->sqlite->db;
  my $tx = $db->begin;

  $db->query('UPDATE accounts SET balance = balance + ? WHERE id = ?', $amount, $account_id);

  my $tx_id = $db->insert('transactions', {
    to_account_id    => $account_id,
    amount           => $amount,
    transaction_type => 'deposit'
  })->last_insert_id;

  $tx->commit;
  return $tx_id;
}

sub withdraw ($self, $account_id, $amount) {
  my $db = $self->sqlite->db;
  my $tx = $db->begin;

  my $res = $db->query(
    'UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?',
    $amount, $account_id, $amount
  );

  if ($res->rows == 0) {
    # Explicitly roll back — no funds moved, no transaction recorded
    $tx->rollback;
    return undef;
  }

  my $tx_id = $db->insert('transactions', {
    from_account_id  => $account_id,
    amount           => $amount,
    transaction_type => 'withdrawal'
  })->last_insert_id;

  $tx->commit;
  return $tx_id;
}

sub transfer ($self, $from_account_id, $to_account_id, $amount) {
  my $db  = $self->sqlite->db;
  my $tx  = $db->begin;
  my $fee = 1.00;
  my $total_deduction = $amount + $fee;

  my $res = $db->query(
    'UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?',
    $total_deduction, $from_account_id, $total_deduction
  );
  if ($res->rows == 0) {
    $tx->rollback;
    return undef;
  }

  $db->query('UPDATE accounts SET balance = balance + ? WHERE id = ?', $amount, $to_account_id);

  my $tx_id = $db->insert('transactions', {
    from_account_id  => $from_account_id,
    to_account_id    => $to_account_id,
    amount           => $amount,
    transaction_type => 'transfer'
  })->last_insert_id;

  $tx->commit;
  return $tx_id;
}

sub history ($self, $account_id, $page = 1, $limit = 20) {
  my $db     = $self->sqlite->db;
  $page      = 1  if $page  < 1;
  $limit     = 20 if $limit < 1 || $limit > 100;
  my $offset = ($page - 1) * $limit;

  my $total = $db->query(
    'SELECT COUNT(*) AS cnt FROM transactions WHERE from_account_id = ? OR to_account_id = ?',
    $account_id, $account_id
  )->hash->{cnt};

  my $rows = $db->query(
    'SELECT * FROM transactions
     WHERE from_account_id = ? OR to_account_id = ?
     ORDER BY created_at DESC
     LIMIT ? OFFSET ?',
    $account_id, $account_id, $limit, $offset
  )->hashes->to_array;

  return { transactions => $rows, total => $total + 0, page => $page + 0, limit => $limit + 0 };
}

# Change 5: Account summary — total deposited and withdrawn
sub summary ($self, $account_id) {
  my $db = $self->sqlite->db;

  my $deposited = $db->query(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE to_account_id = ? AND transaction_type = 'deposit'",
    $account_id
  )->hash->{total};

  my $withdrawn = $db->query(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE from_account_id = ? AND transaction_type = 'withdrawal'",
    $account_id
  )->hash->{total};

  my $transferred_out = $db->query(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE from_account_id = ? AND transaction_type = 'transfer'",
    $account_id
  )->hash->{total};

  my $transferred_in = $db->query(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE to_account_id = ? AND transaction_type = 'transfer'",
    $account_id
  )->hash->{total};

  return {
    total_deposited      => $deposited + 0,
    total_withdrawn      => $withdrawn + 0,
    total_transferred_in => $transferred_in + 0,
    total_transferred_out => $transferred_out + 0,
  };
}

1;
