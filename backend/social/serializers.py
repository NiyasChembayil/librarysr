from rest_framework import serializers
from .models import Like, Comment, Notification, Follow, Post, PostLike, PostComment, PostCommentLike, Poll, PollOption, PollVote
from core.models import Book

class PostLikeSerializer(serializers.ModelSerializer):
    class Meta:
        model = PostLike
        fields = '__all__'
        read_only_fields = ['user']

class PostCommentSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')
    user_avatar = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()

    class Meta:
        model = PostComment
        fields = ['id', 'user', 'username', 'user_avatar', 'post', 'text', 'created_at', 'likes_count', 'is_liked']
        read_only_fields = ['user']

    def get_likes_count(self, obj):
        return obj.likes.count()

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return PostCommentLike.objects.filter(comment=obj, user=request.user).exists()
        return False

    def get_user_avatar(self, obj):
        request = self.context.get('request')
        if hasattr(obj.user, 'profile') and obj.user.profile.avatar:
            if request:
                return request.build_absolute_uri(obj.user.profile.avatar.url)
            return obj.user.profile.avatar.url
        return None

class PostSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')
    user_avatar = serializers.SerializerMethodField()
    book_title = serializers.ReadOnlyField(source='book.title', read_only=True)
    book_cover = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    reposts_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    parent_post_data = serializers.SerializerMethodField()
    poll = serializers.SerializerMethodField()
    is_verified = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'user', 'username', 'user_avatar', 'text', 'post_type', 
            'book', 'book_title', 'book_cover', 'chapter_id', 'audio_file', 'parent_post', 'parent_post_data',
            'created_at', 'updated_at', 'likes_count', 'comments_count', 
            'reposts_count', 'is_liked', 'poll', 'is_verified'
        ]
        read_only_fields = ['user']

    def get_user_avatar(self, obj):
        request = self.context.get('request')
        if hasattr(obj.user, 'profile') and obj.user.profile.avatar:
            if request:
                return request.build_absolute_uri(obj.user.profile.avatar.url)
            return obj.user.profile.avatar.url
        return None

    def get_book_cover(self, obj):
        if not obj.book or not obj.book.cover:
            return None
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.book.cover.url)
        return obj.book.cover.url

    def get_likes_count(self, obj):
        return obj.likes.count()

    def get_comments_count(self, obj):
        return obj.comments.count()

    def get_reposts_count(self, obj):
        return obj.reposts.count()

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return PostLike.objects.filter(post=obj, user=request.user).exists()
        return False

    def get_parent_post_data(self, obj):
        if obj.parent_post:
            return PostParentSerializer(obj.parent_post, context=self.context).data
        return None

    def get_poll(self, obj):
        if hasattr(obj, 'poll'):
            return PollSerializer(obj.poll, context=self.context).data
        return None

    def get_is_verified(self, obj):
        if hasattr(obj.user, 'profile'):
            return obj.user.profile.is_verified
        return False

class PostParentSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')
    user_avatar = serializers.SerializerMethodField()
    is_verified = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = ['id', 'user', 'username', 'user_avatar', 'is_verified', 'text', 'post_type', 'book', 'chapter_id', 'audio_file', 'created_at']

    def get_user_avatar(self, obj):
        request = self.context.get('request')
        if hasattr(obj.user, 'profile') and obj.user.profile.avatar:
            if request:
                return request.build_absolute_uri(obj.user.profile.avatar.url)
            return obj.user.profile.avatar.url
        return None

    def get_is_verified(self, obj):
        if hasattr(obj.user, 'profile'):
            return obj.user.profile.is_verified
        return False

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
    actor_profile_id = serializers.ReadOnlyField(source='actor.profile.id')
    book_title = serializers.ReadOnlyField(source='book.title')
    post_id = serializers.ReadOnlyField(source='post.id')
    is_following = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id', 'recipient', 'actor', 'actor_name', 'actor_profile_id',
            'action_type', 'book', 'book_title', 'post', 'post_id',
            'message', 'is_read', 'created_at', 'is_following'
        ]
        read_only_fields = ['recipient', 'actor', 'book', 'post', 'action_type', 'created_at']

    def get_is_following(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated and obj.actor:
            return Follow.objects.filter(follower=request.user, followed=obj.actor).exists()
        return False

class PollOptionSerializer(serializers.ModelSerializer):
    votes_count = serializers.SerializerMethodField()
    class Meta:
        model = PollOption
        fields = ['id', 'text', 'votes_count']
    
    def get_votes_count(self, obj):
        return obj.votes.count()

class PollSerializer(serializers.ModelSerializer):
    options = PollOptionSerializer(many=True, read_only=True)
    user_voted_option_id = serializers.SerializerMethodField()
    total_votes = serializers.SerializerMethodField()

    class Meta:
        model = Poll
        fields = ['id', 'question', 'options', 'expires_at', 'user_voted_option_id', 'total_votes']

    def get_user_voted_option_id(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            vote = PollVote.objects.filter(poll=obj, user=request.user).first()
            if vote:
                return vote.option_id
        return None

    def get_total_votes(self, obj):
        return obj.votes.count()
