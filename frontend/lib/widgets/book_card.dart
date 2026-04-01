import 'dart:io';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'follow_button.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String coverUrl;
  final int likes;
  final VoidCallback onPlay;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.likes,
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
              color: Colors.black.withValues(alpha: 0.3),
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
              coverUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) => const Icon(Icons.book),
                    )
                  : Image.file(
                      File(coverUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.book),
                    ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
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
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'by $author',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FollowButton(authorUsername: author, isCompact: true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                            const SizedBox(width: 5),
                            Text(
                              '$likes',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        GlassmorphicContainer(
                          width: 120,
                          height: 50,
                          borderRadius: 25,
                          blur: 10,
                          alignment: Alignment.center,
                          border: 1,
                          linearGradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF).withValues(alpha: 0.5),
                              const Color(0xFF00D2FF).withValues(alpha: 0.5),
                            ],
                          ),
                          child: InkWell(
                            onTap: onPlay,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: Colors.white),
                                SizedBox(width: 5),
                                Text('Listen', style: TextStyle(color: Colors.white)),
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
