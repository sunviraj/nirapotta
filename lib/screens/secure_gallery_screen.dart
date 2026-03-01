import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/glass_container.dart';

class SecureGalleryScreen extends StatefulWidget {
  const SecureGalleryScreen({super.key});

  @override
  State<SecureGalleryScreen> createState() => _SecureGalleryScreenState();
}

class _SecureGalleryScreenState extends State<SecureGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<File> _imageFiles = [];
  List<File> _videoFiles = [];
  List<File> _audioFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvidence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvidence() async {
    try {
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/evidence';
      final Directory directory = Directory(dirPath);

      if (await directory.exists()) {
        final files = directory.listSync().whereType<File>().toList();
        // Sort by modified date descending
        files.sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

        setState(() {
          _imageFiles = files
              .where((f) =>
                  f.path.endsWith('.jpg') ||
                  f.path.endsWith('.png') ||
                  f.path.endsWith('.jpeg'))
              .toList();
          _videoFiles = files.where((f) => f.path.endsWith('.mp4')).toList();
          _audioFiles = files
              .where((f) => f.path.endsWith('.m4a') || f.path.endsWith('.mp3'))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading evidence: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Confidential Evidence',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "Images", icon: Icon(Icons.image)),
            Tab(text: "Videos", icon: Icon(Icons.videocam)),
            Tab(text: "Audios", icon: Icon(Icons.mic)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1E1E), Color(0xFF2D1B2E)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMediaList(_imageFiles, "Images"),
                    _buildMediaList(_videoFiles, "Videos"),
                    _buildMediaList(_audioFiles, "Audios"),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMediaList(List<File> files, String type) {
    if (files.isEmpty) {
      return Center(
        child: Text('No $type recorded yet.',
            style: const TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isVideo = file.path.endsWith('.mp4');
        final isAudio =
            file.path.endsWith('.m4a') || file.path.endsWith('.mp3');

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: ListTile(
            leading: Icon(
              isVideo ? Icons.videocam : (isAudio ? Icons.mic : Icons.image),
              color: isVideo
                  ? Colors.blueAccent
                  : (isAudio ? Colors.orangeAccent : Colors.greenAccent),
              size: 32,
            ),
            title: Text(file.uri.pathSegments.last,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              file.lastModifiedSync().toString(),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.blue),
                  onPressed: () => _shareFile(file),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteFile(file),
                ),
              ],
            ),
            onTap: () => _openMedia(file, isVideo, isAudio),
          ),
        );
      },
    );
  }

  Future<void> _shareFile(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)],
          text: 'Secure Evidence from Nirapotta');
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }

  Future<void> _deleteFile(File file) async {
    // Show confirmation dialog before deleting
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Evidence?',
            style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await file.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Evidence deleted successfully'),
              backgroundColor: Colors.red),
        );
        _loadEvidence(); // Refresh lists after deletion
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }
  }

  void _openMedia(File file, bool isVideo, bool isAudio) {
    if (isVideo) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(file: file)));
    } else if (isAudio) {
      _playAudioDialog(file);
    } else {
      _showImageDialog(file);
    }
  }

  void _showImageDialog(File file) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.black87),
              ),
              InteractiveViewer(
                child: Image.file(file),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _playAudioDialog(File file) {
    final player = AudioPlayer();
    bool isPlaying = true;

    player.play(DeviceFileSource(file.path));

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Audio Evidence',
                  style: TextStyle(color: Colors.white)),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 48,
                    color: Colors.amber.shade400,
                    icon: Icon(isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled),
                    onPressed: () {
                      if (isPlaying) {
                        player.pause();
                      } else {
                        player.resume();
                      }
                      setDialogState(() {
                        isPlaying = !isPlaying;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    player.stop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close',
                      style: TextStyle(color: Colors.white70)),
                )
              ],
            );
          });
        }).then((_) => player.dispose());
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File file;
  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Evidence'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                    Center(
                      child: IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
