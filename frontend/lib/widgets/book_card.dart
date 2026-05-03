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
  final bool isCompact;

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
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double cardHeight = isCompact ? 280 : 500;
    final double padding = isCompact ? 12 : 20;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isCompact ? 5 : 20, 
          vertical: isCompact ? 5 : 10
        ),
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCompact ? 20 : 30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: isCompact ? 10 : 20,
              offset: Offset(0, isCompact ? 5 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 20 : 30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              coverUrl.isEmpty
                  ? Container(color: Colors.grey[900], child: Icon(Icons.book, size: isCompact ? 30 : 50, color: Colors.white24))
                  : (coverUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[900]),
                          errorWidget: (context, url, error) => Icon(Icons.book, size: isCompact ? 30 : 50, color: Colors.white24),
                        )
                      : (kIsWeb
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.book, size: isCompact ? 30 : 50, color: Colors.white24),
                            )
                          : Image.file(
                              File(coverUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.book, size: isCompact ? 30 : 50, color: Colors.white24),
                            ))),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: isCompact ? 0.9 : 0.8),
                    ],
                  ),
                ),
              ),
              // Bottom Content
              Positioned(
                bottom: padding,
                left: padding,
                right: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isCompact ? 2 : 5),
                    Text(
                      'by $author',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: isCompact ? 10 : 20),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '$likes',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.cloud_download_rounded, color: Color(0xFF00D2FF), size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '$downloads',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onPlay,
                            borderRadius: BorderRadius.circular(20),
                            child: GlassmorphicContainer(
                              width: isCompact ? 75 : 100,
                              height: isCompact ? 32 : 40,
                              borderRadius: 20,
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: isCompact ? 16 : 20),
                                  const SizedBox(width: 2),
                                  Text(
                                    isCompact ? 'Play' : 'Listen', 
                                    style: TextStyle(color: Colors.white, fontSize: isCompact ? 11 : 13)
                                  ),
                                ],
                              ),
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
