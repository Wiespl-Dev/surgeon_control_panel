import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();

  final List<Map<String, String>> _songs = [
    {
      'title': 'Ocean Breeze',
      'artist': 'Artist A',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'title': 'Sunset Harmony',
      'artist': 'Artist B',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
    {
      'title': 'Tranquil Echoes',
      'artist': 'Artist C',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    },
    {
      'title': 'Mystic Waves',
      'artist': 'Artist D',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    },
    {
      'title': 'Blissful Beats',
      'artist': 'Artist E',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    },
  ];

  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> _playSong(int index) async {
    try {
      await _player.setUrl(_songs[index]['url']!);
      _player.play();
      setState(() {
        _currentIndex = index;
      });
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Widget _buildSongTile(int index) {
    final song = _songs[index];
    final isPlaying = _currentIndex == index && _player.playing;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.teal[100],
          child: Icon(
            isPlaying ? Icons.music_note : Icons.music_video_outlined,
            color: isPlaying ? Colors.teal : Colors.black54,
          ),
        ),
        title: Text(
          song['title']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(song['artist']!),
        trailing: IconButton(
          icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          color: Colors.teal,
          iconSize: 32,
          onPressed: () => _playSong(index),
        ),
        onTap: () => _playSong(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 126, 163, 184),
        elevation: 6,
        title: const Text(
          'My Music',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Container(
        //  width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 124, 162, 184),
              Color.fromARGB(255, 191, 234, 234),
            ],
          ),
        ),
        child: ListView.builder(
          itemCount: _songs.length,
          itemBuilder: (context, index) => _buildSongTile(index),
        ),
      ),
      bottomNavigationBar: _currentIndex != null
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                    child: Text(
                      _songs[_currentIndex!]['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final playing = playerState?.playing ?? false;
                      return IconButton(
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          size: 30,
                          color: Colors.teal[800],
                        ),
                        onPressed: () {
                          if (playing) {
                            _player.pause();
                          } else {
                            _player.play();
                          }
                          setState(() {});
                        },
                      );
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
