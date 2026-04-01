from rest_framework import viewsets, permissions, status, filters
from rest_framework.response import Response
from rest_framework.decorators import action
from django.contrib.auth.models import User
from .models import Profile
from .serializers import UserSerializer, ProfileSerializer, RegisterSerializer, UserListSerializer

class AuthViewSet(viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer

    @action(detail=False, methods=['post'])
    def register(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'])
    def password_reset(self, request):
        email = request.data.get('email')
        if not email:
            return Response({"error": "Email is required."}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user exists
        user_exists = User.objects.filter(email=email).exists()
        
        # We return success regardless to avoid account enumeration (security best practice)
        # In a real app, we would only queue the email if the user exists.
        return Response({
            "message": "If an account with that email exists, a password reset link has been sent.",
            "status": "success"
        }, status=status.HTTP_200_OK)

class ProfileViewSet(viewsets.ModelViewSet):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [filters.SearchFilter]
    search_fields = ['user__username', 'bio']

    def get_queryset(self):
        if self.action == 'me':
            return Profile.objects.filter(user=self.request.user)
        return super().get_queryset()

    @action(detail=False, methods=['get', 'put', 'patch'])
    def me(self, request):
        profile = request.user.profile
        if request.method == 'GET':
            serializer = self.get_serializer(profile)
            return Response(serializer.data)
        serializer = self.get_serializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def follow(self, request, pk=None):
        profile = self.get_object()
        if profile.user == request.user:
            return Response({"error": "You cannot follow yourself."}, status=status.HTTP_400_BAD_REQUEST)
        
        if profile.followed_by.filter(id=request.user.id).exists():
            profile.followed_by.remove(request.user)
            return Response({"status": "unfollowed"})
        else:
            profile.followed_by.add(request.user)
            return Response({"status": "followed"})

    @action(detail=True, methods=['get'])
    def followers(self, request, pk=None):
        profile = self.get_object()
        followers = profile.followed_by.all()
        serializer = UserListSerializer(followers, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def following(self, request, pk=None):
        profile = self.get_object()
        # Get users that this profile's owner is following
        following_profiles = profile.user.following_profiles.all()
        following_users = [p.user for p in following_profiles]
        serializer = UserListSerializer(following_users, many=True)
        return Response(serializer.data)
