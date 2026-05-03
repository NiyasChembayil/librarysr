import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/book_card.dart';
import '../settings/settings_screen.dart';
import '../book/book_detail_screen.dart';
import 'user_list_screen.dart';
import '../../core/api_client.dart';
import '../../providers/post_provider.dart';
import '../feed/widgets/post_card.dart';
import '../../models/profile_model.dart';
import '../../providers/social_provider.dart';

final externalProfileProvider = FutureProvider.family<ProfileModel?, String>((ref, profileId) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final response = await apiClient.dio.get('accounts/profile/by_user/$profileId/');
    return ProfileModel.fromJson(response.data);
  } catch (e) {
    return null;
  }
});

final activityProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, profileId) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final response = await apiClient.dio.get('accounts/profile/$profileId/activity/');
    final data = response.data['activity'] as List;
    return data.map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    return [];
  }
});

final authorBooksProvider = FutureProvider.family<List<BookModel>, String>((ref, authorId) async {
  final apiClient = ref.read(apiClientProvider);
  debugPrint("🚀 Fetching author books | authorId: $authorId");
  try {
    final endpoint = 'core/books/?author=$authorId';
    final response = await apiClient.dio.get(endpoint);
    debugPrint("✅ API Response [${response.statusCode}] for $authorId | endpoint: $endpoint");
    
    final responseData = response.data;
    final List rawList = responseData is Map ? (responseData['results'] ?? []) : (responseData as List? ?? []);
    
    final List<BookModel> validBooks = [];
    for (var j in rawList) {
      try {
        validBooks.add(BookModel.fromJson(j));
      } catch (err) {
        debugPrint("⚠️ Skipping book ID ${j['id']} due to parsing error: $err");
      }
    }
    debugPrint("📦 Successfully parsed ${validBooks.length} out of ${rawList.length} books for $authorId");
    
    if (validBooks.isEmpty && rawList.isNotEmpty) {
      throw Exception("Parsing failed: Found ${rawList.length} entries but 0 were valid. Possible model mismatch.");
    }
    
    return validBooks;
  } catch (e) {
    debugPrint("🔥 Network Error fetching author books for $authorId: $e");
    String errorMsg = e.toString();
    if (e is DioException) {
      errorMsg = "API Error [${e.response?.statusCode}]: ${e.response?.data ?? e.message}";
    }
    throw Exception(errorMsg);
  }
});

class ProfileScreen extends ConsumerStatefulWidget {
  final int? targetUserId;
  const ProfileScreen({super.key, this.targetUserId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    Future.microtask(() {
      final auth = ref.read(authProvider.notifier);
      final authState = ref.read(authProvider);
      
      auth.refreshProfile();
      
      final effectiveUserId = widget.targetUserId ?? authState.profile?.userId;
      if (effectiveUserId != null) {
        ref.read(postFeedProvider.notifier).loadUserPosts(effectiveUserId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final myProfile = authState.profile;
    
    // If we have a targetUserId (navigated from post), compare it with the logged-in User ID.
    // If not, it's definitely 'me'.
    final isMe = widget.targetUserId == null || (myProfile != null && widget.targetUserId == myProfile.userId);
    
    // If it's not me, we need to load the other user's profile
    final profileAsync = !isMe 
        ? ref.watch(externalProfileProvider(widget.targetUserId!.toString()))
        : AsyncValue.data(myProfile);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, stack) => _buildErrorState(ref, context, e.toString()),
      data: (profile) {
        if (profile == null) {
          return _buildErrorState(ref, context, 'Profile could not be loaded. Your session may have expired.');
        }

        // Use 'me' for current user (to see drafts), or profile.userId for others.
        final authorIdKey = isMe ? 'me' : profile.userId.toString();
        final authorBooksAsync = ref.watch(authorBooksProvider(authorIdKey));
        final activityAsync = ref.watch(activityProvider(profile.id));
        final postState = ref.watch(postFeedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Cinematic Banner & Avatar Stack
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Banner
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(25),
                          image: profile?.banner != null
                              ? DecorationImage(image: NetworkImage(profile!.banner!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: profile?.banner == null
                            ? Center(
                                child: Icon(Icons.auto_awesome_mosaic_rounded, 
                                  color: Colors.white.withValues(alpha: 0.05), size: 50),
                              )
                            : null,
                      ),
                      // Back & Settings overlay
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (Navigator.canPop(context))
                              _glassButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              )
                            else
                              const SizedBox(width: 45),
                            _glassButton(
                              icon: Icons.settings_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Overlapping Avatar
                      Positioned(
                        bottom: -45,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0A0A12),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: const Color(0xFF1E1E2E),
                            backgroundImage: profile?.avatar != null
                                ? NetworkImage(profile!.avatar!)
                                : null,
                            child: profile?.avatar == null
                                ? Text(
                                    (profile?.username ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 55),

                  // Username & Role
                  Text(
                    profile?.username ?? 'User',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (profile?.role ?? 'reader').toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF), letterSpacing: 1),
                    ),
                  ),


                  // Bio
                  if (profile?.bio != null && profile!.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 15),
                      child: Text(
                        profile.bio, 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.white54, fontSize: 13)
                      ),
                    ),

                  // Follow Button (Only for others)
                  if (!isMe && profile != null)
                    Consumer(
                      builder: (context, ref, _) {
                        final socialState = ref.watch(socialProvider);
                        final isFollowing = socialState[profile.username] ?? profile.isFollowing;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: SizedBox(
                            width: 200,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () async {
                                await ref.read(socialProvider.notifier).toggleFollow(profile.username, profile.id);
                                // Refresh profile to update counts
                                ref.invalidate(externalProfileProvider(profile.userId.toString()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing ? Colors.transparent : const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                elevation: isFollowing ? 0 : 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: isFollowing 
                                    ? BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5)
                                    : BorderSide.none,
                                ),
                              ).copyWith(
                                overlayColor: MaterialStateProperty.all(Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Text(
                                isFollowing ? 'Following' : 'Follow',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        authorBooksAsync.when(
                          data: (books) {
                            final totalReads = books.fold<int>(0, (sum, b) => sum + b.totalReads);
                            return _buildStatItem('Reads', '$totalReads');
                          },
                          loading: () => _buildStatItem('Reads', '...'),
                          error: (_, __) => _buildStatItem('Reads', '0'),
                        ),
                        _buildVerticalDivider(),
                        _buildStatItem(
                          'Followers',
                          '${profile?.followersCount ?? 0}',
                          onTap: () {
                            if (profile != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserListScreen(
                                    title: 'Followers',
                                    endpoint: 'accounts/profile/${profile.id}/followers/',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        _buildVerticalDivider(),
                        _buildStatItem(
                          'Following',
                          '${profile?.followingCount ?? 0}',
                          onTap: () {
                            if (profile != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserListScreen(
                                    title: 'Following',
                                    endpoint: 'accounts/profile/${profile.id}/following/',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF6C63FF),
                indicatorWeight: 3,
                labelColor: const Color(0xFF6C63FF),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Works'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Posts Tab
            _buildPostsTab(postState),
            // Works Tab
            _buildWorksTab(profile, authorBooksAsync, ref),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildPostsTab(PostFeedState state) {
    return RefreshIndicator(
      onRefresh: () async {
        final authState = ref.read(authProvider);
        final effectiveUserId = widget.targetUserId ?? authState.profile?.userId;
        if (effectiveUserId != null) {
          await ref.read(postFeedProvider.notifier).loadUserPosts(effectiveUserId);
        }
      },
      color: const Color(0xFF6C63FF),
      child: state.isUserPostsLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : state.userPosts.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            "Nothing yet. Join the conversation!",
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 100),
                  itemCount: state.userPosts.length,
                  itemBuilder: (context, index) => PostCard(post: state.userPosts[index]),
                ),
    );
  }

  Widget _buildWorksTab(ProfileModel profile, AsyncValue<List<BookModel>> booksAsync, WidgetRef ref) {
    final myProfile = ref.read(authProvider).profile;
    final isMe = widget.targetUserId == null || (myProfile != null && widget.targetUserId == myProfile.userId);
    
    return RefreshIndicator(
      onRefresh: () async {
        final key = isMe ? 'me' : profile.userId.toString();
        ref.invalidate(authorBooksProvider(key));
      },
      color: const Color(0xFF6C63FF),
      child: booksAsync.when(
        data: (myBooks) {
          if (myBooks.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 40),
                Center(child: _buildNoBooksPlaceholder()),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () => ref.invalidate(authorBooksProvider(isMe ? 'me' : profile.userId.toString())),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("FORCE REFRESH", style: TextStyle(fontSize: 10, color: Colors.white38)),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartSection(ref, profile.id),
                const SizedBox(height: 30),
                
                Text(
                  isMe ? 'My Portfolio' : "${profile.username}'s Portfolio", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 15),
                
                // Grid of books
                MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  itemCount: myBooks.length,
                  itemBuilder: (context, index) {
                    final book = myBooks[index];
                    return Stack(
                      children: [
                        BookCard(
                          title: book.title,
                          author: book.authorName,
                          authorProfileId: book.authorProfileId,
                          isAuthorFollowing: book.isAuthorFollowing,
                          coverUrl: book.coverUrl,
                          likes: book.likesCount,
                          downloads: book.downloadsCount,
                          isCompact: true,
                          onPlay: () {},
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookDetailScreen(
                                  id: book.id,
                                  title: book.title,
                                  author: book.authorName,
                                  coverUrl: book.coverUrl,
                                  description: book.description,
                                ),
                              ),
                            );
                          },
                        ),
                        if (isMe)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              icon: Icon(
                                book.isFeatured ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                color: book.isFeatured ? const Color(0xFF6C63FF) : Colors.white54,
                                size: 20,
                              ),
                              onPressed: () async {
                                final apiClient = ref.read(apiClientProvider);
                                try {
                                  await apiClient.dio.post('core/books/${book.id}/toggle_featured/');
                                  ref.invalidate(authorBooksProvider('me'));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
        error: (err, stack) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      'Connection Error:\n$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(authorBooksProvider(isMe ? 'me' : profile.userId.toString())),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                      child: const Text("Retry Connection"),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksList(BuildContext context, List<BookModel> books, {bool isMe = false}) {
    return SizedBox(
      height: 340,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 250,
            child: Column(
              children: [
                Transform.scale(
                  scale: 0.7,
                  alignment: Alignment.topLeft,
                  child: BookCard(
                    title: book.title,
                    author: book.authorName,
                    authorProfileId: book.authorProfileId,
                    isAuthorFollowing: book.isAuthorFollowing,
                    coverUrl: book.coverUrl,
                    likes: book.likesCount,
                    downloads: book.downloadsCount,
                    onPlay: () {},
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailScreen(
                            id: book.id,
                            title: book.title,
                            author: book.authorName,
                            coverUrl: book.coverUrl,
                            description: book.description,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 0),
                    child: TextButton.icon(
                      onPressed: () async {
                        final apiClient = ref.read(apiClientProvider);
                        try {
                          await apiClient.dio.post('core/books/${book.id}/toggle_featured/');
                          ref.invalidate(authorBooksProvider('me'));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating featured status: $e')),
                          );
                        }
                      },
                      icon: Icon(
                        book.isFeatured ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 14,
                        color: book.isFeatured ? const Color(0xFF6C63FF) : Colors.white38,
                      ),
                      label: Text(
                        book.isFeatured ? 'Unpin from Top' : 'Pin to Top',
                        style: TextStyle(
                          fontSize: 10, 
                          color: book.isFeatured ? const Color(0xFF6C63FF) : Colors.white38,
                          fontWeight: book.isFeatured ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(height: 35, width: 1, color: Colors.white10);

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildChartSection(WidgetRef ref, int profileId) {
    final activityAsync = ref.watch(activityProvider(profileId));
    final myProfile = ref.read(authProvider).profile;
    final isMe = myProfile?.userId == profileId;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Reading Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('Last 5 weeks', style: TextStyle(fontSize: 10, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text('Your engagement over the last 35 days.', style: TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 25),
          SizedBox(
            height: 150,
            child: activityAsync.when(
              data: (data) {
                if (data.isEmpty) return const Center(child: Text("No activity yet", style: TextStyle(color: Colors.white24)));
                
                final maxCount = data.map((e) => e['count'] as int).fold(0, (max, e) => e > max ? e : max);
                final maxY = maxCount > 10 ? (maxCount + 2).toDouble() : 10.0;

                return _buildHeatmap(data);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Icon(Icons.error_outline, color: Colors.white24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(List<Map<String, dynamic>> data) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              return Expanded(
                child: Center(
                  child: Text(
                    'W${index + 1}', 
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 10, fontWeight: FontWeight.w600)
                  ),
                ),
              );
            }),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final count = data[index]['count'] as int;
            Color color;
            if (count == 0) {
              color = Colors.white.withValues(alpha: 0.08);
            } else if (count < 3) {
              color = const Color(0xFF6C63FF).withValues(alpha: 0.4);
            } else if (count < 6) {
              color = const Color(0xFF6C63FF).withValues(alpha: 0.7);
            } else {
              color = const Color(0xFF6C63FF);
            }

            return Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: count > 0 ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  )
                ] : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoBooksPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_stories_rounded, size: 48, color: Colors.white24),
          SizedBox(height: 12),
          Text("You haven't published any books yet.", style: TextStyle(color: Colors.white54)),
          SizedBox(height: 6),
          Text('Tap the + tab to start creating!', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, BuildContext context, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 80, color: Colors.white24),
              const SizedBox(height: 24),
              const Text(
                'Connection Error',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).refreshProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully. Please log in again.'))
                    );
                  }
                },
                child: const Text(
                  'Force Logout',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0A0A12),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
