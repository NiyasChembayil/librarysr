from django.db import models
from django.contrib.auth.models import User

class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)

    def __str__(self):
        return self.name

class Book(models.Model):
    title = models.CharField(max_length=255, db_index=True)
    slug = models.SlugField(unique=True, null=True, blank=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='books')
    cover = models.ImageField(upload_to='book_covers/', null=True, blank=True)
    description = models.TextField()
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='books')
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00) # Legacy field, platform is free
    is_published = models.BooleanField(default=False)
    region = models.CharField(max_length=50, default='Global', db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['title']),
            models.Index(fields=['slug']),
        ]

    def __str__(self):
        return self.title

    @property
    def total_reads(self):
        return self.read_stats.count()

    @property
    def total_downloads(self):
        return self.userlibrary_set.count()

class Chapter(models.Model):
    book = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='chapters')
    title = models.CharField(max_length=255)
    content = models.TextField(null=True, blank=True) # Rich text content
    audio_file = models.FileField(upload_to='chapter_audio/', null=True, blank=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.book.title} - {self.title}"

class Purchase(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('COMPLETED', 'Completed'),
        ('FAILED', 'Failed'),
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='purchases')
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    purchased_at = models.DateTimeField(auto_now_add=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_id = models.CharField(max_length=100, unique=True, null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    stripe_checkout_id = models.CharField(max_length=255, null=True, blank=True)
    stripe_payment_intent_id = models.CharField(max_length=255, null=True, blank=True)

    def __str__(self):
        return f"{self.user.username} bought {self.book.title} ({self.status})"

class ReadStats(models.Model):
    book = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='read_stats')
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

class UserLibrary(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='library')
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'book')
        verbose_name_plural = "User Libraries"

    def __str__(self):
        return f"{self.user.username}'s library: {self.book.title}"

