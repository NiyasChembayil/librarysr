from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import LikeViewSet, CommentViewSet, NotificationViewSet, FollowViewSet

router = DefaultRouter()
router.register(r'likes', LikeViewSet)
router.register(r'comments', CommentViewSet)
router.register(r'follows', FollowViewSet)
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = [
    path('', include(router.urls)),
]
