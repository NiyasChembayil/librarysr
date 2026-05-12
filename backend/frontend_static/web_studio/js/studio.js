const API_BASE_URL = 'https://srishty-backend.onrender.com/api';

class SrishtyStudio {
    constructor() {
        this.token = localStorage.getItem('access_token');
        this.activeBook = null;
        this.activeChapter = null;
        this.chapters = [];
        this.quill = null;
        this.init();
    }

    async init() {
        if (!this.token) {
            window.location.href = '/welcome/';
            return;
        }

        this.initEditor();
        this.loadDashboard();
        this.loadCategories();
    }

    initEditor() {
        this.quill = new Quill('#editor', {
            theme: 'snow',
            placeholder: 'Start your story here...',
            modules: {
                toolbar: [
                    [{ 'header': [2, 3, false] }],
                    ['bold', 'italic', 'underline'],
                    [{ 'list': 'ordered'}, { 'list': 'bullet' }],
                    ['clean']
                ]
            }
        });

        this.quill.on('text-change', () => {
            this.updateWordCount();
        });
    }

    updateWordCount() {
        const text = this.quill.getText();
        const words = text.split(/\s+/).filter(w => w.length > 0).length;
        document.getElementById('word-count').innerText = `${words} words`;
    }

    async fetchAPI(endpoint, options = {}) {
        const headers = {
            'Authorization': `Bearer ${this.token}`,
            ...options.headers
        };

        if (!(options.body instanceof FormData)) {
            headers['Content-Type'] = 'application/json';
        }

        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers
        });

        if (response.status === 401) {
            this.logout();
            return null;
        }

        return await response.json();
    }

    logout() {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/welcome/';
    }

    showView(viewId) {
        document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
        document.getElementById(`view-${viewId}`).classList.remove('hidden');
        window.scrollTo(0, 0);
    }

    async loadDashboard() {
        const stats = await this.fetchAPI('/core/books/author_stats/');
        if (stats) {
            // Stability Fix: Add null checks to prevent crashes if IDs are missing
            const updateStat = (id, value) => {
                const el = document.getElementById(id);
                if (el) el.innerText = value;
            };

            updateStat('stat-total-reads', (stats.total_reads || 0).toLocaleString());
            updateStat('stat-total-followers', (stats.followers_count || 0).toLocaleString());
            updateStat('stat-total-published', (stats.published_count || 0).toLocaleString());
            updateStat('stat-streak', `${stats.writing_streak || 0}d`);
            
            const welcomeEl = document.getElementById('dashboard-welcome');
            if (welcomeEl) {
                const username = stats.username || localStorage.getItem('username') || 'Author';
                welcomeEl.innerText = `Welcome back, ${username}`;
            }
        }

        const books = await this.fetchAPI('/core/books/my_books/');
        if (books) {
            this.renderBooks(books);
        }
    }

    renderBooks(books) {
        const grid = document.getElementById('my-books-grid');
        grid.innerHTML = books.map(book => `
            <div class="glass animate-up" style="padding: 15px; cursor: pointer;" onclick="studioApp.openBook(${JSON.stringify(book).replace(/"/g, '&quot;')})">
                <img src="${book.cover || '/static/assets/logo.png'}" style="width: 100%; height: 200px; object-fit: cover; border-radius: 12px; margin-bottom: 15px;" loading="lazy">
                <h3 style="font-size: 16px; margin-bottom: 5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${book.title}</h3>
                <div style="display: flex; justify-content: space-between; font-size: 12px; color: var(--text-secondary);">
                    <span>${book.category_name}</span>
                    <span>${book.is_published ? '✅ Published' : '⏳ Draft'}</span>
                </div>
            </div>
        `).join('');
    }

    async loadCategories() {
        const data = await this.fetchAPI('/core/categories/');
        if (data && data.results) {
            const select = document.getElementById('book-category');
            select.innerHTML = '<option value="">Select Genre</option>' + 
                data.results.map(c => `<option value="${c.id}">${c.name}</option>`).join('');
        }
    }

    handleCoverPreview(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                const img = document.getElementById('cover-preview-img');
                img.src = e.target.result;
                document.getElementById('cover-upload-box').classList.add('active');
            };
            reader.readAsDataURL(file);
        }
    }

    async createBook() {
        const title = document.getElementById('book-title').value;
        const category = document.getElementById('book-category').value;
        const description = document.getElementById('book-description').value;
        const cover = document.getElementById('book-cover-input').files[0];

        if (!title || !category) {
            alert('Please fill in at least the title and category.');
            return;
        }

        const formData = new FormData();
        formData.append('title', title);
        formData.append('category', category);
        formData.append('description', description);
        if (cover) formData.append('cover', cover);

        const result = await this.fetchAPI('/core/books/', {
            method: 'POST',
            body: formData
        });

        if (result && result.id) {
            this.openBook(result);
        }
    }

    async openBook(book) {
        this.activeBook = book;
        document.getElementById('active-book-title').innerText = book.title;
        this.showView('chapters');
        this.loadChapters();
    }

    async loadChapters() {
        const data = await this.fetchAPI(`/core/books/${this.activeBook.id}/chapters/`);
        if (data) {
            this.chapters = Array.isArray(data) ? data : (data.results || []);
            this.renderChapters();
        }
    }

    renderChapters() {
        const container = document.getElementById('chapters-container');
        const empty = document.getElementById('empty-chapters');
        const count = document.getElementById('chapter-count');

        count.innerText = `${this.chapters.length} Total`;

        if (this.chapters.length === 0) {
            container.innerHTML = '';
            empty.classList.remove('hidden');
        } else {
            empty.classList.add('hidden');
            container.innerHTML = this.chapters.map((ch, i) => `
                <div class="glass chapter-list-item animate-up" onclick="studioApp.editChapter(${JSON.stringify(ch).replace(/"/g, '&quot;')})">
                    <div>
                        <h4 style="margin-bottom: 5px;">${i + 1}. ${ch.title}</h4>
                        <p style="font-size: 12px; color: var(--text-secondary);">${ch.audio_file ? '✅ Audio attached' : '⏳ No audio'}</p>
                    </div>
                    <i class="fas fa-chevron-right" style="opacity: 0.3;"></i>
                </div>
            `).join('');
        }
    }

    async addNewChapter() {
        const order = this.chapters.length;
        const result = await this.fetchAPI(`/core/books/${this.activeBook.id}/chapters/`, {
            method: 'POST',
            body: JSON.stringify({
                title: `Chapter ${order + 1}`,
                content: JSON.stringify({ops: [{insert: "\n"}]}),
                order: order
            })
        });

        if (result) {
            this.editChapter(result);
        }
    }

    editChapter(chapter) {
        this.activeChapter = chapter;
        document.getElementById('chapter-title-input').value = chapter.title;
        document.getElementById('editor-title').innerText = chapter.title;
        
        try {
            const content = JSON.parse(chapter.content);
            this.quill.setContents(content);
        } catch (e) {
            this.quill.setText(chapter.content || '');
        }

        this.showView('editor');
    }

    async saveChapter() {
        const title = document.getElementById('chapter-title-input').value;
        const content = JSON.stringify(this.quill.getContents());

        const result = await this.fetchAPI(`/core/books/${this.activeBook.id}/chapters/${this.activeChapter.id}/`, {
            method: 'PATCH',
            body: JSON.stringify({
                title: title,
                content: content
            })
        });

        if (result) {
            alert('Chapter saved successfully!');
            this.loadChapters();
            this.showView('chapters');
        }
    }

    async publishBook() {
        const result = await this.fetchAPI(`/core/books/${this.activeBook.id}/`, {
            method: 'PATCH',
            body: JSON.stringify({ is_published: true })
        });

        if (result) {
            alert('Congratulations! Your story is now live on Srishty.');
            this.loadDashboard();
            this.showView('dashboard');
        }
    }

    async deleteBook() {
        if (confirm('Are you sure you want to delete this masterpiece? This action cannot be undone.')) {
            const response = await fetch(`${API_BASE_URL}/core/books/${this.activeBook.id}/`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${this.token}` }
            });

            if (response.ok) {
                this.loadDashboard();
                this.showView('dashboard');
            }
        }
    }
}

const studioApp = new SrishtyStudio();
