class LiveCounter {
    constructor(elementId) {
        this.container = document.getElementById(elementId);
        this.value = 0;
        this.digits = [];
        
        // Determine API URL based on current host
        this.apiBase = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
            ? 'http://127.0.0.1:8000/api'
            : 'https://srishty-backend.onrender.com/api';
            
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
}

// Initialize the counter when the DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new LiveCounter('counter');
});
