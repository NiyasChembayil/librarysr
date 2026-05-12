class LiveCounter {
    constructor(elementId) {
        this.container = document.getElementById(elementId);
        if (!this.container) return; // Stability Fix: Don't crash if element is missing
        
        this.value = 0;
        this.digits = [];
        
        // Determine API URL based on current host
        this.apiBase = 'https://srishty-backend.onrender.com/api';
            
        this.apiUrl = `${this.apiBase}/accounts/auth/global_stats/`;
        this.init();
    }

    async init() {
        await this.fetchStats();
        this.render();
        this.startPolling();
    }

    async fetchStats() {
        try {
            const response = await fetch(this.apiUrl);
            if (!response.ok) throw new Error('API request failed');
            const data = await response.json();
            
            if (data.total_users !== undefined) {
                this.update(data.total_users);
            }
        } catch (error) {
            console.error('Error fetching stats:', error);
            // On error, show whatever value we have or 0
            if (this.value === 0) {
                this.update(0); 
            }
        }
    }

    render() {
        // We'll use 6 digits for the "premium" look
        const valStr = this.value.toString().padStart(6, '0');
        this.container.innerHTML = '';
        this.digits = [];
        
        // Split into groups of 3 (e.g., 000 006)
        const groups = [
            valStr.slice(0, 3),
            valStr.slice(3, 6)
        ];

        groups.forEach((group, gIdx) => {
            const groupEl = document.createElement('div');
            groupEl.className = 'digit-group';
            
            [...group].forEach((char, cIdx) => {
                const digitEl = document.createElement('div');
                digitEl.className = 'digit';
                digitEl.innerHTML = `<span>${char}</span>`;
                groupEl.appendChild(digitEl);
                this.digits.push(digitEl);
            });

            this.container.appendChild(groupEl);
        });
    }

    update(newValue) {
        if (newValue === this.value && this.digits.length > 0) return;

        const oldStr = this.value.toString().padStart(6, '0');
        const newStr = newValue.toString().padStart(6, '0');
        
        // Initial render if digits are empty
        if (this.digits.length === 0) {
            this.value = newValue;
            this.render();
            return;
        }

        for (let i = 0; i < newStr.length; i++) {
            if (oldStr[i] !== newStr[i]) {
                const digitEl = this.digits[i];
                if (digitEl) {
                    digitEl.classList.remove('changed');
                    void digitEl.offsetWidth; // Trigger reflow
                    digitEl.innerHTML = `<span>${newStr[i]}</span>`;
                    digitEl.classList.add('changed');
                }
            }
        }

        this.value = newValue;
    }

    startPolling() {
        // Fetch actual data every 5 seconds for a "live" feel
        setInterval(() => {
            this.fetchStats();
        }, 5000);
    }

    enterStudio() {
        console.log("Enter Studio clicked");
        const token = localStorage.getItem('access_token');
        if (token) {
            console.log("Token found, redirecting...");
            window.location.href = '/studio/v2/';
        } else {
            console.log("No token, showing auth...");
            this.showAuth('login');
        }
    }

    // Auth Logic
    showAuth(mode) {
        this.authMode = mode;
        const modal = document.getElementById('auth-modal');
        const title = document.getElementById('auth-title');
        const submitBtn = document.getElementById('auth-submit-btn');
        const toggleText = document.getElementById('auth-toggle-text');
        const toggleLink = document.getElementById('auth-toggle-link');
        const emailGroup = document.getElementById('email-group');

        if (mode === 'signup') {
            title.innerText = 'Join Srishty';
            submitBtn.innerText = 'Create Account';
            toggleText.innerText = 'Already an Author?';
            toggleLink.innerText = 'Sign In';
            emailGroup.classList.remove('hidden');
        } else {
            title.innerText = 'Author Login';
            submitBtn.innerText = 'Continue';
            toggleText.innerText = 'New Author?';
            toggleLink.innerText = 'Create Account';
            emailGroup.classList.add('hidden');
        }

        modal.classList.add('active');
    }

    hideAuth() {
        document.getElementById('auth-modal').classList.remove('active');
    }

    toggleAuthMode(e) {
        e.preventDefault();
        this.showAuth(this.authMode === 'login' ? 'signup' : 'login');
    }

    async handleAuthSubmit(e) {
        e.preventDefault();
        const username = document.getElementById('auth-username').value;
        const password = document.getElementById('auth-password').value;
        const email = document.getElementById('auth-email').value;
        const errorEl = document.getElementById('auth-error');

        errorEl.style.display = 'none';

        const endpoint = this.authMode === 'signup' ? '/accounts/auth/register/' : '/token/';
        const body = this.authMode === 'signup' 
            ? JSON.stringify({ username, password, email, role: 'author' })
            : JSON.stringify({ username, password });

        try {
            const response = await fetch(`${this.apiBase}${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: body
            });

            const data = await response.json();

            if (response.ok) {
                const token = this.authMode === 'signup' ? data.token.access : data.access;
                localStorage.setItem('access_token', token);
                localStorage.setItem('username', username);
                
                // Success! Redirect to Studio V2
                window.location.href = '/studio/v2/';
            } else {
                errorEl.innerText = data.detail || data.error || 'Authentication failed. Please try again.';
                errorEl.style.display = 'block';
            }
        } catch (error) {
            console.error('Auth error:', error);
            errorEl.innerText = 'Server connection error.';
            errorEl.style.display = 'block';
        }
    }
}

// Initialize the counter when the DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.liveCounter = new LiveCounter('counter');
});
