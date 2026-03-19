# 🏦 Usanase's Perl Banking Core API

[![Perl](https://img.shields.io/badge/Language-Perl-blue?style=for-the-badge&logo=perl)](https://www.perl.org/)
[![Mojolicious](https://img.shields.io/badge/Framework-Mojolicious-darkgreen?style=for-the-badge)](https://mojolicious.org/)
[![Database](https://img.shields.io/badge/Database-SQLite-003B57?style=for-the-badge&logo=sqlite)](https://sqlite.org/)
[![Security](https://img.shields.io/badge/Security-JWT%20%26%20Bcrypt-red?style=for-the-badge&logo=jsonwebtokens)]()
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)]()

*Welcome to the future of fintech backends! Architected by **Usanase**, this is a hyper-complex, production-ready Banking API. Experience the power of modern Perl matched with scalable MVC architecture!*

---

## ✨ Features at a Glance

*   🔐 **Bank-Grade Security**: Bulletproof user authentication with **Bcrypt** hashed passwords and **JWT** (JSON Web Tokens) for impenetrable route protection.
*   💾 **Automated Migrations**: Zero-config database setup. Our SQLite schemas deploy dynamically on boot!
*   🛡️ **ACID Transactions**: Dual-entry accounting system. Wire transfers use rigid SQL database transactions. Money only moves if it's 100% verified—no lost funds, ever.
*   🏛️ **Strict MVC Architecture**: Crystal clear logic separation using Controllers and Models mapped with Dependency Injection.

---

## 🛠️ Quick Start Guide

Ready to spin up the bank? Follow these simple steps!

### 1. 🧰 Install Perl
Don't have Perl yet? Download and install **[Strawberry Perl](https://strawberryperl.com/)** (Windows). This installs both `perl` and `cpanm` directly into your system.

### 2. 📦 Fetch Dependencies
Open your terminal in this directory and run:

```powershell
cpanm --installdeps .
```

### 3. 🚀 Launch the Core
Boot up the development server with hot-reloading:

```powershell
morbo script/banking_app
```
*The server will instantly deploy on `http://127.0.0.1:3000` and automatically build your `banking.db`.*

---

## 📡 API Reference & Endpoints

> **Note:** Protected endpoints require you to pass your token in the headers as: `Authorization: Bearer <your_jwt_token>`

### 🔓 Public Routes (Auth)

| Method | Endpoint | Description | JSON Body Example |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Open a new bank profile | `{"username": "john", "password": "123", "email": "a@a.com"}` |
| `POST` | `/api/auth/login` | Securely login & get JWT | `{"username": "john", "password": "123"}` |

### 🔒 Protected Routes (Accounts & Money)

| Method | Endpoint | Description | JSON Body Example |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/accounts` | Create checking/savings | `{"account_type": "checking"}` |
| `GET` | `/api/accounts` | List your active accounts | *-* |
| `GET` | `/api/accounts/:id` | View account balance | *-* |
| `POST` | `/api/transactions/deposit` | Add funds | `{"account_id": 1, "amount": 500}` |
| `POST` | `/api/transactions/withdraw` | Take out cash | `{"account_id": 1, "amount": 100}` |
| `GET` | `/api/accounts/:id/transactions` | Read the full ledger | *-* |
| `POST` | `/api/loans/apply` | Apply for a new bank loan | `{"amount": 50000}` |
| `GET` | `/api/loans` | View your pending loans | *-* |

---

<br>
<div align="center">
  <b>Built from the ground up with ❤️ by Usanase</b>
</div>
<br>
