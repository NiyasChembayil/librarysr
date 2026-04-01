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
    followed_by = models.ManyToManyField(User, related_name='following_profiles', blank=True)
    
    def __str__(self):
        return f"{self.user.username}'s Profile"

    @property
    def is_author(self):
        return self.role == 'author'
