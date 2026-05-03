from django.db import models
from django.contrib.auth.models import User

class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    recommended_ambient_sound = models.ForeignKey('AmbientSound', on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return self.name

class BookQuerySet(models.QuerySet):
    def order_for_discovery(self):
        return self.order_by('?') 

class Book(models.Model):
    objects = BookQuerySet.as_manager()
    title = models.CharField(max_length=255, db_index=True)
    slug = models.SlugField(unique=True, null=True, blank=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='books')
    cover = models.ImageField(upload_to='book_covers/', null=True, blank=True)
    description = models.TextField()
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='books')
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    is_published = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title

class Chapter(models.Model):
    book = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='chapters')
    title = models.CharField(max_length=255)
    content = models.TextField(null=True, blank=True)
    audio_file = models.FileField(upload_to='chapter_audio/', null=True, blank=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.book.title} - {self.title}"

class UserLibrary(models.Model):
    SHELF_CHOICES = (
        ('TO_READ', 'To Read'),
        ('READING', 'Reading'),
        ('FINISHED', 'Finished'),
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    shelf = models.CharField(max_length=20, choices=SHELF_CHOICES, default='TO_READ')
    is_favorite = models.BooleanField(default=False)
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'book')

class ReadStats(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    book = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='reads')
    timestamp = models.DateTimeField(auto_now_add=True)

class ReadingProgress(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    chapter_index = models.IntegerField(default=0)
    last_read = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'book')

    def __str__(self):
        return f"{self.user.username} - {self.book.title} (Chapter {self.chapter_index})"

class AmbientSound(models.Model):
    name = models.CharField(max_length=100)
    emoji = models.CharField(max_length=10, default='🎵')
    audio_url = models.URLField()
    is_system = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.emoji} {self.name}"

class UserAmbientSound(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='custom_sounds')
    name = models.CharField(max_length=50)
    emoji = models.CharField(max_length=10, default='🎵')
    audio_file = models.FileField(upload_to='user_ambient/')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'name')

    def __str__(self):
        return f"{self.user.username}'s {self.name}"

class Purchase(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    stripe_payment_intent = models.CharField(max_length=255, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'book')
