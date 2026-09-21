# 🏦 Usanase's Perl Banking Core API

[![Perl](https://img.shields.io/badge/Language-Perl-blue?style=for-the-badge&logo=perl)](https://www.perl.org/)
[![Mojolicious](https://img.shields.io/badge/Framework-Mojolicious-darkgreen?style=for-the-badge)](https://mojolicious.org/)
[![Database](https://img.shields.io/badge/Database-SQLite-003B57?style=for-the-badge&logo=sqlite)](https://sqlite.org/)
[![Security](https://img.shields.io/badge/Security-JWT%20%2B%20Bcrypt-red?style=for-the-badge&logo=jsonwebtokens)]()
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)]()

**A production-ready, modern banking core API built with Perl + Mojolicious.**

Architected by **Usanase**. Strict MVC, ACID-compliant dual-entry accounting, JWT authentication, and zero-config SQLite migrations.

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