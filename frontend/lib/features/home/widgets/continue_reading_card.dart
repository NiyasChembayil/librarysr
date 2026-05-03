import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reading_progress_model.dart';
import '../../../providers/book_provider.dart';
import '../../book/reader_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ContinueReadingCard extends ConsumerWidget {
  final ReadingProgressModel progress;

  const ContinueReadingCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Book Cover Mini
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: progress.bookCover != null
                ? CachedNetworkImage(
                    imageUrl: progress.bookCover!,
                    width: 50,
                    height: 75,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 50,
                    height: 75,
                    color: Colors.grey[900],
                    child: const Icon(Icons.book, size: 20),
                  ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTINUE READING',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress.bookTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Chapter ${progress.chapterIndex + 1}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.progressPercentage,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Resume Button
          IconButton(
            onPressed: () async {
              final book = await ref.read(currentBookProvider(progress.bookId).future);
              if (book != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(
                      bookId: book.id,
                      title: book.title,
                      chapters: book.chapters,
                      initialChapterIndex: progress.chapterIndex,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF6C63FF), size: 40),
          ),
        ],
      ),
    );
  }
}
