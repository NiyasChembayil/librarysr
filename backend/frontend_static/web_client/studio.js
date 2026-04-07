class StudioApp {
    constructor() {
        this.quill = null;
        this.bookId = null;
        this.chaptersData = [];
        this.init();
    }

    init() {
        // Wait for app.js to fully initialize window.readerApp
        const waitForApp = setInterval(() => {
            if (window.readerApp) {
                clearInterval(waitForApp);
                if (!window.readerApp.token) {
                    alert('You must be logged in to access the Author Studio.');
                    window.location.href = '/index.html';
                    return;
                }
                this.initEditor();
                this.loadCategories();
            }
        }, 50);
    }

    initEditor() {
        this.quill = new Quill('#editor', {
            theme: 'snow',
            placeholder: 'Start writing your story here...',
            modules: {
                toolbar: [
                    [{ 'header': [1, 2, false] }],
                    ['bold', 'italic', 'underline'],
                    [{ 'list': 'ordered'}, { 'list': 'bullet' }],
                    ['clean']
                ]
            }
        });
    }

    async loadCategories() {
        const select = document.getElementById('book-category');
        try {
            // Use the established fetchAPI from app.js for consistency
            const data = await window.readerApp.fetchAPI('/core/categories/');
            
            if (data && data.results && data.results.length > 0) {
                select.innerHTML = '<option value="">Select a category</option>' + 
                    data.results.map(c => `<option value="${c.id}">${c.name}</option>`).join('');
            } else {
                select.innerHTML = '<option value="">No categories found</option>';
            }
        } catch (err) {
            console.error('Failed to load categories:', err);
            select.innerHTML = '<option value="">Error loading categories</option>';
        }
    }

    goToStep(step) {
        document.querySelectorAll('.studio-section').forEach(el => el.classList.remove('active'));
        document.querySelectorAll('.step').forEach(el => el.classList.remove('active'));
        
        document.getElementById(`step-${step}`).classList.add('active');
        document.getElementById(`step-nav-${step}`).classList.add('active');
    }

    handleCoverPreview(event) {
        const file = event.target.files[0];
        const preview = document.getElementById('cover-preview');
        const placeholder = document.getElementById('cover-placeholder');
        
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                preview.src = e.target.result;
                preview.style.display = 'block';
                placeholder.style.display = 'none';
            };
            reader.readAsDataURL(file);
        } else {
            preview.src = '';
            preview.style.display = 'none';
            placeholder.style.display = 'flex';
        }
    }

    handleAuthorPreview(event) {
        const file = event.target.files[0];
        const preview = document.getElementById('author-preview');
        const placeholder = document.getElementById('author-placeholder');
        
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                preview.src = e.target.result;
                preview.style.display = 'block';
                placeholder.style.display = 'none';
            };
            reader.readAsDataURL(file);
        } else {
            preview.src = '';
            preview.style.display = 'none';
            placeholder.style.display = 'flex';
        }
    }

    async createBook() {
        const title = document.getElementById('book-title').value;
        const categoryId = document.getElementById('book-category').value;
        const description = document.getElementById('book-desc').value;
        const btn = document.getElementById('btn-next-1');

        if (!title || !categoryId) {
            alert('Please fill out the Title and Category.');
            return;
        }

        btn.disabled = true;
        btn.textContent = 'Creating...';

        try {
            // 1. Sync Author Photo if provided
            const authorPhotoFile = document.getElementById('author-photo').files[0];
            if (authorPhotoFile) {
                const profileData = new FormData();
                profileData.append('avatar', authorPhotoFile);
                await window.readerApp.fetchAPI('/accounts/profile/me/', {
                    method: 'PATCH',
                    body: profileData
                });
            }

            // 2. Create Book with Cover
            const formData = new FormData();
            formData.append('title', title);
            formData.append('description', description);
            formData.append('category', categoryId);
            formData.append('price', '0.0');
            formData.append('is_published', 'false');

            const coverFile = document.getElementById('book-cover').files[0];
            if (coverFile) {
                formData.append('cover', coverFile);
            }

            const data = await window.readerApp.fetchAPI('/core/books/', {
                method: 'POST',
                body: formData
            });

            if (data && data.id) {
                this.bookId = data.id;
                document.getElementById('summary-title').textContent = title;
                this.goToStep(2);
            } else {
                throw new Error('Could not read book ID from response');
            }
        } catch (e) {
            alert('Failed to create book record. ' + e.message);
        } finally {
            btn.disabled = false;
            btn.textContent = 'Next: Write Story';
        }
    }

    async handleDocxUpload(e) {
        const file = e.target.files[0];
        if (!file || !this.bookId) return;

        alert('Importing Word Document... this may take a moment.');
        
        const formData = new FormData();
        formData.append('file', file);

        try {
            const data = await window.readerApp.fetchAPI('/core/books/convert_docx/', {
                method: 'POST',
                body: formData
            });

            if (data && data.html) {
                this.quill.clipboard.dangerouslyPasteHTML(data.html);
                alert('Import successful! You can now adjust headers if needed.');
            }
        } catch (err) {
            alert('Import failed: ' + err.message);
        }
    }

    async processChapters() {
        if (!this.bookId) return;
        const btn = document.getElementById('btn-next-2');
        btn.disabled = true;
        btn.textContent = 'Processing...';

        const contents = this.quill.getContents();
        let currentTitle = '';
        let currentContentDelta = [];
        let chaptersToImport = [];

        for (let i = 0; i < contents.ops.length; i++) {
            const op = contents.ops[i];
            
            if (typeof op.insert === 'string' && op.attributes && op.attributes.header === 1) {
                if (currentTitle || currentContentDelta.length > 0) {
                    chaptersToImport.push({
                        title: currentTitle || 'Untitled Chapter',
                        content: JSON.stringify(currentContentDelta)
                    });
                }
                currentTitle = op.insert.trim().replace(/\n/g, '');
                currentContentDelta = [];
            } else {
                if (currentTitle || (typeof op.insert === 'string' && op.insert.trim())) {
                    if (!currentTitle && chaptersToImport.length === 0) {
                        currentTitle = "Introduction";
                    }
                    currentContentDelta.push(op);
                } else if (typeof op.insert !== 'string') {
                    currentContentDelta.push(op);
                }
            }
        }

        if (currentTitle || currentContentDelta.length > 0) {
            chaptersToImport.push({
                title: currentTitle || 'Untitled Chapter',
                content: JSON.stringify(currentContentDelta)
            });
        }

        if (chaptersToImport.length === 0) {
            alert('No chapters found. Make sure to type some text.');
            btn.disabled = false;
            btn.textContent = 'Process Chapters & Next';
            return;
        }

        try {
            const res = await window.readerApp.fetchAPI(`/core/books/${this.bookId}/import_chapters/`, {
                method: 'POST',
                body: JSON.stringify({ chapters: chaptersToImport })
            });

            if (res && res.status === 'chapters imported') {
                this.chaptersData = res.chapters;
                document.getElementById('summary-chapters').textContent = this.chaptersData.length;
                this.goToStep(3);
            } else {
                throw new Error('Unexpected response format');
            }
        } catch (err) {
            alert('Failed to split chapters: ' + err.message);
        } finally {
            btn.disabled = false;
            btn.textContent = 'Process Chapters & Next';
        }
    }

    async publishBook() {
        if (!this.bookId) return;
        const btn = document.getElementById('btn-publish');
        btn.disabled = true;
        btn.textContent = 'Publishing...';
        
        try {
            await window.readerApp.fetchAPI(`/core/books/${this.bookId}/`, {
                method: 'PATCH',
                body: JSON.stringify({ is_published: true })
            });
            
            alert('Congratulations! Your story is now live on Srishty! You can now find it in the Discovery gallery under its genre.');
            window.location.href = 'index.html';
        } catch (err) {
            alert('Failed to publish: ' + err.message);
            btn.disabled = false;
            btn.textContent = 'Publish to Srishty!';
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    window.studioApp = new StudioApp();
});
