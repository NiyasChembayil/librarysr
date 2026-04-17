const API_BASE_URL = 'http://127.0.0.1:8000/api';

class SrishtyReaderApp {
    constructor() {
        this.categories = [];
        this.token = localStorage.getItem('access_token');
        this.isSignUpMode = false;
        this.ws = null;
        this.init();
    }

    init() {
        this.checkAuth();
        this.bindEvents();

        if (this.token) {
            this.initNotifications();
            this.loadMyWorks();
        }
    }

    checkAuth() {
        const guestNav = document.getElementById('guest-nav');
        const authNav = document.getElementById('auth-nav');
        const usernameDisplay = document.getElementById('nav-username');
        const authSection = document.getElementById('auth-section');
        const worksSection = document.getElementById('my-works-section');
        
        if (this.token) {
            if (guestNav) guestNav.classList.add('hidden');
            if (authNav) authNav.classList.remove('hidden');
            if (usernameDisplay) usernameDisplay.textContent = localStorage.getItem('username') || 'Author';
            
            if (authSection) authSection.classList.add('hidden');
            if (worksSection) worksSection.classList.remove('hidden');
        } else {
            if (guestNav) guestNav.classList.remove('hidden');
            if (authNav) authNav.classList.add('hidden');
            
            if (authSection) authSection.classList.remove('hidden');
            if (worksSection) worksSection.classList.add('hidden');
        }
    }

    toggleAuthMode(e) {
        if (e) e.preventDefault();
        this.isSignUpMode = !this.isSignUpMode;
        
        const title = document.getElementById('auth-title');
        const submitBtn = document.getElementById('auth-submit-btn');
        const emailGroup = document.getElementById('email-group');
        const toggleText = document.getElementById('auth-toggle-text');
        const toggleLink = document.getElementById('auth-toggle-link');
        
        if (this.isSignUpMode) {
            title.textContent = 'Create Account';
            submitBtn.textContent = 'Sign Up';
            emailGroup.classList.remove('hidden');
            document.getElementById('auth-email').required = true;
            toggleText.textContent = 'Already have an account?';
            toggleLink.textContent = 'Sign In';
        } else {
            title.textContent = 'Sign In';
            submitBtn.textContent = 'Sign In';
            emailGroup.classList.add('hidden');
            document.getElementById('auth-email').required = false;
            toggleText.textContent = 'New to Srishty?';
            toggleLink.textContent = 'Create Account';
        }
    }

    async handleAuthSubmit(e) {
        e.preventDefault();
        const username = document.getElementById('auth-username').value;
        const password = document.getElementById('auth-password').value;
        const errorEl = document.getElementById('auth-error');
        const btn = document.getElementById('auth-submit-btn');
        
        errorEl.style.display = 'none';
        btn.disabled = true;
        btn.textContent = 'Please wait...';
        
        try {
            if (this.isSignUpMode) {
                const email = document.getElementById('auth-email').value;
                const response = await fetch(`${API_BASE_URL}/accounts/auth/register/`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, email, password, role: 'author' })
                });
                
                if (!response.ok) throw new Error('Registration failed. Username may exist.');
                
                await this.loginUser(username, password);
            } else {
                await this.loginUser(username, password);
            }
        } catch (error) {
            errorEl.textContent = error.message;
            errorEl.style.display = 'block';
        } finally {
            btn.disabled = false;
            btn.textContent = this.isSignUpMode ? 'Sign Up' : 'Sign In';
        }
    }

    async loginUser(username, password) {
        const response = await fetch(`${API_BASE_URL}/token/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        
        if (!response.ok) throw new Error('Invalid credentials');
        
        const data = await response.json();
        this.token = data.access;
        localStorage.setItem('access_token', data.access);
        if (data.refresh) localStorage.setItem('refresh_token', data.refresh);
        localStorage.setItem('username', username);
        
        this.checkAuth();
        this.initNotifications();
        this.loadMyWorks();
    }

    logout() {
        this.token = null;
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('username');
        this.checkAuth();
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
        if (window.location.pathname.includes('studio.html')) {
            window.location.href = 'index.html';
        }
    }

    detectLocation() {
        const locBadge = document.getElementById('user-location');
        const trendInd = document.getElementById('local-trend-indicator');
        if (!locBadge || !trendInd) return;

        // Mocking location based on timezone strictly for UI personalization
        const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
        let region = "Global";
        if (tz.includes('America')) region = "North America";
        else if (tz.includes('Europe')) region = "Europe";
        else if (tz.includes('Asia')) region = "Asia Region";
        
        locBadge.innerHTML = `📍 Trending in ${region}`;
        trendInd.textContent = `in ${region}`;
    }

    bindEvents() {
        // Setup category tab clicks dynamically
        const tabContainer = document.querySelector('.category-tabs');
        if (!tabContainer) return;

        tabContainer.addEventListener('click', (e) => {
            if (e.target.classList.contains('tab-btn')) {
                // Update active state
                document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
                e.target.classList.add('active');
                
                // Fetch books for selected category
                const catSlug = e.target.getAttribute('data-category');
                this.loadCategoryBooks(catSlug);
            }
        });
    }

    async fetchAPI(endpoint, options = {}) {
        try {
            const headers = { 'Content-Type': 'application/json', ...options.headers };
            // If body is FormData, let browser set Content-Type correctly
            if (options.body instanceof FormData) {
                delete headers['Content-Type'];
            }
            if (this.token) {
                headers['Authorization'] = `Bearer ${this.token}`;
            }
            
            const response = await fetch(`${API_BASE_URL}${endpoint}`, {
                ...options,
                headers
            });
            if (!response.ok) throw new Error('Network response was not ok');
            return await response.json();
        } catch (error) {
            console.error(`API Error on ${endpoint}:`, error);
            return null;
        }
    }

    openBookInStudio(bookObj) {
        localStorage.setItem('activeStudioBook', JSON.stringify(bookObj));
        window.location.href = 'studio.html';
    }

    startNewBook() {
        localStorage.removeItem('activeStudioBook');
        window.location.href = 'studio.html';
    }

    createBookCardHTML(book) {
        // Fallback for missing cover
        const coverHtml = book.cover 
            ? `<img src="${book.cover}" alt="${book.title} cover" class="book-cover">`
            : `<div class="book-cover placeholder-cover">📖</div>`;
            
        return `
            <article class="book-card dashboard-card" onclick="readerApp.openBookInStudio(${JSON.stringify(book).replace(/"/g, '&quot;')})">
                ${coverHtml}
                <div class="book-title" title="${book.title}">${book.title}</div>
                <div class="book-author">by ${book.author_name || 'Unknown'}</div>
            </article>
        `;
    }

    async loadTrendingBooks() {
        const container = document.getElementById('trending-carousel');
        if (!container) return;

        const data = await this.fetchAPI('/core/books/trending/');
        
        if (data && data.length > 0) {
            container.innerHTML = data.map(book => this.createBookCardHTML(book)).join('');
        } else {
            container.innerHTML = '<div class="loading-spinner">No trending stories found today.</div>';
        }
    }

    async loadCategories() {
        const data = await this.fetchAPI('/core/categories/');
        // We could dynamically render tabs here if needed. 
        // For now, we fetch them to map slugs robustly.
        if (data && data.results) {
            this.categories = data.results;
        }
    }

    async loadCategoryBooks(slug) {
        const container = document.getElementById('category-books');
        if (!container) return;

        container.innerHTML = '<div class="loading-spinner">Loading books...</div>';

        // Adjust ID/Slug logic based on backend. If filtering uses category ID:
        const category = this.categories.find(c => c.slug === slug || c.slug.toLowerCase() === slug);
        const filterStr = category ? `?category=${category.id}` : '';

        const data = await this.fetchAPI(`/core/books/${filterStr}`);
        
        if (data && data.results && data.results.length > 0) {
            container.innerHTML = data.results.map(book => this.createBookCardHTML(book)).join('');
        } else {
            container.innerHTML = '<div class="loading-spinner" style="grid-column: 1/-1;">No books found in this genre yet. Be the first to write one!</div>';
        }
    }

    async loadMyWorks() {
        const container = document.getElementById('my-books-container');
        const section = document.getElementById('my-works-section');
        if (!container || !this.token) return;

        container.innerHTML = '<div class="loading-spinner">Waking up your stories...</div>';
        
        const data = await this.fetchAPI('/core/books/my_books/');
        
        if (data && data.length > 0) {
            section.classList.remove('hidden');
            container.innerHTML = data.map(book => {
                const draftBadge = !book.is_published ? '<span class="draft-badge" style="position:absolute; top:10px; right:10px; background:var(--accent-blue); padding:4px 8px; border-radius:4px; font-size:12px; font-weight:bold;">Draft</span>' : '';
                const baseCard = this.createBookCardHTML(book);
                // Inject draft badge if needed
                return baseCard.replace('</article>', `${draftBadge}</article>`);
            }).join('');
        } else {
            container.innerHTML = `
                <div class="loading-spinner" style="grid-column: 1/-1; padding: 60px;">
                    <div style="font-size: 40px; margin-bottom: 20px;">✍️</div>
                    <div style="color: white; font-size: 20px; font-weight: 700; margin-bottom: 10px;">Your gallery is empty</div>
                    <p style="margin-bottom: 30px;">Every great author starts with a single word. Start yours today!</p>
                    <button class="btn-primary" onclick="readerApp.startNewBook()">Begin Your First Masterpiece</button>
                </div>
            `;
        }
    }

    initNotifications() {
        if (this.ws) this.ws.close();

        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        // Use relative URL for simple host mapping
        this.ws = new WebSocket(`${protocol}//${window.location.host}/ws/notifications/?token=${this.token}`);

        this.ws.onmessage = (e) => {
            const data = JSON.parse(e.data);
            if (data.type === 'notification') {
                this.showToast(data.notification);
            }
        };

        this.ws.onclose = () => {
            console.log('Notification WebSocket closed. Reconnecting in 5s...');
            setTimeout(() => {
                if (this.token) this.initNotifications();
            }, 5000);
        };
    }

    showToast(notification) {
        let toastContainer = document.getElementById('toast-container');
        if (!toastContainer) {
            toastContainer = document.createElement('div');
            toastContainer.id = 'toast-container';
            document.body.appendChild(toastContainer);
        }

        const toast = document.createElement('div');
        toast.className = 'toast glass';
        toast.innerHTML = `
            <div style="font-weight: 800; color: var(--accent-blue); margin-bottom: 4px;">New Notification</div>
            <div>${notification.message}</div>
        `;

        toastContainer.appendChild(toast);

        // Animate in and out
        setTimeout(() => toast.classList.add('active'), 10);
        setTimeout(() => {
            toast.classList.remove('active');
            setTimeout(() => toast.remove(), 500);
        }, 5000);
    }
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
    window.readerApp = new SrishtyReaderApp();
});
