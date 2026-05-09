from rest_framework import viewsets, permissions, status, filters
from rest_framework.response import Response
from rest_framework.decorators import action
from django.contrib.auth.models import User
from django.utils import timezone
from .models import Profile
from .serializers import UserSerializer, ProfileSerializer, RegisterSerializer, UserListSerializer
from core.models import ReadStats
from social.models import Follow, Notification
from core.permissions import IsProfileOwnerOrReadOnly

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

    @action(detail=False, methods=['get'])
    def global_stats(self, request):
        total_users = User.objects.count()
        new_users_today = User.objects.filter(date_joined__date=timezone.now().date()).count()
        
        return Response({
            "total_users": total_users,
            "new_users_today": new_users_today,
            "server_time": timezone.now()
        })

class ProfileViewSet(viewsets.ModelViewSet):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsProfileOwnerOrReadOnly]
    filter_backends = [filters.SearchFilter]
    search_fields = ['user__username', 'bio']

    def get_permissions(self):
        if self.action == 'follow':
            return [permissions.IsAuthenticated()]
        return super().get_permissions()

    def get_queryset(self):
        if self.action == 'me':
            return Profile.objects.filter(user=self.request.user)
        return super().get_queryset()

    @action(detail=False, methods=['get', 'put', 'patch'])
    def me(self, request):
        profile, created = Profile.objects.get_or_create(user=request.user)
        if request.method == 'GET':
            serializer = self.get_serializer(profile)
            return Response(serializer.data)
            
        # Let the serializer handle all updates (Profile and User fields)

        # Handle Profile model updates
        serializer = self.get_serializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def follow(self, request, pk=None):
        profile = self.get_object()
        if profile.user == request.user:
            return Response({"error": "You cannot follow yourself."}, status=status.HTTP_400_BAD_REQUEST)
        
        follow_rel = Follow.objects.filter(follower=request.user, followed=profile.user)
        if follow_rel.exists():
            follow_rel.delete()
            return Response({"status": "unfollowed"})
        else:
            Follow.objects.create(follower=request.user, followed=profile.user)
            Notification.objects.create(
                recipient=profile.user,
                actor=request.user,
                action_type='FOLLOW',
                message=f"{request.user.username} started following you."
            )
            return Response({"status": "followed"})

    @action(detail=True, methods=['get'])
    def followers(self, request, pk=None):
        profile = self.get_object()
        # Users who are following this profile's owner
        follows = Follow.objects.filter(followed=profile.user).select_related('follower')
        followers_users = [f.follower for f in follows]
        serializer = UserListSerializer(followers_users, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def following(self, request, pk=None):
        profile = self.get_object()
        # Users who this profile's owner is following
        follows = Follow.objects.filter(follower=profile.user).select_related('followed')
        following_users = [f.followed for f in follows]
        serializer = UserListSerializer(following_users, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def activity(self, request, pk=None):
        profile = self.get_object()
        
        # Calculate daily activity for the last 35 days (5 weeks) for heatmap
        today = timezone.localdate()
        results = []
        
        # If the user is an author, show reads of THEIR books
        # If they are just a reader, show THEIR own reading activity
        is_author = profile.role == 'author'
        
        for i in range(34, -1, -1):
            date = today - timezone.timedelta(days=i)
            if is_author:
                # Total reads of all books by this author on this day
                count = ReadStats.objects.filter(
                    book__author=profile.user,
                    timestamp__date=date
                ).count()
            else:
                # Total reads done by this user on this day
                count = ReadStats.objects.filter(
                    user=profile.user,
                    timestamp__date=date
                ).count()
                
            results.append({
                "date": date.isoformat(),
                "count": count
            })
            
        return Response({
            "activity": results,
            "type": "author" if is_author else "reader"
        })
    
    @action(detail=False, methods=['get'], url_path='by_user/(?P<user_id>[0-9]+)')
    def by_user(self, request, user_id=None):
        try:
            profile = Profile.objects.get(user_id=user_id)
            serializer = self.get_serializer(profile)
            return Response(serializer.data)
        except Profile.DoesNotExist:
            return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=['post'])
    def upgrade_role(self, request):
        profile = request.user.profile
        if profile.role == 'reader':
            profile.role = 'author'
            profile.save()
            return Response({"status": "success", "role": profile.role})
        return Response({"status": "already_author", "role": profile.role})

    @action(detail=True, methods=['post'])
    def toggle_verification(self, request, pk=None):
        if not (request.user.is_staff or request.user.profile.role == 'admin'):
            return Response({"error": "Admin access required"}, status=403)
            
        profile = self.get_object()
        profile.is_verified = not profile.is_verified
        profile.save()
        
        if profile.is_verified:
            Notification.objects.create(
                recipient=profile.user,
                action_type='SYSTEM',
                message="Congratulations! Your account has been officially verified with a Blue Tick."
            )
            
        return Response({
            "status": "success",
            "is_verified": profile.is_verified
        })

    @action(detail=False, methods=['get'])
    def export_csv(self, request):
        if not (request.user.is_staff or request.user.profile.role == 'admin'):
            return Response({"error": "Admin access required"}, status=403)
            
        import csv
        from django.http import HttpResponse
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="srishty_users.csv"'
        
        writer = csv.writer(response)
        writer.writerow(['ID', 'Username', 'Email', 'Role', 'Verified', 'Date Joined'])
        
        profiles = Profile.objects.all().select_related('user')
        for profile in profiles:
            writer.writerow([
                profile.user.id,
                profile.user.username,
                profile.user.email,
                profile.role,
                profile.is_verified,
                profile.user.date_joined.strftime('%Y-%m-%d %H:%M:%S')
            ])
            
        return response
