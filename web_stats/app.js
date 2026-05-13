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
        console.log('Counter initialized. API:', this.apiUrl);
        this.init();
    }

    async init() {
        // Render initial state (000000) immediately
        this.render();
        
        // Then try to fetch real stats
        try {
            await this.fetchStats();
        } catch (e) {
            console.error('Initial fetch failed:', e);
        }
        
        this.startPolling();
    }

    async fetchStats() {
        try {
            const response = await fetch(this.apiUrl);
            if (!response.ok) throw new Error(`API request failed: ${response.status}`);
            const data = await response.json();
            
            console.log('Fetched stats:', data);
            if (data.total_users !== undefined) {
                this.update(data.total_users);
            }
        } catch (error) {
            console.error('Error fetching stats:', error);
            // On error, ensure we at least show 0
            if (this.value === 0 && this.digits.length === 0) {
                this.render();
            }
        }
    }

    render() {
        const valStr = this.value.toString().padStart(6, '0');
        console.log('Rendering counter:', valStr);
        this.container.innerHTML = '';
        this.digits = [];
        
        const groups = [
            valStr.slice(0, 3),
            valStr.slice(3, 6)
        ];

        groups.forEach((group) => {
            const groupEl = document.createElement('div');
            groupEl.className = 'digit-group';
            
            [...group].forEach((char) => {
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
                    void digitEl.offsetWidth; 
                    digitEl.innerHTML = `<span>${newStr[i]}</span>`;
                    digitEl.classList.add('changed');
                }
            }
        }

        this.value = newValue;
    }

    startPolling() {
        setInterval(() => {
            this.fetchStats();
        }, 5000);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('counter')) {
        new LiveCounter('counter');
    } else {
        console.error('Counter element not found!');
    }
});
