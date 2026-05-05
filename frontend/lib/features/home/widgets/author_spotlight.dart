import 'package:flutter/material.dart';
import '../../../models/profile_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../profile/profile_screen.dart';

class AuthorSpotlight extends StatelessWidget {
  final List<ProfileModel> authors;

  const AuthorSpotlight({super.key, required this.authors});

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Author Spotlight',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: authors.length,
            itemBuilder: (context, index) {
              final author = authors[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(targetUserId: author.userId),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFFFF6B6B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E2E),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[900],
                            backgroundImage: author.avatar != null
                                ? CachedNetworkImageProvider(author.avatar!)
                                : null,
                            child: author.avatar == null
                                ? const Icon(Icons.person, color: Colors.white54)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        author.username,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
