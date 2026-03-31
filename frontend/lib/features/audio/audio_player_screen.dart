import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/audio_provider.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final String author;
  final String coverUrl;

  const AudioPlayerScreen({
    super.key,
    required this.title,
    required this.author,
    required this.coverUrl,
  });

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerNotifierProvider.notifier).play(
        MediaItem(
          id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // Placeholder
          title: widget.title,
          album: 'Bookify',
          artist: widget.author,
          artUri: Uri.parse(widget.coverUrl),
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final playerNotifier = ref.read(playerNotifierProvider.notifier);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred Background
          CachedNetworkImage(
            imageUrl: widget.coverUrl,
            fit: BoxFit.cover,
          ),
          GlassmorphicContainer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
            blur: 40,
            alignment: Alignment.center,
            border: 0,
            linearGradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
            borderGradient: LinearGradient(colors: [Colors.transparent, Colors.transparent]),
          ),
          
          // Player Content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40)),
                      const Text('Now Playing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
                    ],
                  ),
                ),
                const Spacer(),
                // Book Cover
                Hero(
                  tag: 'book-cover-${widget.title}',
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 15)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: CachedNetworkImage(imageUrl: widget.coverUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const Spacer(),
                // Title and Author
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Text(widget.author, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Slider(
                        value: playerState.position.inSeconds.toDouble(),
                        max: playerState.totalDuration.inSeconds.toDouble().clamp(1.0, double.infinity),
                        onChanged: (v) => playerNotifier.seek(Duration(seconds: v.toInt())),
                        activeColor: const Color(0xFF6C63FF),
                        inactiveColor: Colors.white24,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(playerState.position), style: const TextStyle(color: Colors.white54)),
                          Text(_formatDuration(playerState.totalDuration), style: const TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: () => playerNotifier.seek(playerState.position - const Duration(seconds: 10)), icon: const Icon(Icons.replay_10_rounded, size: 35)),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => playerNotifier.togglePlay(),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                        child: Icon(playerState.status == PlayerStatus.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 50, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(onPressed: () => playerNotifier.seek(playerState.position + const Duration(seconds: 30)), icon: const Icon(Icons.forward_30_rounded, size: 35)),
                  ],
                ),
                const SizedBox(height: 40),
                // Speed Control
                OutlinedButton(
                  onPressed: () {
                    double nextSpeed = playerState.playbackSpeed >= 2.0 ? 1.0 : playerState.playbackSpeed + 0.5;
                    playerNotifier.setSpeed(nextSpeed);
                  },
                  child: Text('${playerState.playbackSpeed}x Speed'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
