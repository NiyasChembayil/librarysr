from rest_framework import viewsets, permissions, status, filters
from rest_framework.response import Response
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.db.models import Count, Q, F, Sum
from django.utils import timezone
from datetime import timedelta
from .models import Category, Book, Chapter, Purchase, ReadStats, ReadingProgress, AmbientSound, UserAmbientSound
from .serializers import CategorySerializer, BookSerializer, BookSummarySerializer, ChapterSerializer, PurchaseSerializer, AmbientSoundSerializer, UserAmbientSoundSerializer
from .payments import create_stripe_checkout_session, fulfill_purchase
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator
from .permissions import IsAuthorOrReadOnly
import stripe

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'

class BookViewSet(viewsets.ModelViewSet):
    serializer_class = BookSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly]
    filterset_fields = ['category']
    search_fields = ['title', 'description']
    ordering_fields = ['created_at', 'price']
    ordering = ['-created_at']

    def get_queryset(self):
        queryset = Book.objects.all()
        author_id = self.request.query_params.get('author')
        if author_id:
            print(f"DEBUG: author_id={author_id}, user={self.request.user}, authenticated={self.request.user.is_authenticated}")
            if author_id == 'me' and self.request.user.is_authenticated:
                queryset = queryset.filter(author=self.request.user)
            else:
                queryset = queryset.filter(author_id=author_id)
        
        category_slug = self.request.query_params.get('category_slug')
        if category_slug:
            queryset = queryset.filter(category__slug=category_slug)

        print(f"DEBUG: returning {queryset.count()} books")
        return queryset

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    @action(detail=True, methods=['post'])
    def toggle_featured(self, request, pk=None):
        book = self.get_object()
        book.is_featured = not book.is_featured
        book.save()
        return Response({'status': 'featured toggled', 'is_featured': book.is_featured})

    @action(detail=True, methods=['post'])
    def record_read(self, request, pk=None):
        book = self.get_object()
        user = request.user if request.user.is_authenticated else None
        ReadStats.objects.create(book=book, user=user)
        
        if user:
            from social.models import Notification
            read_count = ReadStats.objects.filter(user=user).count()
            milestones = [10, 50, 100, 500, 1000]
            if read_count in milestones:
                Notification.objects.create(
                    recipient=user,
                    action_type='MILESTONE',
                    message=f"🎉 Achievement Unlocked: You've read {read_count} chapters on Srishty! Keep up the great journey."
                )
                
        return Response({'status': 'read recorded'})

    @action(detail=False, methods=['get'])
    def library_stats(self, request):
        user = request.user
        if not user.is_authenticated:
            return Response({"error": "Authentication required"}, status=401)

        # 1. Total Library Books
        written_books_ids = set(Book.objects.filter(author=user).values_list('id', flat=True))
        purchased_books_ids = set(Purchase.objects.filter(user=user).values_list('book_id', flat=True))
        all_library_ids = written_books_ids.union(purchased_books_ids)
        total_library_books = len(all_library_ids)

        # 2. Monthly Milestone (Chapters/Reads this month)
        now = timezone.now()
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        monthly_milestone = ReadStats.objects.filter(user=user, timestamp__gte=start_of_month).count()

        # 3. Genre DNA (Reading)
        genre_counts = ReadStats.objects.filter(user=user)\
            .values('book__category__name')\
            .annotate(count=Count('id'))\
            .order_by('-count')[:5]
        
        genre_dna = [
            {"genre": g['book__category__name'] or "Other", "count": g['count']} 
            for g in genre_counts
        ]

        # 4. Streak
        read_dates = ReadStats.objects.filter(user=user)\
            .annotate(date=F('timestamp__date'))\
            .values_list('date', flat=True)\
            .distinct()\
            .order_by('-date')
        
        streak = 0
        if read_dates.exists():
            today = timezone.localdate()
            current_check = today
            if read_dates[0] < today:
                if read_dates[0] == today - timedelta(days=1):
                    current_check = today - timedelta(days=1)
                else:
                    streak = 0
                    current_check = None
            
            if current_check:
                for read_date in read_dates:
                    if read_date == current_check:
                        streak += 1
                        current_check -= timedelta(days=1)
                    elif read_date < current_check:
                        break

        return Response({
            "streak": streak,
            "genre_dna": genre_dna,
            "monthly_milestone": monthly_milestone,
            "total_library_books": total_library_books
        })

    @action(detail=False, methods=['get'])
    def author_stats(self, request):
        user = request.user
        if not user.is_authenticated:
            return Response({"error": "Authentication required"}, status=401)

        # 1. Total Reads across all my books
        my_books = Book.objects.filter(author=user)
        total_reads = ReadStats.objects.filter(book__in=my_books).count()

        # 2. Total Followers
        followers_count = user.followers.count()

        # 3. Genre DNA (Writing distribution)
        writing_genres = my_books.values('category__name').annotate(count=Count('id')).order_by('-count')
        genre_dna = [
            {"genre": g['category__name'] or "Other", "count": g['count']}
            for g in writing_genres
        ]

        # 4. Published Books
        published_count = my_books.filter(is_published=True).count()

        return Response({
            "total_reads": total_reads,
            "followers_count": followers_count,
            "genre_dna": genre_dna,
            "published_count": published_count,
            "writing_streak": 7 # Placeholder for actual logic if needed
        })

    @action(detail=False, methods=['get'])
    def discovery(self, request):
        # In a real app, this would use complex analytics.
        # For now, we'll provide varied random samples to populate the grid.
        all_published = Book.objects.filter(is_published=True)
        
        mostly_read = all_published.order_by('?')[:6]
        local_hits = all_published.order_by('?')[:6]
        social_hits = all_published.order_by('?')[:6]
        
        # Featured Authors Spotlight
        from accounts.models import Profile
        from accounts.serializers import ProfileSerializer
        featured_authors = Profile.objects.filter(role='author').order_by('?')[:10]
        
        serializer_context = {'request': request}
        
        return Response({
            'mostly_read': {
                'category_name': 'Trending Now',
                'books': BookSummarySerializer(mostly_read, many=True, context=serializer_context).data
            },
            'local_hits': BookSummarySerializer(local_hits, many=True, context=serializer_context).data,
            'social_hits': BookSummarySerializer(social_hits, many=True, context=serializer_context).data,
            'featured_authors': ProfileSerializer(featured_authors, many=True, context=serializer_context).data
        })

class ChapterViewSet(viewsets.ModelViewSet):
    serializer_class = ChapterSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly]

    def get_queryset(self):
        return Chapter.objects.filter(book_id=self.kwargs['book_pk'])

    def perform_create(self, serializer):
        book = Book.objects.get(pk=self.kwargs['book_pk'])
        serializer.save(book=book)

class AmbientSoundViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AmbientSound.objects.all()
    serializer_class = AmbientSoundSerializer
    permission_classes = [permissions.AllowAny]

    def list(self, request, *args, **kwargs):
        system_sounds = AmbientSound.objects.filter(is_system=True)
        user_sounds = []
        if request.user.is_authenticated:
            user_sounds = UserAmbientSound.objects.filter(user=request.user)
        
        results = [AmbientSoundSerializer(s).data for s in system_sounds]
        for us in user_sounds:
            sound_data = UserAmbientSoundSerializer(us, context={'request': request}).data
            results.append({
                'id': sound_data['id'],
                'name': sound_data['name'],
                'emoji': sound_data['emoji'],
                'audio_url': sound_data['audio_file'], # DRF serializes FileField to absolute URL
                'is_system': False
            })
        return Response(results)

class UserAmbientSoundViewSet(viewsets.ModelViewSet):
    serializer_class = UserAmbientSoundSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserAmbientSound.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class PurchaseViewSet(viewsets.ModelViewSet):
    queryset = Purchase.objects.all()
    serializer_class = PurchaseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Purchase.objects.filter(user=self.request.user)

    @action(detail=False, methods=['post'])
    def create_session(self, request):
        book_id = request.data.get('book_id')
        try:
            book = Book.objects.get(id=book_id)
            session = create_stripe_checkout_session(request.user, book)
            return Response({'sessionId': session.id, 'url': session.url})
        except Book.DoesNotExist:
            return Response({'error': 'Book not found'}, status=404)
        except Exception as e:
            return Response({'error': str(e)}, status=400)

@csrf_exempt
def stripe_webhook(request):
    payload = request.body
    sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')
    event = None

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        return Response(status=400)
    except stripe.error.SignatureVerificationError:
        return Response(status=400)

    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        fulfill_purchase(session)

    return Response(status=200)
