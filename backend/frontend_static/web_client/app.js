const API_BASE_URL = window.location.hostname === '127.0.0.1' || window.location.hostname === 'localhost' 
    ? 'http://127.0.0.1:8000/api' 
    : '/api';

function escapeHTML(str) {
    if (str === null || str === undefined) return '';
    return str.toString().replace(/[&<>'"]/g, 
        tag => ({
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            "'": '&#39;',
            '"': '&quot;'
        }[tag]));
}

class SrishtyReaderApp {
    constructor() {
        this.categories = [];
        this.token = localStorage.getItem('access_token');
        this.allMyBooks = [];
        this.galleryTab = 'all'; // all, drafts, published
        this.galleryView = 'grid'; // grid, list
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
        const landingSection = document.getElementById('landing-section');
        const featuresSection = document.getElementById('features');
        const visionSection = document.getElementById('vision');
        const worksSection = document.getElementById('my-works-section');
        const authModal = document.getElementById('auth-modal');
        
        if (this.token) {
            if (guestNav) guestNav.classList.add('hidden');
            if (authNav) authNav.classList.remove('hidden');
            if (usernameDisplay) usernameDisplay.textContent = localStorage.getItem('username') || 'Author';
            
            if (landingSection) landingSection.classList.add('hidden');
            if (featuresSection) featuresSection.classList.add('hidden');
            if (visionSection) visionSection.classList.add('hidden');
            if (worksSection) worksSection.classList.remove('hidden');
            if (authModal) authModal.classList.remove('active');
        } else {
            if (guestNav) guestNav.classList.remove('hidden');
            if (authNav) authNav.classList.add('hidden');
            
            if (landingSection) landingSection.classList.remove('hidden');
            if (featuresSection) featuresSection.classList.remove('hidden');
            if (visionSection) visionSection.classList.remove('hidden');
            if (worksSection) worksSection.classList.add('hidden');
        }
    }

    showAuth(mode) {
        const modal = document.getElementById('auth-modal');
        if (!modal) return;
        
        if (mode === 'signup' && !this.isSignUpMode) {
            this.toggleAuthMode();
        } else if (mode === 'login' && this.isSignUpMode) {
            this.toggleAuthMode();
        }
        
        modal.classList.add('active');
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
            ? `<img src="${escapeHTML(book.cover)}" alt="${escapeHTML(book.title)} cover" class="book-cover">`
            : `<div class="book-cover placeholder-cover">📖</div>`;
            
        return `
            <article class="book-card dashboard-card" onclick="readerApp.openBookInStudio(${escapeHTML(JSON.stringify(book))})">
                ${coverHtml}
                <div class="book-title" title="${escapeHTML(book.title)}">${escapeHTML(book.title)}</div>
                <div class="book-author">by ${escapeHTML(book.author_name || 'Unknown')}</div>
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
            this.allMyBooks = data;
            this.updateAuthorStats();
            this.renderMyBooks(data);
            this.renderAchievements();
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

    updateAuthorStats() {
        let totalReads = 0;
        let totalLikes = 0;
        let totalPublished = 0;
        let totalWords = 0;

        this.allMyBooks.forEach(book => {
            totalReads += book.total_reads || 0;
            totalLikes += book.likes_count || 0;
            if (book.is_published) totalPublished++;
            // Calculate mock total words from local storage if needed, or assume per book
            totalWords += parseInt(localStorage.getItem(`total_words_${book.id}`)) || 500; 
        });

        const readsEl = document.getElementById('total-reads');
        const followersEl = document.getElementById('total-followers');
        const streakEl = document.getElementById('writing-streak');
        const levelEl = document.getElementById('author-level');

        // Milestone Updates (with some mock data for social growth)
        if (readsEl) readsEl.textContent = totalReads.toLocaleString();
        if (followersEl) followersEl.textContent = (totalReads * 0.15).toFixed(0); // Mock 15% follow rate
        if (streakEl) streakEl.innerHTML = `🔥 7 Days`; // Mock streak
        
        // XP & Level Calculation
        const xp = (totalReads * 10) + (totalLikes * 50) + (totalPublished * 500);
        const level = Math.floor(Math.sqrt(xp / 100)) + 1;
        if (levelEl) levelEl.textContent = `Lv. ${level}`;
    }

    renderAchievements() {
        const list = document.getElementById('achievements-list');
        if (!list) return;

        let totalReads = 0;
        this.allMyBooks.forEach(b => totalReads += b.total_reads || 0);

        // Logic to "unlock" badges
        const badges = list.querySelectorAll('.achievement-badge');
        
        // 1. Author Badge (At least 1 book)
        if (this.allMyBooks.length > 0) badges[0].classList.replace('locked', 'unlocked');
        
        // 2. Rising Star (100+ reads)
        if (totalReads >= 100) badges[1].classList.replace('locked', 'unlocked');
        
        // 3. Streak badge (Mocked)
        badges[2].classList.replace('locked', 'unlocked'); 

        // 4. Night Owl (Mocked)
        badges[3].classList.replace('locked', 'unlocked');
    }

    setGalleryTab(tab) {
        this.galleryTab = tab;
        document.querySelectorAll('.btn-tab').forEach(btn => btn.classList.remove('active'));
        document.getElementById(`tab-${tab}`).classList.add('active');
        this.renderMyWorksList();
    }

    setGalleryView(view) {
        this.galleryView = view;
        document.querySelectorAll('.btn-view-toggle').forEach(btn => btn.classList.remove('active'));
        document.getElementById(`view-${view}`).classList.add('active');
        this.renderMyWorksList();
    }

    renderMyWorksList() {
        let filtered = this.allMyBooks;
        if (this.galleryTab === 'drafts') filtered = filtered.filter(b => !b.is_published);
        if (this.galleryTab === 'published') filtered = filtered.filter(b => b.is_published);
        
        this.renderMyBooks(filtered);
    }

    renderMyBooks(books) {
        const container = document.getElementById('my-books-container');
        const pinnedContainer = document.getElementById('pinned-project-container');
        if (!container) return;

        // 1. Identify Pinned Focus Project (Most recent)
        if (books.length > 0 && this.galleryTab === 'all' && pinnedContainer) {
            const pinned = books[0]; // Assuming first is most recent
            pinnedContainer.innerHTML = `
                <div class="hero-project-card animate-up">
                    <img src="${escapeHTML(pinned.cover) || '../frontend/assets/logo.png'}" class="hero-cover">
                    <div class="hero-details">
                        <span style="font-size: 12px; color: var(--accent-blue); text-transform: uppercase; letter-spacing: 2px; margin-bottom: 5px;">CURRENT FOCUS</span>
                        <h2 style="font-size: 28px; margin-bottom: 10px;">${escapeHTML(pinned.title)}</h2>
                        <p style="color: var(--text-secondary); margin-bottom: 20px; line-height: 1.5; max-width: 500px;">${escapeHTML(pinned.description || 'Continue working on your masterpiece and share it with the world.')}</p>
                        <div style="display: flex; gap: 15px;">
                            <button class="btn-primary" onclick="readerApp.openBookInStudio(${escapeHTML(JSON.stringify(pinned))})">Continue Writing</button>
                            <button class="btn-secondary" onclick="alert('Viewing Analytics...')">View Full Analytics</button>
                        </div>
                    </div>
                </div>
            `;
            // Remove pinned from the main list to avoid duplication
            var mainList = books.slice(1);
        } else {
            if (pinnedContainer) pinnedContainer.innerHTML = '';
            var mainList = books;
        }

        if (mainList.length === 0 && books.length === 0) {
            container.innerHTML = '<div class="loading-spinner" style="grid-column: 1/-1; padding: 40px;">No stories found in this tab.</div>';
            return;
        }

        // 2. Set View Class
        container.className = this.galleryView === 'grid' ? 'book-grid' : 'book-grid list-view';

        container.innerHTML = mainList.map(book => {
            const statusClass = book.is_published ? 'status-published' : 'status-draft';
            const statusLabel = book.is_published ? 'Published' : 'Draft';
            
            // Fix image URL
            let cover = book.cover;
            if (cover && !cover.startsWith('http')) {
                // Remove base domain if present to keep it relative
                cover = cover.replace('https://srishty-backend.onrender.com', '');
                if (!cover.startsWith('/')) cover = '/' + cover;
            }
            if (!cover) cover = '/static/assets/logo.png';
            
            if (this.galleryView === 'grid') {
                return `
                    <article class="book-card dashboard-card">
                        <div class="book-status-badge ${statusClass}">${statusLabel}</div>
                        <img src="${cover}" alt="${escapeHTML(book.title)}" class="book-cover">
                        
                        <div class="book-analytics-overlay">
                            <span>👁️ ${book.total_reads || 0}</span>
                            <span>❤️ ${book.likes_count || 0}</span>
                        </div>

                        <div class="quick-actions-hover">
                            <button class="action-btn" onclick="readerApp.openBookInStudio(${escapeHTML(JSON.stringify(book))})">✏️ Edit Story</button>
                            <button class="action-btn" onclick="alert('Shared to community!')">🔗 Share Link</button>
                        </div>

                        <div class="book-title" title="${escapeHTML(book.title)}">${escapeHTML(book.title)}</div>
                        <div class="book-author">by You</div>
                    </article>
                `;
            } else {
                // List View
                return `
                    <article class="dashboard-card">
                        <img src="${cover}" class="book-cover">
                        <div>
                            <div style="font-weight: 700; color: white;">${escapeHTML(book.title)}</div>
                            <div style="font-size: 11px; color: var(--text-secondary);">${statusLabel}</div>
                        </div>
                        <div class="book-analytics-overlay">
                            <span>👁️ ${book.total_reads || 0} Reads</span>
                        </div>
                        <div class="book-analytics-overlay">
                            <span>❤️ ${book.likes_count || 0} Likes</span>
                        </div>
                        <div class="quick-actions-hover">
                            <button class="action-btn" onclick="readerApp.openBookInStudio(${escapeHTML(JSON.stringify(book))})">Edit</button>
                            <button class="action-btn">Stats</button>
                        </div>
                    </article>
                `;
            }
        }).join('');
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
            <div>${escapeHTML(notification.message)}</div>
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

// --- Author Tools Modal Logic ---
readerApp.openToolModal = function(type) {
    const modal = document.getElementById('author-tools-modal');
    const title = document.getElementById('tool-modal-title');
    
    // Hide all tool contents first
    document.querySelectorAll('.tool-content').forEach(el => el.classList.add('hidden'));
    
    if (type === 'rank') {
        title.innerText = '🏆 Global Author Rankings';
        document.getElementById('tool-content-rank').classList.remove('hidden');
        this.renderLeaderboard();
    } else if (type === 'settings') {
        title.innerText = '⚙️ Profile Settings';
        document.getElementById('tool-content-settings').classList.remove('hidden');
        // Load current settings
        document.getElementById('setting-pen-name').value = localStorage.getItem('username') || '';
        document.getElementById('setting-bio').value = localStorage.getItem('author_bio') || '';
    } else if (type === 'help') {
        title.innerText = '❓ Author Help Center';
        document.getElementById('tool-content-help').classList.remove('hidden');
    }
    
    modal.classList.add('active');
};

readerApp.closeToolModal = function() {
    document.getElementById('author-tools-modal').classList.remove('active');
};

readerApp.renderLeaderboard = function() {
    const list = document.getElementById('leaderboard-list');
    const mockLeaders = [
        { name: "Niyas C.", reads: "15.4k", rank: "Diamond" },
        { name: "StoryMaster", reads: "12.1k", rank: "Diamond" },
        { name: "Ink & Quill", reads: "8.9k", rank: "Platinum" },
        { name: "The Novelist", reads: "5.2k", rank: "Gold" },
        { name: "WordSmith", reads: "4.8k", rank: "Gold" }
    ];

    list.innerHTML = mockLeaders.map((leader, i) => `
        <div class="glass" style="display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; border-radius: 12px; background: ${i === 0 ? 'rgba(108, 99, 255, 0.1)' : 'rgba(255,255,255,0.02)'}; border: 1px solid ${i === 0 ? 'var(--accent-blue)' : 'rgba(255,255,255,0.05)'}">
            <div style="display: flex; align-items: center; gap: 15px;">
                <span style="font-weight: 800; color: var(--text-secondary); width: 20px;">#${i + 1}</span>
                <span style="font-weight: 700; color: white;">${escapeHTML(leader.name)}</span>
            </div>
            <div style="text-align: right;">
                <div style="font-size: 14px; font-weight: 800; color: var(--accent-blue); text-shadow: 0 0 10px rgba(108, 99, 255, 0.5);">${escapeHTML(leader.reads)}</div>
                <div style="font-size: 10px; text-transform: uppercase; letter-spacing: 1px; color: var(--text-secondary); opacity: 0.8;">${escapeHTML(leader.rank)}</div>
            </div>
        </div>
    `).join('');
};

readerApp.saveAuthorSettings = function() {
    const name = document.getElementById('setting-pen-name').value;
    const bio = document.getElementById('setting-bio').value;
    
    localStorage.setItem('username', name);
    localStorage.setItem('author_bio', bio);
    
    // Update UI
    const navUsername = document.getElementById('nav-username');
    if (navUsername) navUsername.innerText = name;
    
    alert("Profile updated successfully!");
    this.closeToolModal();
};

readerApp.handleSocialLogin = function(provider) {
    alert(`Sign in with ${provider.charAt(0).toUpperCase() + provider.slice(1)} is being configured. Please use your Srishty credentials for now.`);
};
