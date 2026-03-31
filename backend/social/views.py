from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action
from .models import Like, Comment, Notification, Follow
from .serializers import LikeSerializer, CommentSerializer, NotificationSerializer, FollowSerializer

class LikeViewSet(viewsets.ModelViewSet):
    queryset = Like.objects.all()
    serializer_class = LikeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        like = serializer.save(user=self.request.user)
        # Create notification for author
        if like.book.author != self.request.user:
            Notification.objects.create(
                recipient=like.book.author,
                actor=self.request.user,
                action_type='LIKE',
                book=like.book
            )

class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        comment = serializer.save(user=self.request.user)
        # Create notification for author
        if comment.book.author != self.request.user:
            Notification.objects.create(
                recipient=comment.book.author,
                actor=self.request.user,
                action_type='COMMENT',
                book=comment.book,
                message=comment.text[:50]
            )

class FollowViewSet(viewsets.ModelViewSet):
    queryset = Follow.objects.all()
    serializer_class = FollowSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Follow.objects.filter(follower=self.request.user)

    def perform_create(self, serializer):
        follow = serializer.save(follower=self.request.user)
        # Create notification for followed user
        Notification.objects.create(
            recipient=follow.followed,
            actor=self.request.user,
            action_type='FOLLOW',
            message=f"{self.request.user.username} started following you."
        )

class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({'status': 'marked as read'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        self.get_queryset().update(is_read=True)
        return Response({'status': 'all marked as read'})
