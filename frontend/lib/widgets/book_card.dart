import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'follow_button.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final int authorProfileId;
  final bool isAuthorFollowing;
  final String coverUrl;
  final int likes;
  final int downloads;
  final VoidCallback onPlay;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.authorProfileId,
    required this.isAuthorFollowing,
    required this.coverUrl,
    required this.likes,
    required this.downloads,
    required this.onPlay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              coverUrl.isEmpty
                  ? Container(color: Colors.grey[900], child: const Icon(Icons.book, size: 50, color: Colors.white24))
                  : (coverUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[900]),
                          errorWidget: (context, url, error) => const Icon(Icons.book, size: 50, color: Colors.white24),
                        )
                      : (kIsWeb
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 50, color: Colors.white24),
                            )
                          : Image.file(
                              File(coverUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 50, color: Colors.white24),
                            ))),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              // Bottom Content
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'by $author',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FollowButton(
                          authorUsername: author,
                          authorProfileId: authorProfileId,
                          initialIsFollowing: isAuthorFollowing,
                          isCompact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '$likes',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.cloud_download_rounded, color: Color(0xFF00D2FF), size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '$downloads',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassmorphicContainer(
                          width: 100,
                          height: 40,
                          borderRadius: 25,
                          blur: 10,
                          alignment: Alignment.center,
                          border: 1,
                          linearGradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF).withOpacity(0.5),
                              const Color(0xFF00D2FF).withOpacity(0.5),
                            ],
                          ),
                          child: InkWell(
                            onTap: onPlay,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 2),
                                Text('Listen', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
