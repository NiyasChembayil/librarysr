import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';
import 'dart:math' as math;

class AudioPostPlayer extends StatefulWidget {
  final String audioUrl;
  const AudioPostPlayer({super.key, required this.audioUrl});

  @override
  State<AudioPostPlayer> createState() => _AudioPostPlayerState();
}

class _AudioPostPlayerState extends State<AudioPostPlayer> with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  String? _error;

  late AnimationController _visualizerController;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.audioUrl);
      _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading || 
                         state.processingState == ProcessingState.buffering;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load audio";
          _isLoading = false;
        });
      }
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.15),
                const Color(0xFF1E1E2E).withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildPlayButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Voice Update",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (_isPlaying)
                              _AudioVisualizer(
                                isPlaying: _isPlaying,
                                controller: _visualizerController,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildSlider(context),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: () {
        if (_isLoading) return;
        if (_isPlaying) {
          _player.pause();
        } else {
          if (_position >= _duration && _duration > Duration.zero) {
            _player.seek(Duration.zero);
          }
          _player.play();
        }
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7, elevation: 4),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: const Color(0xFF6C63FF),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        thumbColor: Colors.white,
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: _position.inMilliseconds.toDouble(),
        max: _duration.inMilliseconds.toDouble() > 0 
            ? _duration.inMilliseconds.toDouble() 
            : 1.0,
        onChanged: (value) {
          _player.seek(Duration(milliseconds: value.toInt()));
        },
      ),
    );
  }
}

class _AudioVisualizer extends StatelessWidget {
  final bool isPlaying;
  final AnimationController controller;

  const _AudioVisualizer({required this.isPlaying, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            double value = 0.3;
            if (isPlaying) {
              value = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(controller.value * 2 * math.pi + index));
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: 12 * value,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
