const API_BASE_URL = '/api';

class AdminApp {
    constructor() {
        this.token = localStorage.getItem('srishty_admin_token');
        this.user = JSON.parse(localStorage.getItem('srishty_admin_user'));
        this.currentView = 'dashboard';
        
        this.init();
    }

    init() {
        this.checkAuth();
        this.bindEvents();
        if (this.token) {
            this.loadDashboard();
        }
    }

    checkAuth() {
        if (!this.token) {
            document.getElementById('login-overlay').classList.remove('hidden');
            document.getElementById('app').classList.add('blurred');
        } else {
            document.getElementById('login-overlay').classList.add('hidden');
            document.getElementById('app').classList.remove('blurred');
            document.getElementById('admin-name').textContent = this.user.username;
        }
    }

    bindEvents() {
        // Login Form
        document.getElementById('login-form').addEventListener('submit', (e) => this.login(e));

        // Navigation
        const navItems = document.querySelectorAll('.nav-item');
        navItems.forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                const view = item.id.replace('nav-', '');
                this.switchView(view);
                
                // Update UI state
                navItems.forEach(nav => nav.classList.remove('active'));
                item.classList.add('active');
            });
        });
    }

    async login(e) {
        e.preventDefault();
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;

        try {
            const response = await fetch(`${API_BASE_URL}/token/`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });

            if (response.ok) {
                const data = await response.json();
                this.token = data.access;
                
                // Validate if user is admin
                const profileRes = await this.fetchWithAuth(`${API_BASE_URL}/accounts/profile/me/`);
                if (profileRes.role !== 'admin') {
                    alert('Access denied: You do not have administrative privileges.');
                    this.logout();
                    return;
                }

                this.user = profileRes;
                localStorage.setItem('srishty_admin_token', this.token);
                localStorage.setItem('srishty_admin_user', JSON.stringify(this.user));
                
                this.checkAuth();
                this.loadDashboard();
            } else {
                alert('Authentication failed. Please check your credentials.');
            }
        } catch (error) {
            console.error('Login error:', error);
            alert('A connection error occurred.');
        }
    }

    logout() {
        localStorage.removeItem('srishty_admin_token');
        localStorage.removeItem('srishty_admin_user');
        window.location.reload();
    }

    async fetchWithAuth(url, options = {}) {
        const headers = {
            'Authorization': `Bearer ${this.token}`,
            'Content-Type': 'application/json',
            ...options.headers
        };

        const response = await fetch(url, { ...options, headers });
        if (response.status === 401) {
            this.logout();
            return;
        }
        return response.json();
    }

    switchView(view) {
        this.currentView = view;
        const container = document.getElementById('view-container');
        const title = document.getElementById('page-title');

        switch (view) {
            case 'dashboard':
                title.textContent = 'Dashboard Overview';
                this.loadDashboard();
                break;
            case 'users':
                title.textContent = 'User Management';
                this.loadUsersView();
                break;
            case 'books':
                title.textContent = 'Content Moderation';
                this.loadBooksView();
                break;
            case 'analytics':
                title.textContent = 'Platform Analytics';
                this.loadAnalyticsView();
                break;
            case 'settings':
                title.textContent = 'System Settings';
                this.loadSettingsView();
                break;
            case 'sounds':
                title.textContent = 'Ambient Sound Library';
                this.loadSoundsView();
                break;
            case 'categories':
                title.textContent = 'Genre & Mood Management';
                this.loadCategoriesView();
                break;
            default:
                container.innerHTML = '<div class="glass section-card"><h3>Coming Soon</h3><p>This module is currently in development.</p></div>';
        }
    }

    async loadDashboard() {
        try {
            const stats = await this.fetchWithAuth(`${API_BASE_URL}/admin/admin-stats/stats/`);
            const activity = await this.fetchWithAuth(`${API_BASE_URL}/admin/admin-stats/recent_activity/`);

            // Update stats cards
            document.getElementById('count-users').textContent = stats.users.total.toLocaleString();
            document.getElementById('count-authors').textContent = stats.users.authors.toLocaleString();
            document.getElementById('count-books').textContent = stats.books.total.toLocaleString();
            document.getElementById('count-revenue').textContent = `$${stats.revenue.total.toFixed(2)}`;

            // Render recent books
            const list = document.getElementById('recent-books-list');
            list.innerHTML = activity.books.map(book => `
                <tr class="animate-slide-up">
                    <td>${book.title}</td>
                    <td>${book.author}</td>
                    <td>Fiction</td>
                    <td><span class="status-badge active">Published</span></td>
                    <td><button class="btn-action">Manage</button></td>
                </tr>
            `).join('');

        } catch (error) {
            console.error('Failed to load dashboard data:', error);
        }
    }

    async loadUsersView() {
        const container = document.getElementById('view-container');
        container.innerHTML = `<div class="glass section-card animate-slide-up">
            <h3>Registered Platform Users</h3>
            <div class="table-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>User ID</th>
                            <th>Username</th>
                            <th>Role</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody id="users-list-target">
                        <tr><td colspan="5">Loading user data...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>`;

        try {
            const data = await this.fetchWithAuth(`${API_BASE_URL}/accounts/profile/`);
            const target = document.getElementById('users-list-target');
            target.innerHTML = data.results.map(profile => `
                <tr>
                    <td>#${profile.id}</td>
                    <td>
                        ${profile.username}
                        ${profile.is_verified ? '<span style="color: #00D2FF; margin-left: 5px;" title="Verified User">☑️</span>' : ''}
                    </td>
                    <td>${profile.role}</td>
                    <td><span class="status-badge ${profile.role}">Online</span></td>
                    <td>
                        <button class="btn-action ${profile.is_verified ? 'orange' : 'blue'}" 
                                onclick="adminApp.toggleVerification(${profile.id})">
                            ${profile.is_verified ? 'Unverify' : 'Verify'}
                        </button>
                        <button class="btn-action red">Block</button>
                    </td>
                </tr>
            `).join('');
        } catch (e) {
            console.error(e);
        }
    }

    async toggleVerification(profileId) {
        try {
            const res = await this.fetchWithAuth(`${API_BASE_URL}/accounts/profile/${profileId}/toggle_verification/`, {
                method: 'POST'
            });
            if (res.status === 'success') {
                this.loadUsersView();
            }
        } catch (error) {
            console.error('Verification toggle failed:', error);
        }
    }

    async loadBooksView() {
        const container = document.getElementById('view-container');
        container.innerHTML = `<div class="glass section-card animate-slide-up">
            <h3>Book Catalog & Moderation</h3>
            <div class="table-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Book ID</th>
                            <th>Title</th>
                            <th>Author</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody id="books-list-target">
                        <tr><td colspan="5">Loading book data...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>`;

        try {
            const data = await this.fetchWithAuth(`${API_BASE_URL}/core/books/`);
            const target = document.getElementById('books-list-target');
            target.innerHTML = data.results.map(book => `
                <tr>
                    <td>#${book.id}</td>
                    <td>${book.title}</td>
                    <td>${book.author_name}</td>
                    <td><span class="status-badge active">Live</span></td>
                    <td><button class="btn-action red">Remove</button></td>
                </tr>
            `).join('');
        } catch (e) {
            console.error(e);
        }
    }
    async loadAnalyticsView() {
        const container = document.getElementById('view-container');
        container.innerHTML = `
            <div class="chart-grid">
                <div class="glass section-card animate-slide-up">
                    <h3>Revenue Growth (30 Days)</h3>
                    <div class="chart-container">
                        <canvas id="revenueChart"></canvas>
                    </div>
                </div>
                <div class="glass section-card animate-slide-up" style="animation-delay: 0.1s">
                    <h3>User Demographics</h3>
                    <div class="chart-container">
                        <canvas id="userChart"></canvas>
                    </div>
                </div>
            </div>
        `;

        try {
            const stats = await this.fetchWithAuth(`${API_BASE_URL}/admin/admin-stats/stats/`);
            
            // Generate simulated 30-day historical data ending at 'total revenue'
            const days = Array.from({length: 30}, (_, i) => `Day ${i+1}`);
            let currentRev = 0;
            const revData = days.map((_, i) => {
                const increase = (stats.revenue.total / 30) * (Math.random() * 0.5 + 0.75);
                currentRev += increase;
                return currentRev;
            });
            // Force last point to be exactly the real total
            revData[29] = stats.revenue.total;

            // Render Revenue Line Chart
            const ctxRev = document.getElementById('revenueChart').getContext('2d');
            new Chart(ctxRev, {
                type: 'line',
                data: {
                    labels: days,
                    datasets: [{
                        label: 'Total Revenue ($)',
                        data: revData,
                        borderColor: '#00D2FF',
                        backgroundColor: 'rgba(0, 210, 255, 0.1)',
                        borderWidth: 3,
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { labels: { color: '#fff' } } },
                    scales: {
                        y: { 
                            grid: { color: 'rgba(255, 255, 255, 0.1)' },
                            ticks: { color: '#rgba(255, 255, 255, 0.6)' }
                        },
                        x: { 
                            grid: { display: false },
                            ticks: { display: false }
                        }
                    }
                }
            });

            // Render User Pie Chart
            const ctxUser = document.getElementById('userChart').getContext('2d');
            new Chart(ctxUser, {
                type: 'doughnut',
                data: {
                    labels: ['Readers', 'Authors'],
                    datasets: [{
                        data: [stats.users.readers, stats.users.authors],
                        backgroundColor: ['#6C63FF', '#00D2FF'],
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { 
                        legend: { position: 'bottom', labels: { color: '#fff', padding: 20 } }
                    },
                    cutout: '70%'
                }
            });

        } catch (e) {
            console.error('Failed to load analytics:', e);
        }
    }

    loadSettingsView() {
        const container = document.getElementById('view-container');
        
        // Load mock settings from local storage or set defaults
        const settings = JSON.parse(localStorage.getItem('srishty_settings')) || {
            platformName: 'Srishty StoryVerse',
            maintenanceMode: false,
            allowNewRegistrations: true,
            authorCommission: '70'
        };

        container.innerHTML = `
            <div class="glass section-card animate-slide-up" style="max-width: 800px;">
                <h3>Platform Configuration</h3>
                <form id="settings-form">
                    
                    <div class="settings-group">
                        <h4>General Options</h4>
                        <div class="form-group">
                            <label>Platform Name</label>
                            <input type="text" id="set-name" value="${settings.platformName}" required>
                        </div>
                        <div class="form-group">
                            <label>Author Commission Rate (%)</label>
                            <input type="number" id="set-commission" min="10" max="90" value="${settings.authorCommission}" required>
                        </div>
                    </div>

                    <div class="settings-group">
                        <h4>System State</h4>
                        
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <span>Maintenance Mode</span>
                                <small>Disables public access and displays an under-maintenance screen.</small>
                            </div>
                            <label class="switch">
                                <input type="checkbox" id="set-maintenance" ${settings.maintenanceMode ? 'checked' : ''}>
                                <span class="slider"></span>
                            </label>
                        </div>

                        <div class="toggle-row" style="margin-top: 15px;">
                            <div class="toggle-info">
                                <span>Allow New Registrations</span>
                                <small>Toggle whether new users can create accounts.</small>
                            </div>
                            <label class="switch">
                                <input type="checkbox" id="set-register" ${settings.allowNewRegistrations ? 'checked' : ''}>
                                <span class="slider"></span>
                            </label>
                        </div>
                    </div>

                    <button type="submit" class="btn-save">Save Settings</button>
                </form>
            </div>
        `;

        // Handle settings save
        document.getElementById('settings-form').addEventListener('submit', (e) => {
            e.preventDefault();
            const newSettings = {
                platformName: document.getElementById('set-name').value,
                authorCommission: document.getElementById('set-commission').value,
                maintenanceMode: document.getElementById('set-maintenance').checked,
                allowNewRegistrations: document.getElementById('set-register').checked,
            };
            
            localStorage.setItem('srishty_settings', JSON.stringify(newSettings));
            alert('Settings successfully saved!');
        });
    }

    async loadCategoriesView() {
        const container = document.getElementById('view-container');
        container.innerHTML = `
            <div class="glass section-card animate-slide-up">
                <div class="section-header">
                    <h3>Platform Categories</h3>
                    <button class="btn-action blue" onclick="adminApp.showCategoryModal()">+ Add New Category</button>
                </div>
                <div class="table-container">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Slug</th>
                                <th>Default Mood</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody id="categories-list-target">
                            <tr><td colspan="4">Loading categories...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <div id="category-modal" class="modal hidden">
                <div class="modal-content glass animate-slide-up">
                    <h4 id="category-modal-title">Add New Category</h4>
                    <form id="category-form">
                        <input type="hidden" id="category-id">
                        <div class="form-group">
                            <label>Category Name</label>
                            <input type="text" id="category-name" placeholder="e.g. Science Fiction" required>
                        </div>
                        <div class="form-group">
                            <label>Slug (URL handle)</label>
                            <input type="text" id="category-slug" placeholder="e.g. sci-fi" required>
                        </div>
                        <div class="form-group">
                            <label>Default Ambient Sound (Mood)</label>
                            <select id="category-sound">
                                <option value="">No Default Mood</option>
                            </select>
                        </div>
                        <div class="modal-actions">
                            <button type="button" class="btn-action" onclick="adminApp.hideCategoryModal()">Cancel</button>
                            <button type="submit" class="btn-action blue" id="btn-save-category">Save Category</button>
                        </div>
                    </form>
                </div>
            </div>
        `;

        try {
            const [categoriesData, sounds] = await Promise.all([
                this.fetchWithAuth(`${API_BASE_URL}/core/categories/`),
                this.fetchWithAuth(`${API_BASE_URL}/core/ambient-sounds/`)
            ]);

            const categories = categoriesData.results || categoriesData;

            const soundSelect = document.getElementById('category-sound');
            const systemSounds = sounds.filter(s => s.is_system);
            soundSelect.innerHTML += systemSounds.map(s => `<option value="${s.id}">${s.emoji} ${s.name}</option>`).join('');

            const target = document.getElementById('categories-list-target');
            target.innerHTML = categories.map(cat => `
                <tr>
                    <td><strong>${cat.name}</strong></td>
                    <td><code>${cat.slug}</code></td>
                    <td>${cat.recommended_mood_emoji || '🎵'} ${cat.recommended_mood_name || 'None'}</td>
                    <td>
                        <button class="btn-action orange" onclick="adminApp.editCategory('${cat.slug}')">Edit</button>
                        <button class="btn-action red" onclick="adminApp.deleteCategory('${cat.slug}')">Delete</button>
                    </td>
                </tr>
            `).join('');

            document.getElementById('category-form').addEventListener('submit', (e) => this.handleCategorySubmit(e));

        } catch (e) {
            console.error(e);
        }
    }

    showCategoryModal() {
        document.getElementById('category-modal-title').textContent = 'Add New Category';
        document.getElementById('category-form').reset();
        document.getElementById('category-id').value = '';
        document.getElementById('category-modal').classList.remove('hidden');
    }

    hideCategoryModal() {
        document.getElementById('category-modal').classList.add('hidden');
    }

    async handleCategorySubmit(e) {
        e.preventDefault();
        const id = document.getElementById('category-id').value;
        const name = document.getElementById('category-name').value;
        const slug = document.getElementById('category-slug').value;
        const soundId = document.getElementById('category-sound').value;

        const data = { name, slug, recommended_ambient_sound: soundId || null };
        const method = id ? 'PATCH' : 'POST';
        const url = id ? `${API_BASE_URL}/core/categories/${id}/` : `${API_BASE_URL}/core/categories/`;

        try {
            const res = await this.fetchWithAuth(url, {
                method,
                body: JSON.stringify(data)
            });
            if (res) {
                this.hideCategoryModal();
                this.loadCategoriesView();
            }
        } catch (error) {
            console.error('Category save failed:', error);
        }
    }

    async editCategory(slug) {
        try {
            const cat = await this.fetchWithAuth(`${API_BASE_URL}/core/categories/${slug}/`);
            document.getElementById('category-modal-title').textContent = 'Edit Category';
            document.getElementById('category-id').value = cat.slug; // Using slug as lookup
            document.getElementById('category-name').value = cat.name;
            document.getElementById('category-slug').value = cat.slug;
            document.getElementById('category-sound').value = cat.recommended_ambient_sound || '';
            document.getElementById('category-modal').classList.remove('hidden');
        } catch (e) {
            console.error(e);
        }
    }

    async deleteCategory(slug) {
        if (!confirm('Are you sure? All books in this category will lose their genre association.')) return;
        try {
            const res = await fetch(`${API_BASE_URL}/core/categories/${slug}/`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${this.token}` }
            });
            if (res.ok) this.loadCategoriesView();
        } catch (e) {
            console.error(e);
        }
    }

    async loadSoundsView() {
        const container = document.getElementById('view-container');
        container.innerHTML = `
            <div class="glass section-card animate-slide-up">
                <div class="section-header">
                    <h3>Official Platform Sounds</h3>
                    <button class="btn-action blue" onclick="adminApp.showSoundModal()">+ Add New Sound</button>
                </div>
                <div class="table-container">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Icon</th>
                                <th>Name</th>
                                <th>Type</th>
                                <th>Preview</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody id="sounds-list-target">
                            <tr><td colspan="5">Loading sounds...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <div id="sound-modal" class="modal hidden">
                <div class="modal-content glass animate-slide-up">
                    <h4>Add New Ambient Sound</h4>
                    <form id="sound-form">
                        <div class="form-group">
                            <label>Sound Name</label>
                            <input type="text" id="sound-name" placeholder="e.g. Heavy Rain" required>
                        </div>
                        <div class="form-group">
                            <label>Emoji Icon</label>
                            <input type="text" id="sound-emoji" placeholder="e.g. 🌧️" required>
                        </div>
                        <div class="form-group">
                            <label>Audio File</label>
                            <input type="file" id="sound-file" accept="audio/*" required>
                        </div>
                        <div class="modal-actions">
                            <button type="button" class="btn-action" onclick="adminApp.hideSoundModal()">Cancel</button>
                            <button type="submit" class="btn-action blue" id="btn-upload-sound">Upload Sound</button>
                        </div>
                    </form>
                </div>
            </div>
        `;

        try {
            const data = await this.fetchWithAuth(`${API_BASE_URL}/core/ambient-sounds/`);
            const target = document.getElementById('sounds-list-target');
            
            // Show only system sounds for management
            const systemSounds = data.filter(s => s.is_system);
            
            target.innerHTML = systemSounds.map(sound => `
                <tr>
                    <td style="font-size: 24px;">${sound.emoji}</td>
                    <td>${sound.name}</td>
                    <td><span class="status-badge active">System</span></td>
                    <td>
                        <audio controls style="height: 30px; width: 220px;">
                            <source src="${sound.audio_url}" type="audio/mpeg">
                        </audio>
                    </td>
                    <td>
                        <button class="btn-action red" onclick="adminApp.deleteSound(${sound.id})">Delete</button>
                    </td>
                </tr>
            `).join('');

            document.getElementById('sound-form').addEventListener('submit', (e) => this.handleSoundUpload(e));

        } catch (e) {
            console.error(e);
        }
    }

    showSoundModal() {
        document.getElementById('sound-modal').classList.remove('hidden');
    }

    hideSoundModal() {
        document.getElementById('sound-modal').classList.add('hidden');
    }

    async handleSoundUpload(e) {
        e.preventDefault();
        const btn = document.getElementById('btn-upload-sound');
        btn.disabled = true;
        btn.textContent = 'Uploading...';

        const name = document.getElementById('sound-name').value;
        const emoji = document.getElementById('sound-emoji').value;
        const file = document.getElementById('sound-file').files[0];

        const formData = new FormData();
        formData.append('name', name);
        formData.append('emoji', emoji);
        formData.append('audio_file', file);
        formData.append('is_system', 'true');

        try {
            const response = await fetch(`${API_BASE_URL}/core/ambient-sounds/`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.token}`
                },
                body: formData
            });

            if (response.ok) {
                this.hideSoundModal();
                this.loadSoundsView();
            } else {
                alert('Upload failed. Please check the file format.');
            }
        } catch (error) {
            console.error('Upload error:', error);
        } finally {
            btn.disabled = false;
            btn.textContent = 'Upload Sound';
        }
    }

    async deleteSound(id) {
        if (!confirm('Are you sure you want to delete this sound? Authors will no longer be able to use it.')) return;
        
        try {
            const res = await fetch(`${API_BASE_URL}/core/ambient-sounds/${id}/`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${this.token}`
                }
            });
            if (res.ok) {
                this.loadSoundsView();
            }
        } catch (error) {
            console.error('Delete failed:', error);
        }
    }
}

const adminApp = new AdminApp();
