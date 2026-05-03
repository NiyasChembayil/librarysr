from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Chapter, Book
from social.models import Notification, Follow

@receiver(post_save, sender=Chapter)
def notify_new_chapter(sender, instance, created, **kwargs):
    if created:
        book = instance.book
        # Notify all followers of the author
        followers = Follow.objects.filter(followed=book.author)
        for follow in followers:
            Notification.objects.create(
                recipient=follow.follower,
                actor=book.author,
                action_type='NEW_CHAPTER',
                book=book,
                message=f"{book.author.username} added a new chapter to '{book.title}': {instance.title}"
            )

@receiver(post_save, sender=Book)
def notify_new_book(sender, instance, created, **kwargs):
    if created and instance.is_published:
        # Notify all followers of the author
        followers = Follow.objects.filter(followed=instance.author)
        for follow in followers:
            Notification.objects.create(
                recipient=follow.follower,
                actor=instance.author,
                action_type='NEW_BOOK',
                book=instance,
                message=f"{instance.author.username} published a new book: '{instance.title}'"
            )
