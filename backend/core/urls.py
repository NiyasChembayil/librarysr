from django.urls import path, include
from rest_framework_nested import routers
from .views import CategoryViewSet, BookViewSet, ChapterViewSet, PurchaseViewSet, AmbientSoundViewSet, UserAmbientSoundViewSet

router = routers.DefaultRouter()
router.register(r'categories', CategoryViewSet)
router.register(r'books', BookViewSet, basename='book')
router.register(r'purchases', PurchaseViewSet)
router.register(r'ambient-sounds-list', AmbientSoundViewSet, basename='ambient-sounds-list')
router.register(r'user-sounds', UserAmbientSoundViewSet, basename='user-sounds')

books_router = routers.NestedDefaultRouter(router, r'books', lookup='book')
books_router.register(r'chapters', ChapterViewSet, basename='book-chapters')

urlpatterns = [
    path('', include(router.urls)),
    path('', include(books_router.urls)),
    # Legacy path if still needed, otherwise the router handles it
    path('ambient-sounds/', AmbientSoundViewSet.as_view({'get': 'list'}), name='ambient-sounds'),
]
