from rest_framework import serializers
from .models import Like, Comment, Notification, Follow

class LikeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Like
        fields = '__all__'
        read_only_fields = ['user']

class CommentSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = Comment
        fields = ['id', 'user', 'username', 'book', 'text', 'created_at']
        read_only_fields = ['user']

class FollowSerializer(serializers.ModelSerializer):
    follower_name = serializers.ReadOnlyField(source='follower.username')
    followed_name = serializers.ReadOnlyField(source='followed.username')

    class Meta:
        model = Follow
        fields = ['id', 'follower', 'follower_name', 'followed', 'followed_name', 'created_at']
        read_only_fields = ['follower', 'created_at']

class NotificationSerializer(serializers.ModelSerializer):
    actor_name = serializers.ReadOnlyField(source='actor.username')
    book_title = serializers.ReadOnlyField(source='book.title')

    class Meta:
        model = Notification
        fields = [
            'id', 'recipient', 'actor', 'actor_name', 
            'action_type', 'book', 'book_title', 
            'message', 'is_read', 'created_at'
        ]
        read_only_fields = ['recipient', 'actor', 'book', 'action_type', 'created_at']
