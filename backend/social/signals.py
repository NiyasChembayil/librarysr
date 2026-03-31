from django.db.models.signals import post_save
from django.dispatch import receiver
from core.models import Book
from .models import Notification, Follow

@receiver(post_save, sender=Book)
def notify_followers_on_new_book(sender, instance, created, **kwargs):
    if created and instance.is_published:
        # Get all followers of the author
        followers = Follow.objects.filter(followed=instance.author)
        
        # Collect recipients to avoid N+1 if mass creating notifications
        notifications = [
            Notification(
                recipient=follow.follower,
                actor=instance.author,
                action_type='NEW_BOOK',
                book=instance,
                message=f"{instance.author.username} published a new book: {instance.title}"
            )
            for follow in followers
        ]
        
        # Bulk create all notifications for efficiency
        Notification.objects.bulk_create(notifications)
