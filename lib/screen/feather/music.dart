// music_player_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:surgeon_control_panel/provider/audioProvider.dart';
import 'dart:convert';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class Music {
  final int id;
  final String name;
  final String fileUrl;
  final bool isAsset;

  Music({
    required this.id,
    required this.name,
    required this.fileUrl,
    this.isAsset = false,
  });

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(id: json['id'], name: json['name'], fileUrl: json['file_url']);
  }
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final List<Music> _musicList = [];
  final List<Music> _assetMusicList = [];
  bool _isLoading = true;

  // Use your actual server IP
  final String _baseUrl = 'http://192.168.0.101:3000/api';

  @override
  void initState() {
    super.initState();
    _loadAssetMusic();
    _loadMusic();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = Provider.of<MusicPlayerProvider>(
        context,
        listen: false,
      );
      playerProvider.initAudioSession();
    });
  }

  void _loadAssetMusic() {
    _assetMusicList.addAll([
      Music(
        id: -1,
        name: 'Gayatri Mantra',
        fileUrl: 'assets/music/Gayatri Mantra_128-(PagalWorld.Org.Im).mp3',
        isAsset: true,
      ),
      Music(
        id: -2,
        name: 'He Ram He Ram',
        fileUrl: 'assets/music/He Ram He Ram-320kbps.mp3',
        isAsset: true,
      ),
      Music(
        id: -3,
        name: 'Mahamrityunjay Mantra',
        fileUrl:
            'assets/music/Mahamrityunjay Mantra महमतयजय मतर Om Trayambakam Yajamahe.mp3',
        isAsset: true,
      ),
      Music(
        id: -4,
        name: 'Shiv Namaskarartha Mantra',
        fileUrl:
            'assets/music/Shiv Namaskarartha Mantra  Monday Special  LoFi Version.mp3',
        isAsset: true,
      ),
      Music(
        id: -5,
        name: 'Sri Venkatesha Stotram',
        fileUrl:
            'assets/music/Sri Venkatesha Stotram - Invoking the Lord\'s Mercy _ New Year 2025.mp3',
        isAsset: true,
      ),
      Music(
        id: -6,
        name: 'Sri Venkateshwara Suprabhatham',
        fileUrl: 'assets/music/Sri Venkateshwara Suprabhatham-320kbps.mp3',
        isAsset: true,
      ),
      Music(
        id: -7,
        name: 'Shree Hanuman Chalisa',
        fileUrl:
            'assets/music/शर हनमन चलस  Shree Hanuman Chalisa Original Video  GULSHAN KUMAR  HARIHARAN Full HD.mp3',
        isAsset: true,
      ),
    ]);
  }

  Future<void> _loadMusic() async {
    try {
      print('Loading music from: $_baseUrl/music');
      final response = await http.get(Uri.parse('$_baseUrl/music'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _musicList.clear();
          _musicList.addAll(data.map((json) => Music.fromJson(json)));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading music: $e');
      _showError('Failed to load music. Check server connection.');
    }
  }

  Future<void> _uploadMusic() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final String? musicName = await showDialog<String>(
          context: context,
          builder: (context) {
            String name = file.name.split('.').first;
            return AlertDialog(
              title: const Text('Add Music'),
              content: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Music Name',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: name),
                onChanged: (value) => name = value,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, name),
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );

        if (musicName != null && musicName.isNotEmpty) {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('$_baseUrl/music'),
          );
          request.fields['name'] = musicName;
          request.files.add(
            http.MultipartFile.fromBytes(
              'music_file',
              file.bytes!,
              filename: file.name,
            ),
          );

          final response = await request.send();
          if (response.statusCode == 200) {
            _showSuccess('Music uploaded successfully!');
            _loadMusic();
          } else {
            _showError('Upload failed: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      _showError('Upload error: $e');
    }
  }

  Future<void> _playMusic(int index, MusicPlayerProvider playerProvider) async {
    try {
      final currentList = playerProvider.currentTab == 0
          ? _musicList
          : _assetMusicList;
      final music = currentList[index];

      if (playerProvider.currentIndex == index &&
          playerProvider.isPlaying &&
          _getCurrentMusic(playerProvider)?.id == music.id) {
        // Pause if same song is playing
        await playerProvider.player.pause();
      } else if (playerProvider.currentIndex == index &&
          !playerProvider.isPlaying &&
          _getCurrentMusic(playerProvider)?.id == music.id) {
        // Resume if same song is paused
        await playerProvider.player.play();
      } else {
        // Play new song
        if (music.isAsset) {
          await playerProvider.player.setAsset(music.fileUrl);
        } else {
          String fullUrl = music.fileUrl;
          if (!music.fileUrl.startsWith('http')) {
            fullUrl = '$_baseUrl/${music.fileUrl}';
          }
          await playerProvider.player.setUrl(fullUrl);
        }

        // Set up completion listener for looping
        playerProvider.player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (playerProvider.isLooping &&
                playerProvider.currentIndex != null) {
              _playMusic(playerProvider.currentIndex!, playerProvider);
            }
          }
        });

        await playerProvider.player.play();
        playerProvider.setCurrentIndex(index);
      }
    } catch (e) {
      _showError('Playback error: $e');
      print('Error playing music: $e');
    }
  }

  Music? _getCurrentMusic(MusicPlayerProvider playerProvider) {
    if (playerProvider.currentIndex == null) return null;
    final currentList = playerProvider.currentTab == 0
        ? _musicList
        : _assetMusicList;
    return playerProvider.currentIndex! < currentList.length
        ? currentList[playerProvider.currentIndex!]
        : null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteMusic(
    Music music,
    MusicPlayerProvider playerProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Music'),
        content: Text('Delete "${music.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('$_baseUrl/music/${music.id}'),
        );
        if (response.statusCode == 200) {
          _showSuccess('Music deleted');
          if (playerProvider.currentIndex != null &&
              _getCurrentMusic(playerProvider)?.id == music.id) {
            await playerProvider.stop();
          }
          _loadMusic();
        } else {
          _showError('Delete failed: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Delete failed: $e');
      }
    }
  }

  Widget _buildSongTile(
    int index,
    List<Music> musicList,
    MusicPlayerProvider playerProvider,
  ) {
    final music = musicList[index];
    final isCurrentPlaying =
        playerProvider.currentIndex == index &&
        _getCurrentMusic(playerProvider)?.id == music.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: isCurrentPlaying ? Colors.teal : Colors.teal[100],
          child: Icon(
            isCurrentPlaying && playerProvider.isPlaying
                ? Icons.pause
                : Icons.play_arrow,
            color: isCurrentPlaying ? Colors.white : Colors.black54,
          ),
        ),
        title: Text(
          music.name,
          style: TextStyle(
            fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              music.isAsset ? 'Default Music' : 'Server Music',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (isCurrentPlaying && playerProvider.isPlaying)
              LinearProgressIndicator(
                value: playerProvider.duration.inSeconds > 0
                    ? playerProvider.position.inSeconds /
                          playerProvider.duration.inSeconds
                    : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentPlaying && playerProvider.isPlaying)
              Icon(
                Icons.loop,
                color: playerProvider.isLooping ? Colors.orange : Colors.grey,
                size: 20,
              ),
            const SizedBox(width: 8),
            if (!music.isAsset) // Only show delete for server music
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteMusic(music, playerProvider),
              ),
          ],
        ),
        onTap: () => _playMusic(index, playerProvider),
      ),
    );
  }

  Widget _buildMusicList(
    List<Music> musicList,
    String emptyMessage,
    MusicPlayerProvider playerProvider,
  ) {
    if (musicList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: musicList.length,
      itemBuilder: (context, index) =>
          _buildSongTile(index, musicList, playerProvider),
    );
  }

  Widget _buildTab(
    int tabIndex,
    String title,
    int count,
    MusicPlayerProvider playerProvider,
  ) {
    return Expanded(
      child: Material(
        color: playerProvider.currentTab == tabIndex
            ? const Color(0xFF3D8A8F)
            : const Color(0xFF2C6B6F),
        child: InkWell(
          onTap: () {
            playerProvider.setCurrentTab(tabIndex);
            // Reset current index when switching tabs if the current music is from the other tab
            if (_getCurrentMusic(playerProvider)?.isAsset != (tabIndex == 1)) {
              playerProvider.setCurrentIndex(null);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: playerProvider.currentTab == tabIndex
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '($count)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentList = playerProvider.currentTab == 0
            ? _musicList
            : _assetMusicList;
        final currentMusic = _getCurrentMusic(playerProvider);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF3D8A8F),
            elevation: 6,
            title: const Text(
              'Music Player',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (playerProvider.isPlaying) ...[
                IconButton(
                  icon: Icon(
                    playerProvider.isLooping ? Icons.loop : Icons.loop_outlined,
                    color: playerProvider.isLooping
                        ? Colors.yellow
                        : Colors.white,
                  ),
                  onPressed: () => playerProvider.toggleLoop(),
                  tooltip: playerProvider.isLooping
                      ? 'Looping Enabled'
                      : 'Looping Disabled',
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.white),
                  onPressed: () => playerProvider.stop(),
                  tooltip: 'Stop Music',
                ),
              ],
              if (playerProvider.currentTab ==
                  0) // Only show refresh for server music
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadMusic,
                  tooltip: 'Refresh',
                ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3D8A8F), Color(0xFF3D8A8F)],
              ),
            ),
            child: Column(
              children: [
                // Tab Bar
                Container(
                  color: const Color(0xFF2C6B6F),
                  child: Row(
                    children: [
                      _buildTab(
                        0,
                        'Server Music',
                        _musicList.length,
                        playerProvider,
                      ),
                      _buildTab(
                        1,
                        'Default Music',
                        _assetMusicList.length,
                        playerProvider,
                      ),
                    ],
                  ),
                ),
                // Now Playing Section
                if (currentMusic != null && playerProvider.isPlaying)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white.withOpacity(0.1),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.music_note, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Now Playing: ${currentMusic.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (playerProvider.isLooping)
                              const Icon(
                                Icons.loop,
                                color: Colors.yellow,
                                size: 16,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: playerProvider.position.inSeconds.toDouble(),
                          min: 0,
                          max: playerProvider.duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            playerProvider.seekTo(
                              Duration(seconds: value.toInt()),
                            );
                          },
                          activeColor: Colors.white,
                          inactiveColor: Colors.white54,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(playerProvider.position),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                _formatDuration(playerProvider.duration),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Music List
                Expanded(
                  child: _isLoading && playerProvider.currentTab == 0
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _buildMusicList(
                          currentList,
                          playerProvider.currentTab == 0
                              ? 'No server music found\nTap + to add music'
                              : 'No Default music available',
                          playerProvider,
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: playerProvider.currentTab == 0
              ? FloatingActionButton(
                  onPressed: _uploadMusic,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3D8A8F),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: currentMusic != null && playerProvider.isPlaying
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, -1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentMusic.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentMusic.isAsset
                                  ? 'Default Music'
                                  : 'Server Music',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (playerProvider.isLooping)
                            Icon(Icons.loop, color: Colors.teal[800], size: 20),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              playerProvider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 30,
                              color: Colors.teal[800],
                            ),
                            onPressed: () => playerProvider.togglePlayPause(),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
