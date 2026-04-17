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
                    window.location.href = 'index.html';
                    return;
                }
                this.initEditor();
                this.loadCategories().then(() => {
                    const activeBookJSON = localStorage.getItem('activeStudioBook');
                    if (activeBookJSON && activeBookJSON !== 'null') {
                        try {
                            const book = JSON.parse(activeBookJSON);
                            this.resumeBook(book);
                        } catch (e) {
                            this.startNewBook();
                        }
                    } else {
                        this.startNewBook();
                    }
                });
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
        
        const navBar = document.getElementById('studio-nav-bar');
        navBar.classList.remove('hidden');
        
        const navItem = document.getElementById(`step-nav-${step}`);
        if (navItem) navItem.classList.add('active');

        const section = document.getElementById(`step-${step}`);
        if (section) section.classList.add('active');

        if (step === 3) {
            this.renderAudioChapters();
        }
    }



    startNewBook() {
        // Reset state for new book
        this.bookId = null;
        this.chaptersData = [];
        document.getElementById('book-title').value = '';
        document.getElementById('book-desc').value = '';
        document.getElementById('book-category').value = '';
        document.getElementById('cover-preview').src = '';
        document.getElementById('cover-preview').style.display = 'none';
        document.getElementById('cover-placeholder').style.display = 'flex';
        
        this.goToStep(1);
    }

    resumeBook(book) {
        this.bookId = book.id;
        this.chaptersData = book.chapters || [];
        
        // Fill details in Step 1 just in case they go back
        document.getElementById('book-title').value = book.title;
        document.getElementById('book-desc').value = book.description || '';
        document.getElementById('book-category').value = book.category || '';
        if (book.cover) {
            const preview = document.getElementById('cover-preview');
            preview.src = book.cover;
            preview.style.display = 'block';
            document.getElementById('cover-placeholder').style.display = 'none';
        }

        document.getElementById('summary-title').textContent = book.title;

        // If it already has chapters, we could potentially try to reload them 
        // into the editor, but for now we'll go to the "Editor" step to allow additions.
        this.goToStep(1);
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

    async handlePdfUpload(e) {
        const file = e.target.files[0];
        if (!file || !this.bookId) return;

        alert('Importing PDF Document... this may take a moment.');
        
        const formData = new FormData();
        formData.append('file', file);

        try {
            const data = await window.readerApp.fetchAPI('/core/books/convert_pdf/', {
                method: 'POST',
                body: formData
            });

            if (data && data.html) {
                this.quill.clipboard.dangerouslyPasteHTML(data.html);
                alert('Import successful! Text has been extracted from your PDF.');
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
                this.goToStep(3); // Go to Audio Step
            } else {
                throw new Error('Unexpected response format');
            }
        } catch (err) {
            alert('Failed to split chapters: ' + err.message);
        } finally {
            btn.disabled = false;
            btn.textContent = 'Next: Audio Studio';
        }
    }

    renderAudioChapters() {
        const container = document.getElementById('audio-chapters-list');
        if (!this.chaptersData || this.chaptersData.length === 0) {
            container.innerHTML = '<div style="text-align: center; padding: 20px;">No chapters found to attach audio to.</div>';
            return;
        }

        container.innerHTML = this.chaptersData.map((ch, idx) => `
            <div class="audio-row" id="audio-row-${idx + 1}">
                <div class="audio-info">
                    <span class="chapter-name">Chapter ${idx + 1}: ${ch.title}</span>
                    <span class="upload-status" id="status-${idx + 1}">Ready to upload</span>
                </div>
                <div class="audio-actions">
                    <div class="audio-progress-bar" id="progress-bar-${idx + 1}">
                        <div class="audio-progress-fill" id="progress-fill-${idx + 1}"></div>
                    </div>
                    <input type="file" id="audio-input-${idx + 1}" accept="audio/*" style="display: none;" 
                           onchange="studioApp.handleAudioUpload(${idx + 1}, event)">
                    <button class="btn-primary" onclick="document.getElementById('audio-input-${idx + 1}').click()">
                        Upload Audio
                    </button>
                </div>
            </div>
        `).join('');
    }

    async handleAudioUpload(chapterNumber, event) {
        const file = event.target.files[0];
        if (!file) return;

        const statusEl = document.getElementById(`status-${chapterNumber}`);
        const progressContainer = document.getElementById(`progress-bar-${chapterNumber}`);
        const progressFill = document.getElementById(`progress-fill-${chapterNumber}`);
        const row = document.getElementById(`audio-row-${chapterNumber}`);

        statusEl.textContent = 'Uploading...';
        statusEl.className = 'upload-status';
        progressContainer.style.display = 'block';
        progressFill.style.width = '0%';

        const formData = new FormData();
        formData.append('audio_file', file);
        formData.append('chapter_number', chapterNumber);

        try {
            // Using a simple fetch for progress tracking or just wait
            const response = await window.readerApp.fetchAPI(`/core/books/${this.bookId}/upload_audio/`, {
                method: 'POST',
                body: formData
            });

            if (response && response.status === 'audio uploaded') {
                statusEl.textContent = '✓ Audio Uploaded Successfully';
                statusEl.classList.add('success');
                progressFill.style.width = '100%';
                setTimeout(() => { progressContainer.style.display = 'none'; }, 2000);
            } else {
                throw new Error(response.error || 'Upload failed');
            }
        } catch (err) {
            statusEl.textContent = '⚠ ' + err.message;
            statusEl.classList.add('error');
            progressFill.style.width = '0%';
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
