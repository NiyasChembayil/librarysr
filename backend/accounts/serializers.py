from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Profile


class ProfileSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')
    email = serializers.ReadOnlyField(source='user.email')
    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = ['id', 'username', 'email', 'role', 'bio', 'avatar', 'followed_by', 'followers_count', 'following_count']
        read_only_fields = ['id', 'followed_by', 'username', 'email', 'followers_count', 'following_count']

    def get_followers_count(self, obj):
        return obj.followed_by.count()

    def get_following_count(self, obj):
        return obj.user.following_profiles.count()


class UserSerializer(serializers.ModelSerializer):
    profile = ProfileSerializer()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'profile']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        profile_data = validated_data.pop('profile', {})
        user = User.objects.create_user(**validated_data)
        Profile.objects.filter(user=user).update(**profile_data)
        return user


class UserListSerializer(serializers.ModelSerializer):
    avatar = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'avatar']

    def get_avatar(self, obj):
        if hasattr(obj, 'profile') and obj.profile.avatar:
            return obj.profile.avatar.url
        return None


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    role = serializers.CharField(write_only=True, required=False, default='reader')

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'role']

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_username(self, value):
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def create(self, validated_data):
        role = validated_data.pop('role', 'reader')
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )
        user.profile.role = role
        user.profile.save()
        return user
