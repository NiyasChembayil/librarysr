from rest_framework import viewsets, permissions, status, filters
from rest_framework.response import Response
from rest_framework.decorators import action
from django.db.models import Count
from .models import Category, Book, Chapter, Purchase, ReadStats
from .serializers import CategorySerializer, BookSerializer, ChapterSerializer, PurchaseSerializer
from .utils import generate_voice_for_chapter
from .payments import create_stripe_checkout_session, fulfill_purchase
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator
import stripe

@method_decorator(cache_page(60 * 15), name='dispatch')
class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'slug'

class BookViewSet(viewsets.ModelViewSet):
    queryset = Book.objects.filter(is_published=True).select_related('author', 'category').prefetch_related('chapters')
    serializer_class = BookSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filterset_fields = ['category', 'author']
    search_fields = ['title', 'description']
    ordering_fields = ['created_at', 'price']

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    @action(detail=True, methods=['post'])
    def record_read(self, request, pk=None):
        book = self.get_object()
        user = request.user if request.user.is_authenticated else None
        ReadStats.objects.create(book=book, user=user)
        return Response({'status': 'read recorded'})

    @method_decorator(cache_page(60 * 15))
    @action(detail=False, methods=['get'])
    def trending(self, request):
        region = request.query_params.get('region')
        
        # Weighted Score: (Reads * 1) + (Likes * 3)
        books = Book.objects.annotate(
            read_count=Count('read_stats', distinct=True),
            likes_count=Count('likes', distinct=True)
        ).annotate(
            score=(Count('read_stats') * 1) + (Count('likes') * 3)
        )
        
        if region:
            books = books.filter(region__icontains=region)
            
        books = books.order_by('-score')[:10]
        serializer = self.get_serializer(books, many=True)
        return Response(serializer.data)

class ChapterViewSet(viewsets.ModelViewSet):
    queryset = Chapter.objects.all().select_related('book')
    serializer_class = ChapterSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return Chapter.objects.filter(book_id=self.kwargs['book_pk'])

    def perform_create(self, serializer):
        chapter = serializer.save(book_id=self.kwargs['book_pk'])
        # Automate voice generation for new chapters
        try:
            generate_voice_for_chapter(chapter)
        except Exception as e:
            # Log error but don't fail chapter creation
            print(f"Voice generation failed: {e}")

    @action(detail=True, methods=['post'])
    def generate_voice(self, request, book_pk=None, pk=None):
        chapter = self.get_object()
        if not chapter.content:
            return Response({'error': 'Chapter has no content'}, status=status.HTTP_400_BAD_REQUEST)
        
        audio_url = generate_voice_for_chapter(chapter)
        return Response({'status': 'audio generated', 'url': audio_url})

class PurchaseViewSet(viewsets.ModelViewSet):
    queryset = Purchase.objects.all().select_related('user', 'book')
    serializer_class = PurchaseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Purchase.objects.filter(user=self.request.user)

    @action(detail=False, methods=['post'])
    def create_checkout_session(self, request):
        book_id = request.data.get('book_id')
        if not book_id:
            return Response({'error': 'book_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        success_url = settings.FRONTEND_URL + '/payment-success'
        cancel_url = settings.FRONTEND_URL + '/payment-cancelled'
        
        session = create_stripe_checkout_session(
            request.user, 
            book_id, 
            success_url, 
            cancel_url
        )
        
        if session:
            return Response({
                'session_url': session.url,
                'session_id': session.id
            })
        return Response({'error': 'Failed to create session'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny])
    @method_decorator(csrf_exempt)
    def webhook(self, request):
        payload = request.body
        sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')
        endpoint_secret = settings.STRIPE_WEBHOOK_SECRET

        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, endpoint_secret
            )
        except ValueError:
            return Response(status=status.HTTP_400_BAD_REQUEST)
        except stripe.error.SignatureVerificationError:
            return Response(status=status.HTTP_400_BAD_REQUEST)

        if event['type'] == 'checkout.session.completed':
            session = event['data']['object']
            fulfill_purchase(session)

        return Response(status=status.HTTP_200_OK)

    def perform_create(self, serializer):
        # Prevent manual creation, only via checkout
        pass
