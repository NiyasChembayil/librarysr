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

class StudioApp {
    constructor() {
        this.quill = null;
        this.bookId = null;
        this.chapters = []; 
        this.currentChapterId = null;
        this.autosaveTimer = null;
        this.init();
    }

    init() {
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
                    this.checkExistingSession();
                });
            }
        }, 50);
    }

    initEditor() {
        this.quill = new Quill('#editor', {
            theme: 'snow',
            placeholder: 'Start writing your page here...',
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
            // Update local content immediately so word count and switching works
            const chapter = this.chapters.find(ch => ch.id === this.currentChapterId);
            if (chapter) {
                chapter.content = JSON.stringify(this.quill.getContents());
            }
            
            this.triggerAutosave();
            this.updateTotalWordCount();
        });
    }

    async loadCategories() {
        const select = document.getElementById('book-category');
        try {
            const data = await window.readerApp.fetchAPI('/core/categories/');
            if (data && data.results) {
                select.innerHTML = '<option value="">Select a category</option>' + 
                    data.results.map(c => `<option value="${c.id}">${escapeHTML(c.name)}</option>`).join('');
            }
        } catch (err) { console.error(err); }
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

        if (step === 2) {
            if (this.chapters.length === 0) {
                this.addNewChapter();
            } else if (!this.currentChapterId) {
                this.loadChapterContent(this.chapters[0].id);
            }
        }
        if (step === 3) {
            this.loadAudioStep();
        }
    }

    checkExistingSession() {
        const saved = localStorage.getItem('activeStudioBook');
        if (saved) {
            const book = JSON.parse(saved);
            this.bookId = book.id;
            
            // Populate Step 1 fields
            document.getElementById('book-title').value = book.title || '';
            document.getElementById('book-desc').value = book.description || '';
            document.getElementById('book-category').value = book.category || '';
            
            if (book.cover) {
                const preview = document.getElementById('cover-preview');
                const placeholder = document.getElementById('cover-placeholder');
                preview.src = book.cover;
                preview.classList.add('active');
                placeholder.classList.add('hidden');
            }

            // Load existing chapters
            this.loadChapters();
        } else {
            this.startNewBook();
        }
    }

    startNewBook() {
        this.bookId = null;
        this.chapters = []; 
        this.currentChapterId = null;
        this.goToStep(1);
    }

    handleCoverPreview(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                document.getElementById('cover-preview').src = e.target.result;
                document.getElementById('cover-preview').style.display = 'block';
                document.getElementById('cover-placeholder').style.display = 'none';
            };
            reader.readAsDataURL(file);
        }
    }

    async createBook() {
        const title = document.getElementById('book-title').value;
        const categoryId = document.getElementById('book-category').value;
        const description = document.getElementById('book-desc').value;

        if (!title || !categoryId) return alert('Fill required fields');

        const formData = new FormData();
        formData.append('title', title);
        formData.append('description', description);
        formData.append('category', categoryId);
        
        const coverFile = document.getElementById('book-cover').files[0];
        if (coverFile) formData.append('cover', coverFile);

        try {
            const data = await window.readerApp.fetchAPI('/core/books/', {
                method: 'POST',
                body: formData
            });

            if (data && data.id) {
                this.bookId = data.id;
                document.getElementById('summary-title').textContent = title;
                this.goToStep(2);
            }
        } catch (e) { alert(e.message); }
    }

    async loadChapters() {
        if (!this.bookId) return;
        try {
            const data = await window.readerApp.fetchAPI(`/core/books/${this.bookId}/chapters/`);
            if (data) {
                // If backend returns a list directly or a results object
                this.chapters = Array.isArray(data) ? data : (data.results || []);
                this.renderChaptersList();
                
                // If we are in Step 2, load the first chapter if nothing is selected
                const section = document.getElementById('step-2');
                if (section && section.classList.contains('active')) {
                    if (this.chapters.length > 0 && !this.currentChapterId) {
                        this.loadChapterContent(this.chapters[0].id);
                    }
                }
            }
        } catch (error) { console.error("Failed to load chapters", error); }
    }

    // --- Editor Logic ---

    async addNewChapter() {
        if (!this.bookId) return;
        
        try {
            const order = this.chapters.length;
            const newChapter = await window.readerApp.fetchAPI(`/core/books/${this.bookId}/chapters/`, {
                method: 'POST',
                body: JSON.stringify({
                    title: `Page ${order + 1}`,
                    content: JSON.stringify({ops: [{insert: "\n"}]}),
                    order: order
                })
            });

            if (newChapter) {
                this.chapters.push(newChapter);
                this.loadChapterContent(newChapter.id);
            }
        } catch (error) { console.error(error); }
    }

    renderChaptersList() {
        const list = document.getElementById('chapters-list');
        list.innerHTML = '';
        
        this.chapters.sort((a, b) => a.order - b.order).forEach((ch, index) => {
            const item = document.createElement('div');
            item.className = `chapter-nav-item glass ${ch.id === this.currentChapterId ? 'active' : ''}`;
            item.style.padding = '10px 12px';
            item.style.borderRadius = '8px';
            item.style.cursor = 'pointer';
            item.style.fontSize = '13px';
            item.style.display = 'flex';
            item.style.alignItems = 'center';
            item.style.gap = '10px';
            item.style.background = ch.id === this.currentChapterId ? 'rgba(0, 210, 255, 0.1)' : 'rgba(255,255,255,0.02)';
            
            const handle = document.createElement('span');
            handle.innerHTML = '⋮⋮';
            handle.style.opacity = '0.3';
            handle.style.cursor = 'grab';
            item.appendChild(handle);

            const title = document.createElement('span');
            title.innerText = `${index + 1}. ${escapeHTML(ch.title)}`;
            title.style.whiteSpace = 'nowrap';
            title.style.overflow = 'hidden';
            title.style.textOverflow = 'ellipsis';
            title.style.flexGrow = '1';
            item.appendChild(title);
            
            item.onclick = (e) => {
                if (e.target === handle) return;
                this.loadChapterContent(ch.id);
            };

            item.draggable = true;
            item.ondragstart = (e) => {
                e.dataTransfer.setData('text/plain', index);
                item.style.opacity = '0.5';
            };
            item.ondragend = () => item.style.opacity = '1';
            item.ondragover = (e) => e.preventDefault();
            item.ondrop = (e) => {
                e.preventDefault();
                const fromIndex = parseInt(e.dataTransfer.getData('text/plain'));
                this.reorderChapters(fromIndex, index);
            };

            list.appendChild(item);
        });
        this.updateTotalWordCount();
    }

    async reorderChapters(fromIndex, toIndex) {
        if (fromIndex === toIndex) return;
        const movedChapter = this.chapters.splice(fromIndex, 1)[0];
        this.chapters.splice(toIndex, 0, movedChapter);
        this.chapters.forEach((ch, i) => ch.order = i);
        this.renderChaptersList();

        try {
            await window.readerApp.fetchAPI(`/core/books/${this.bookId}/chapters/${movedChapter.id}/`, {
                method: 'PATCH',
                body: JSON.stringify({ order: toIndex })
            });
        } catch (e) { console.error(e); }
    }

    async loadChapterContent(id) {
        if (id === this.currentChapterId) return;

        // Force a save of the current chapter before switching
        if (this.currentChapterId && !this._isLoading) {
            if (this.autosaveTimer) {
                clearTimeout(this.autosaveTimer);
                await this.saveCurrentChapterSync();
            }
        }

        this._isLoading = true; // Block autosave during load
        this.currentChapterId = id;
        const chapter = this.chapters.find(ch => ch.id === id);
        if (!chapter) return;

        document.getElementById('current-chapter-title').value = chapter.title;
        try {
            const content = JSON.parse(chapter.content);
            this.quill.setContents(content);
        } catch (e) { this.quill.setText(chapter.content || ''); }

        this.renderChaptersList();
        this.loadNotes();
        this.updateTotalWordCount();
        
        // Brief delay before re-enabling autosave
        setTimeout(() => { this._isLoading = false; }, 200);
    }

    handleTitleChange() {
        const title = document.getElementById('current-chapter-title').value;
        const chapter = this.chapters.find(ch => ch.id === this.currentChapterId);
        if (chapter) {
            chapter.title = title;
            this.triggerAutosave();
        }
    }

    triggerAutosave() {
        if (this._isLoading) return; // Don't save while we are loading a page
        
        const status = document.getElementById('autosave-status');
        status.innerText = 'Saving...';
        if (this.autosaveTimer) clearTimeout(this.autosaveTimer);
        this.autosaveTimer = setTimeout(() => this.saveCurrentChapterSync(), 2000);
    }

    async saveCurrentChapterSync() {
        const status = document.getElementById('autosave-status');
        const chapter = this.chapters.find(ch => ch.id === this.currentChapterId);
        if (!chapter) return;

        const content = JSON.stringify(this.quill.getContents());
        
        try {
            await window.readerApp.fetchAPI(`/core/books/${this.bookId}/chapters/${this.currentChapterId}/`, {
                method: 'PATCH',
                body: JSON.stringify({
                    title: chapter.title,
                    content: content
                })
            });
            status.innerText = '✓ Saved';
            chapter.content = content; // Ensure local state is synced
            this.renderChaptersList(); // Update list (handles titles)
        } catch (e) { 
            status.innerText = '⚠️ Error'; 
            console.error("Save failed", e);
        }
    }

    // --- New Features ---

    updateTotalWordCount() {
        let total = 0;
        this.chapters.forEach(ch => {
            let text = "";
            if (ch.id === this.currentChapterId) {
                text = this.quill.getText();
            } else {
                try {
                    const delta = JSON.parse(ch.content);
                    text = delta.ops.map(op => op.insert || '').join('');
                } catch (e) { text = ch.content || ""; }
            }
            total += text.split(/\s+/).filter(w => w.length > 0).length;
        });
        document.getElementById('total-word-count').innerText = total.toLocaleString();
        const progress = Math.min((total / 50000) * 100, 100);
        document.getElementById('word-progress-fill').style.width = `${progress}%`;
    }

    toggleFocusMode() {
        document.body.classList.toggle('focus-mode');
        const btn = document.getElementById('btn-focus');
        btn.innerText = document.body.classList.contains('focus-mode') ? 'Exit Focus Mode' : 'Focus Mode';
    }

    toggleNotes() { document.getElementById('notes-panel').classList.toggle('hidden'); }

    saveNotes() {
        const notes = document.getElementById('world-notes').value;
        localStorage.setItem(`book_notes_${this.bookId}`, notes);
    }

    loadNotes() {
        document.getElementById('world-notes').value = localStorage.getItem(`book_notes_${this.bookId}`) || '';
    }

    showMobilePreview() {
        const previewContent = document.getElementById('mobile-preview-content');
        const title = document.getElementById('current-chapter-title').value;
        previewContent.innerHTML = `
            <h2 style="font-size: 22px; margin-bottom: 15px; color: white;">${escapeHTML(title)}</h2>
            <div style="color: rgba(255,255,255,0.7); line-height: 1.8;">
                ${this.quill.root.innerHTML}
            </div>
        `;
        document.getElementById('mobile-preview-modal').classList.add('active');
    }

    // --- Audio & Publish ---

    async loadAudioStep() {
        const list = document.getElementById('audio-chapters-list');
        list.innerHTML = this.chapters.map(ch => `
            <div class="glass" style="padding: 20px; margin-bottom: 15px; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h4 style="margin-bottom: 5px;">${escapeHTML(ch.title)}</h4>
                    <p style="font-size: 12px; color: var(--text-secondary);">${ch.audio_file ? '✅ Audio uploaded' : '⏳ No audio file'}</p>
                </div>
                <div>
                    <input type="file" id="audio-input-${ch.id}" accept="audio/*" style="display:none" onchange="studioApp.uploadAudio(${ch.id})">
                    <button class="btn-secondary" onclick="document.getElementById('audio-input-${ch.id}').click()">Upload Audio</button>
                </div>
            </div>
        `).join('');
    }

    async uploadAudio(chapterId) {
        const file = document.getElementById(`audio-input-${chapterId}`).files[0];
        if (!file) return;
        const formData = new FormData();
        formData.append('audio_file', file);
        try {
            await window.readerApp.fetchAPI(`/core/books/${this.bookId}/chapters/${chapterId}/`, {
                method: 'PATCH',
                body: formData
            });
            alert("Audio uploaded!");
            this.loadAudioStep();
        } catch (e) { console.error(e); }
    }

    async publishBook() {
        if (!this.bookId) return;
        try {
            await window.readerApp.fetchAPI(`/core/books/${this.bookId}/`, {
                method: 'PATCH',
                body: JSON.stringify({ is_published: true })
            });
            alert('Your story is now live!');
            window.location.href = 'index.html';
        } catch (e) { alert(e.message); }
    }
}

const studioApp = new StudioApp();
