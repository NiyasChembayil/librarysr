from django.db import models
from django.contrib.auth.models import User

class Profile(models.Model):
    ROLE_CHOICES = (
        ('reader', 'Reader'),
        ('author', 'Author'),
        ('admin', 'Admin'),
    )
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='author')
    bio = models.TextField(blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    banner = models.ImageField(upload_to='banners/', null=True, blank=True)
    is_verified = models.BooleanField(default=False)
    
    # Privacy & Safety
    is_private = models.BooleanField(default=False)
    
    # Notification Preferences
    notify_new_follower = models.BooleanField(default=True)
    notify_likes = models.BooleanField(default=True)
    notify_comments = models.BooleanField(default=True)
    notify_new_books = models.BooleanField(default=True)
    
    # Reader & Audio Preferences
    font_size = models.FloatField(default=16.0)
    reader_theme = models.CharField(max_length=20, default='Dark')
    playback_speed = models.FloatField(default=1.0)
    
    def save(self, *args, **kwargs):
        from core.utils import optimize_image
        # Optimize avatar
        if self.avatar and not self.avatar._committed:
            optimized_avatar = optimize_image(self.avatar, max_width=300)
            if optimized_avatar:
                self.avatar.save(optimized_avatar.name, optimized_avatar, save=False)
        # Optimize banner
        if self.banner and not self.banner._committed:
            optimized_banner = optimize_image(self.banner, max_width=1200)
            if optimized_banner:
                self.banner.save(optimized_banner.name, optimized_banner, save=False)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.username}'s Profile"

    @property
    def is_author(self):
        return self.role == 'author'
