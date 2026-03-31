from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Category, Book, Chapter, Purchase, ReadStats

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class ChapterSerializer(serializers.ModelSerializer):
    class Meta:
        model = Chapter
        fields = '__all__'

class BookSerializer(serializers.ModelSerializer):
    author_name = serializers.ReadOnlyField(source='author.username')
    category_name = serializers.ReadOnlyField(source='category.name')
    chapters = ChapterSerializer(many=True, read_only=True)
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()

    class Meta:
        model = Book
        fields = [
            'id', 'title', 'slug', 'author', 'author_name', 'cover', 
            'description', 'category', 'category_name', 'price', 
            'is_published', 'created_at', 'updated_at', 'chapters',
            'likes_count', 'comments_count', 'total_reads'
        ]

    def get_likes_count(self, obj):
        return obj.likes.count()

    def get_comments_count(self, obj):
        return obj.comments.count()

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
