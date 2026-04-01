const API_BASE_URL = '/api';

class SrishtyReaderApp {
    constructor() {
        this.categories = [];
        this.init();
    }

    init() {
        this.detectLocation();
        this.bindEvents();
        this.loadTrendingBooks();
        this.loadCategories().then(() => {
            // Load the first category or default 'sci-fi'
            if (this.categories.length > 0) {
                const defaultCat = this.categories.find(c => c.slug === 'sci-fi') || this.categories[0];
                this.loadCategoryBooks(defaultCat.slug);
            }
        });
    }

    detectLocation() {
        // Mocking location based on timezone strictly for UI personalization
        const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
        let region = "Global";
        if (tz.includes('America')) region = "North America";
        else if (tz.includes('Europe')) region = "Europe";
        else if (tz.includes('Asia')) region = "Asia Region";
        
        this.userRegion = region;
        
        document.getElementById('user-location').innerHTML = `📍 Trending in ${region}`;
        document.getElementById('local-trend-indicator').textContent = `in ${region}`;
    }

    bindEvents() {
        // Setup category tab clicks dynamically
        const tabContainer = document.querySelector('.category-tabs');
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

    async fetchAPI(endpoint) {
        try {
            const response = await fetch(`${API_BASE_URL}${endpoint}`);
            if (!response.ok) throw new Error('Network response was not ok');
            return await response.json();
        } catch (error) {
            console.error(`API Error on ${endpoint}:`, error);
            return null;
        }
    }

    createBookCardHTML(book) {
        // Fallback for missing cover
        const coverHtml = book.cover 
            ? `<img src="${book.cover}" alt="${book.title} cover" class="book-cover">`
            : `<div class="book-cover placeholder-cover">📖</div>`;
            
        return `
            <article class="book-card" onclick="alert('Opening reading view for: ${book.title}')">
                ${coverHtml}
                <div class="book-title" title="${book.title}">${book.title}</div>
                <div class="book-author">by ${book.author_name || 'Unknown'}</div>
            </article>
        `;
    }

    async loadTrendingBooks() {
        const container = document.getElementById('trending-carousel');
        const queryParams = this.userRegion && this.userRegion !== "Global" ? `?region=${encodeURIComponent(this.userRegion)}` : '';
        const data = await this.fetchAPI(`/core/books/trending/${queryParams}`);
        
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
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
    window.readerApp = new SrishtyReaderApp();
});
