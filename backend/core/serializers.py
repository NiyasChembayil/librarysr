from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Category, Book, Chapter, Purchase, ReadStats, AmbientSound, UserAmbientSound

class CategorySerializer(serializers.ModelSerializer):
    recommended_mood_name = serializers.ReadOnlyField(source='recommended_ambient_sound.name')
    recommended_mood_emoji = serializers.ReadOnlyField(source='recommended_ambient_sound.emoji')
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'recommended_mood_name', 'recommended_mood_emoji']

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

    class Meta:
        model = Book
        fields = [
            'id', 'title', 'slug', 'author_name', 'author_profile_id', 'cover', 
            'category_name', 'is_featured', 'likes_count', 'total_reads', 'downloads_count'
        ]

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

    class Meta:
        model = Book
        fields = [
            'id', 'title', 'slug', 'author', 'author_name', 'author_profile_id', 'is_author_following', 'cover', 
            'description', 'category', 'category_name', 'recommended_mood', 'price', 
            'is_published', 'is_featured', 'created_at', 'updated_at', 'chapters',
            'likes_count', 'comments_count', 'total_reads', 'is_in_library', 'is_liked',
            'downloads_count', 'shelf_status', 'is_favorite_book'
        ]

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

class PurchaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Purchase
        fields = [
            'id', 'user', 'book', 'purchased_at', 'amount', 
            'transaction_id', 'status', 'stripe_checkout_id'
        ]
        read_only_fields = ['user', 'amount', 'transaction_id', 'status', 'stripe_checkout_id']

class ReadStatsSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReadStats
        fields = '__all__'

class AmbientSoundSerializer(serializers.ModelSerializer):
    class Meta:
        model = AmbientSound
        fields = '__all__'

class UserAmbientSoundSerializer(serializers.ModelSerializer):
    audio_url = serializers.FileField(source='audio_file')
    
    class Meta:
        model = UserAmbientSound
        fields = ['id', 'name', 'emoji', 'audio_url', 'created_at']
        read_only_fields = ['user']

    def validate(self, data):
        user = self.context['request'].user
        if UserAmbientSound.objects.filter(user=user).count() >= 3:
            raise serializers.ValidationError("You can only add up to 3 custom ambient sounds.")
        return data
