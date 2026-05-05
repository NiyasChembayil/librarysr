import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/book_model.dart';
import '../../book/book_detail_screen.dart';

class HeroSection extends StatelessWidget {
  final BookModel book;

  const HeroSection({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
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
      ),
      child: SizedBox(
        height: 500,
        width: double.infinity,
        child: Stack(
          children: [
            // Blurred Background
            Positioned.fill(
              child: book.coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: book.coverUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(color: const Color(0xFF1E1E2E)),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        const Color(0xFF0F0F15).withValues(alpha: 0.8),
                        const Color(0xFF0F0F15),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Book Cover with Reflection/Shadow
                  Container(
                    height: 220,
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: book.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: book.coverUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.book, size: 50, color: Colors.white24),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      book.categoryName.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Title & Author
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${book.authorName}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Primary Action
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to details or start reading
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                    ),
                    child: const Text(
                      'START READING',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
