# 🏦 Usanase's Perl Banking Core API

[![Perl](https://img.shields.io/badge/Language-Perl-blue?style=for-the-badge&logo=perl)](https://www.perl.org/)
[![Mojolicious](https://img.shields.io/badge/Framework-Mojolicious-darkgreen?style=for-the-badge)](https://mojolicious.org/)
[![Database](https://img.shields.io/badge/Database-SQLite-003B57?style=for-the-badge&logo=sqlite)](https://sqlite.org/)
[![Security](https://img.shields.io/badge/Security-JWT%20%2B%20Bcrypt-red?style=for-the-badge&logo=jsonwebtokens)]()
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)]()

**A production-ready, modern banking core API built with Perl and Mojolicious.**

Architected by **Usanase**.
---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔐 **Bank-grade security** | Bcrypt password hashing + JWT authentication on all protected routes |
| 💾 **Zero-config database** | SQLite schema is created and migrated automatically on first boot |
| 🛡️ **ACID transactions** | All money movements (deposit, withdraw, transfer) run inside database transactions |
| 🏛️ **Clean MVC + DI** | Controllers and Models with clear separation of concerns |
| 📊 **Account summaries** | Built-in totals for money in / money out |
| 📄 **Paginated ledgers** | Transaction history with `page` & `limit` support |
| 🏦 **Loan management** | Apply, view, and repay loans |
| 🛑 **Rate limiting** | Built-in protection against brute-force attacks |

---

## 🛠️ Quick Start

### Prerequisites

- **Perl 5.30+** (recommended: [Strawberry Perl](https://strawberryperl.com/) on Windows)
- `cpanm` (comes with Strawberry Perl)

### 1. Install dependencies

```bash
cpanm --installdeps .

---

## 🗺️ API Endpoints

All protected routes require an `Authorization: Bearer <token>` header.

### Auth (`/api/auth`)

| Method | Path | Auth? | Description |
|--------|------|-------|-------------|
| `POST` | `/api/auth/register` | ❌ | Register a new user |
| `POST` | `/api/auth/login` | ❌ | Login and receive a JWT token |
| `GET` | `/api/auth/me` | ✅ | Get current user profile |
| `PATCH` | `/api/auth/me` | ✅ | Update email, full name, or password |
| `DELETE` | `/api/auth/me` | ✅ | Permanently delete your user account |

### Accounts (`/api/accounts`)

| Method | Path | Auth? | Description |
|--------|------|-------|-------------|
| `GET` | `/api/accounts` | ✅ | List all accounts for the current user |
| `POST` | `/api/accounts` | ✅ | Create a new checking or savings account |
| `GET` | `/api/accounts/:id` | ✅ | Get a specific account |
| `DELETE` | `/api/accounts/:id` | ✅ | Delete an account (must have zero balance) |

### Transactions (`/api/transactions`)

| Method | Path | Auth? | Description |
|--------|------|-------|-------------|
| `POST` | `/api/transactions/deposit` | ✅ | Deposit funds into an account |
| `POST` | `/api/transactions/withdraw` | ✅ | Withdraw funds from an account |
| `POST` | `/api/transactions/transfer` | ✅ | Transfer funds between accounts (flat \$1.00 fee) |
| `GET` | `/api/accounts/:id/history` | ✅ | Paginated transaction history |
| `GET` | `/api/accounts/:id/summary` | ✅ | Total money in / money out summary |

### Loans (`/api/loans`)

| Method | Path | Auth? | Description |
|--------|------|-------|-------------|
| `POST` | `/api/loans` | ✅ | Apply for a loan |
| `GET` | `/api/loans` | ✅ | List all loans for the current user |
| `POST` | `/api/loans/:id/repay` | ✅ | Make a loan repayment |