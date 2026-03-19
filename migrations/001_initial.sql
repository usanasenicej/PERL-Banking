-- 1 up
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  account_number TEXT UNIQUE NOT NULL,
  account_type TEXT NOT NULL, 
  balance DECIMAL(15,2) DEFAULT 0.00,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_account_id INTEGER REFERENCES accounts(id),
  to_account_id INTEGER REFERENCES accounts(id),
  amount DECIMAL(15,2) NOT NULL,
  transaction_type TEXT NOT NULL, 
  status TEXT DEFAULT 'completed',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 1 down
DROP TABLE transactions;
DROP TABLE accounts;
DROP TABLE users;
