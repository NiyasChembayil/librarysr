from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Category, Book, Chapter, Purchase, ReadStats, ReadingProgress, AmbientSound, UserAmbientSound, Review

class CategorySerializer(serializers.ModelSerializer):
    recommended_mood_name = serializers.ReadOnlyField(source='recommended_ambient_sound.name')
    recommended_mood_emoji = serializers.ReadOnlyField(source='recommended_ambient_sound.emoji')
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'recommended_ambient_sound', 'recommended_mood_name', 'recommended_mood_emoji']

class ChapterSerializer(serializers.ModelSerializer):
    book = serializers.PrimaryKeyRelatedField(read_only=True)
    class Meta:
        model = Chapter
        fields = '__all__'

class BookSummarySerializer(serializers.ModelSerializer):
    author_name = serializers.ReadOnlyField(source='author.username')
    category_name = serializers.ReadOnlyField(source='category.name')
    author_profile_id = serializers.ReadOnlyField(source='author.profile.id')
    likes_count = serializers.SerializerMethodField()
    total_reads = serializers.SerializerMethodField()
    downloads_count = serializers.SerializerMethodField()
    author_avatar = serializers.SerializerMethodField()

    class Meta:
        model = Book
        fields = [
            'id', 'title', 'slug', 'author_name', 'author_profile_id', 'author_avatar', 'cover', 
            'category_name', 'is_featured', 'likes_count', 'total_reads', 'downloads_count', 'rating'
        ]

    rating = serializers.ReadOnlyField(source='average_rating')

    def get_author_avatar(self, obj):
        if hasattr(obj.author, 'profile') and obj.author.profile.avatar:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.author.profile.avatar.url)
            return obj.author.profile.avatar.url
        return None

    def get_likes_count(self, obj):
        return obj.likes.count()

    def get_total_reads(self, obj):
        return obj.reads.count()

    def get_downloads_count(self, obj):
        return obj.userlibrary_set.count()

class BookSerializer(serializers.ModelSerializer):
    author = serializers.PrimaryKeyRelatedField(read_only=True)
    author_name = serializers.ReadOnlyField(source='author.username')
    category_name = serializers.ReadOnlyField(source='category.name')
    recommended_mood = serializers.ReadOnlyField(source='category.recommended_ambient_sound.name')
    author_profile_id = serializers.ReadOnlyField(source='author.profile.id')
    is_author_following = serializers.SerializerMethodField()
    chapters = ChapterSerializer(many=True, read_only=True)
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    is_in_library = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    downloads_count = serializers.SerializerMethodField()
    total_reads = serializers.SerializerMethodField()
    shelf_status = serializers.SerializerMethodField()
    is_favorite_book = serializers.SerializerMethodField()
    is_author_verified = serializers.SerializerMethodField()
    author_avatar = serializers.SerializerMethodField()
    rating = serializers.ReadOnlyField(source='average_rating')

    class Meta:
        model = Book
        fields = [
            'id', 'title', 'slug', 'author', 'author_name', 'author_profile_id', 'author_avatar', 'is_author_following', 'cover', 
            'description', 'category', 'category_name', 'recommended_mood', 'price', 
            'is_published', 'is_featured', 'created_at', 'updated_at', 'chapters',
            'likes_count', 'comments_count', 'total_reads', 'is_in_library', 'is_liked',
            'downloads_count', 'shelf_status', 'is_favorite_book', 'is_author_verified', 'rating'
        ]

    def get_author_avatar(self, obj):
        if hasattr(obj.author, 'profile') and obj.author.profile.avatar:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.author.profile.avatar.url)
            return obj.author.profile.avatar.url
        return None

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False

    def get_is_author_following(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            # Check if the current user follows the author
            return obj.author.followers.filter(follower=request.user).exists()
        return False

    def get_likes_count(self, obj):
        return obj.likes.count()

    def get_comments_count(self, obj):
        return obj.comments.count()

    def get_is_in_library(self, obj):
        from .models import UserLibrary
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return UserLibrary.objects.filter(user=request.user, book=obj).exists()
        return False

    def get_downloads_count(self, obj):
        return obj.userlibrary_set.count()

    def get_total_reads(self, obj):
        return obj.reads.count()

    def get_shelf_status(self, obj):
        from .models import UserLibrary
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            item = UserLibrary.objects.filter(user=request.user, book=obj).first()
            return item.shelf if item else 'TO_READ'
        return 'TO_READ'

    def get_is_favorite_book(self, obj):
        from .models import UserLibrary
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            item = UserLibrary.objects.filter(user=request.user, book=obj).first()
            return item.is_favorite if item else False
        return False

    def get_is_author_verified(self, obj):
        if hasattr(obj.author, 'profile'):
            return obj.author.profile.is_verified
        return False

class PurchaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Purchase
        fields = [
            'id', 'user', 'book', 'purchased_at', 'amount', 
            'transaction_id', 'status', 'stripe_checkout_id'
        ]
        read_only_fields = ['user', 'amount', 'transaction_id', 'status', 'stripe_checkout_id']

class ReviewSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')
    user_avatar = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ['id', 'user', 'username', 'user_avatar', 'book', 'rating', 'comment', 'created_at']
        read_only_fields = ['user']

    def get_user_avatar(self, obj):
        if hasattr(obj.user, 'profile') and obj.user.profile.avatar:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.user.profile.avatar.url)
            return obj.user.profile.avatar.url
        return None

class ReadStatsSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReadStats
        fields = '__all__'

class AmbientSoundSerializer(serializers.ModelSerializer):
    audio_url = serializers.SerializerMethodField()
    
    class Meta:
        model = AmbientSound
        fields = ['id', 'name', 'emoji', 'audio_url', 'audio_file', 'is_system', 'order']

    def get_audio_url(self, obj):
        if obj.audio_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.audio_file.url)
            return obj.audio_file.url
        return obj.audio_url

class UserAmbientSoundSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserAmbientSound
        fields = ['id', 'name', 'emoji', 'audio_file', 'created_at']
        read_only_fields = ['user']

    def validate(self, data):
        user = self.context['request'].user
        if UserAmbientSound.objects.filter(user=user).count() >= 3:
            raise serializers.ValidationError("You can only add up to 3 custom ambient sounds.")
        return data

class ReadingProgressSerializer(serializers.ModelSerializer):
    book_id = serializers.ReadOnlyField(source='book.id')
    book_title = serializers.ReadOnlyField(source='book.title')
    book_author = serializers.ReadOnlyField(source='book.author.username')
    book_cover = serializers.SerializerMethodField()

    class Meta:
        model = ReadingProgress
        fields = ['id', 'book_id', 'book_title', 'book_author', 'book_cover', 'chapter_index', 'last_read']

    def get_book_cover(self, obj):
        if obj.book.cover:
            return self.context['request'].build_absolute_uri(obj.book.cover.url)
        return None
