const API_URL = '/api';
let token = localStorage.getItem('jwt');
let accountsData = [];

// Init
window.onload = () => {
    if (token) {
        showView('dashboard-view');
        loadDashboard();
    } else {
        showView('auth-view');
    }
};

// -----------------------------------------------
// UI Helpers
// -----------------------------------------------
function showView(id) {
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.getElementById(id).classList.add('active');
}

function switchAuthTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.auth-form').forEach(f => f.classList.remove('active'));

    if (tab === 'login') {
        document.querySelector('.tab-btn:nth-child(1)').classList.add('active');
        document.getElementById('login-form').classList.add('active');
    } else {
        document.querySelector('.tab-btn:nth-child(2)').classList.add('active');
        document.getElementById('register-form').classList.add('active');
    }
}

function showModal(id) {
    if (['deposit-modal', 'withdraw-modal', 'transfer-modal'].includes(id)) {
        populateAccountDropdowns();
    }
    // Clear any previous error messages when opening a modal
    const errorEl = document.getElementById(id)?.querySelector('.error-msg');
    if (errorEl) errorEl.innerText = '';

    document.getElementById(id).classList.add('active');
}

function closeModal(id) {
    document.getElementById(id).classList.remove('active');
}

/** Show an inline error message inside a modal instead of an alert() */
function showModalError(modalId, message) {
    const errorEl = document.getElementById(modalId)?.querySelector('.error-msg');
    if (errorEl) {
        errorEl.innerText = message;
        errorEl.style.color = '';  // Reset to default error styling from CSS
    } else {
        // Fallback — should never happen if HTML is correct
        console.error(`[${modalId}] ${message}`);
    }
}

// -----------------------------------------------
// API Helper
// -----------------------------------------------
async function apiCall(endpoint, method = 'GET', body = null) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const config = { method, headers };
    if (body) config.body = JSON.stringify(body);

    const res = await fetch(`${API_URL}${endpoint}`, config);
    const data = await res.json();

    if (!res.ok) {
        if (res.status === 401 && endpoint !== '/auth/login') {
            logout();
        }
        throw new Error(data.error || 'API Error');
    }
    return data;
}

// -----------------------------------------------
// Auth Logic
// -----------------------------------------------
document.getElementById('login-form').onsubmit = async (e) => {
    e.preventDefault();
    const username = document.getElementById('login-username').value;
    const password = document.getElementById('login-password').value;
    try {
        const res = await apiCall('/auth/login', 'POST', { username, password });
        token = res.token;
        localStorage.setItem('jwt', token);
        showView('dashboard-view');
        loadDashboard();
    } catch (err) {
        document.getElementById('login-error').innerText = err.message;
        document.getElementById('login-error').style.color = '';
    }
};

document.getElementById('register-form').onsubmit = async (e) => {
    e.preventDefault();
    const username = document.getElementById('reg-username').value;
    const email    = document.getElementById('reg-email').value;
    const password = document.getElementById('reg-password').value;
    try {
        await apiCall('/auth/register', 'POST', { username, email, password });
        switchAuthTab('login');
        document.getElementById('login-username').value = username;
        const loginErr = document.getElementById('login-error');
        loginErr.innerText = 'Registration successful! Please sign in.';
        loginErr.style.color = 'var(--success)';
    } catch (err) {
        document.getElementById('reg-error').innerText = err.message;
        document.getElementById('reg-error').style.color = '';
    }
};

function logout() {
    token = null;
    accountsData = [];
    localStorage.removeItem('jwt');
    showView('auth-view');
}

// -----------------------------------------------
// Dashboard Logic
// -----------------------------------------------
async function loadDashboard() {
    try {
        const profile = await apiCall('/auth/me');
        document.getElementById('welcome-msg').innerText = `Welcome back, ${profile.profile.username}!`;

        await loadAccounts();
        await loadLoans();
    } catch (err) {
        console.error(err);
    }
}

async function loadAccounts() {
    try {
        const res = await apiCall('/accounts');
        accountsData = res.accounts || [];
        const list = document.getElementById('accounts-list');
        list.innerHTML = '';

        if (accountsData.length === 0) {
            list.innerHTML = '<div class="text-muted" style="color: var(--text-muted); font-size: 0.9rem;">No accounts found. Open one to get started!</div>';
            return;
        }

        accountsData.forEach(acc => {
            list.innerHTML += `
                <div class="card">
                    <div class="card-details">
                        <div class="card-title">${acc.account_type.charAt(0).toUpperCase() + acc.account_type.slice(1)} Account</div>
                        <div class="card-subtitle">ID: ${acc.id} | ACC: ${acc.account_number}</div>
                    </div>
                    <div class="card-amount">$${parseFloat(acc.balance).toFixed(2)}</div>
                </div>
            `;
        });
    } catch (e) { console.error(e); }
}

async function loadLoans() {
    try {
        const res = await apiCall('/loans');
        const loans = res.loans || [];
        const list  = document.getElementById('loans-list');
        list.innerHTML = '';

        if (loans.length === 0) {
            list.innerHTML = '<div class="text-muted" style="color: var(--text-muted); font-size: 0.9rem;">No active loans.</div>';
            return;
        }

        loans.forEach(loan => {
            const statusColor = loan.status === 'pending' ? 'orange' : 'var(--primary)';
            list.innerHTML += `
                <div class="card" style="border-color: ${statusColor}">
                    <div class="card-details">
                        <div class="card-title">Personal Loan</div>
                        <div class="card-subtitle">Status: ${loan.status.toUpperCase()} | Rate: ${loan.interest_rate}%</div>
                    </div>
                    <div class="card-amount">$${parseFloat(loan.amount).toFixed(2)}</div>
                </div>
            `;
        });
    } catch (e) { console.error(e); }
}

function populateAccountDropdowns() {
    const options = accountsData.map(a =>
        `<option value="${a.id}">${a.account_type.charAt(0).toUpperCase() + a.account_type.slice(1)} (ID: ${a.id}) — $${parseFloat(a.balance).toFixed(2)}</option>`
    ).join('');
    document.querySelectorAll('.account-dropdown').forEach(sel => sel.innerHTML = options);
}

// -----------------------------------------------
// Actions
// -----------------------------------------------
async function createAccount() {
    const type = document.getElementById('new-account-type').value;
    try {
        await apiCall('/accounts', 'POST', { account_type: type });
        closeModal('create-account-modal');
        loadAccounts();
    } catch (err) {
        showModalError('create-account-modal', err.message);
    }
}

async function submitDeposit() {
    const id     = document.getElementById('deposit-account').value;
    const amount = document.getElementById('deposit-amount').value;
    try {
        await apiCall('/transactions/deposit', 'POST', { account_id: parseInt(id), amount: parseFloat(amount) });
        closeModal('deposit-modal');
        loadAccounts();
    } catch (err) {
        showModalError('deposit-modal', err.message);
    }
}

async function submitWithdraw() {
    const id     = document.getElementById('withdraw-account').value;
    const amount = document.getElementById('withdraw-amount').value;
    try {
        await apiCall('/transactions/withdraw', 'POST', { account_id: parseInt(id), amount: parseFloat(amount) });
        closeModal('withdraw-modal');
        loadAccounts();
    } catch (err) {
        showModalError('withdraw-modal', err.message);
    }
}

async function submitTransfer() {
    const fromId = document.getElementById('transfer-from').value;
    const toId   = document.getElementById('transfer-to').value;
    const amount = document.getElementById('transfer-amount').value;
    try {
        await apiCall('/transactions/transfer', 'POST', {
            from_account_id: parseInt(fromId),
            to_account_id:   parseInt(toId),
            amount:          parseFloat(amount)
        });
        closeModal('transfer-modal');
        loadAccounts();
    } catch (err) {
        showModalError('transfer-modal', err.message);
    }
}

async function submitLoan() {
    const amount = document.getElementById('loan-amount').value;
    try {
        await apiCall('/loans/apply', 'POST', { amount: parseFloat(amount) });
        closeModal('loan-modal');
        loadLoans();
    } catch (err) {
        showModalError('loan-modal', err.message);
    }
}
