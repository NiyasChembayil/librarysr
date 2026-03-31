from django.db import models
from django.contrib.auth.models import User
from core.models import Book

class Like(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='book_likes')
    book = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='likes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'book')

    def __str__(self):
        return f"{self.user.username} liked {self.book.title}"

class Comment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='book_comments')
    book = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='comments')
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} on {self.book.title}: {self.text[:20]}"

class Follow(models.Model):
    follower = models.ForeignKey(User, on_delete=models.CASCADE, related_name='following')
    followed = models.ForeignKey(User, on_delete=models.CASCADE, related_name='followers')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('follower', 'followed')

    def __str__(self):
        return f"{self.follower.username} follows {self.followed.username}"

class Notification(models.Model):
    TYPES = (
        ('LIKE', 'New Like'),
        ('COMMENT', 'New Comment'),
        ('NEW_BOOK', 'New Book'),
        ('FOLLOW', 'New Follower'),
        ('SYSTEM', 'System Message'),
    )
    
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    actor = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    action_type = models.CharField(max_length=20, choices=TYPES)
    book = models.ForeignKey(Book, on_delete=models.CASCADE, null=True, blank=True)
    message = models.TextField(blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.action_type} for {self.recipient.username}"
