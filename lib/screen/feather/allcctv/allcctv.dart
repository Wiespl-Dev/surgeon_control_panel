import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoGridScreen extends StatefulWidget {
  @override
  _VideoGridScreenState createState() => _VideoGridScreenState();
}

class _VideoGridScreenState extends State<VideoGridScreen> {
  final List<List<String>> videoData = [
    ["osgndmRBjsM"],
    ["_MTER8jQSFQ", "sPyZRkkxqNs"],
    ["lp4eRla1vFg", "osgndmRBjsM", "_MTER8jQSFQ"],
    ["sPyZRkkxqNs", "lp4eRla1vFg", "osgndmRBjsM", "_MTER8jQSFQ"],
  ];

  void _openFullscreenPlayer(String videoId) {
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: true,
        disableDragSeek: false,
        loop: false,
        forceHD: true,
        enableCaption: true,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.blueAccent,
              progressColors: ProgressBarColors(
                playedColor: Colors.blue,
                handleColor: Colors.blueAccent,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.grey[300]!,
              ),
              onReady: () {
                controller.addListener(() {});
              },
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                FullScreenButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCTV'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + 20,
            left: 12,
            right: 12,
            bottom: 12,
          ),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: videoData.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullscreenPlayer(videoData[index][0]),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildVideoGrid(videoData[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGrid(List<String> videoIds) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFEAC5E).withOpacity(0.7),
            Color(0xFFC779D0).withOpacity(0.7)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _getVideoLayout(videoIds),
    );
  }

  Widget _getVideoLayout(List<String> videoIds) {
    switch (videoIds.length) {
      case 1:
        return _singleVideo(videoIds[0]);
      case 2:
        return _twoVideos(videoIds[0], videoIds[1]);
      case 3:
        return _threeVideos(videoIds[0], videoIds[1], videoIds[2]);
      case 4:
        return _fourVideos(videoIds[0], videoIds[1], videoIds[2], videoIds[3]);
      default:
        return _singleVideo(videoIds[0]);
    }
  }

  Widget _singleVideo(String videoId) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[800],
          ),
        ),
        Center(
          child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
        ),
      ],
    );
  }

  Widget _twoVideos(String videoId1, String videoId2) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://img.youtube.com/vi/$videoId1/mqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                ),
              ),
              Center(
                child:
                    Icon(Icons.play_circle_fill, size: 30, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://img.youtube.com/vi/$videoId2/mqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                ),
              ),
              Center(
                child:
                    Icon(Icons.play_circle_fill, size: 30, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _threeVideos(String videoId1, String videoId2, String videoId3) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://img.youtube.com/vi/$videoId1/mqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                ),
              ),
              Center(
                child:
                    Icon(Icons.play_circle_fill, size: 40, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$videoId2/mqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                      ),
                    ),
                    Center(
                      child: Icon(Icons.play_circle_fill,
                          size: 25, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$videoId3/mqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                      ),
                    ),
                    Center(
                      child: Icon(Icons.play_circle_fill,
                          size: 25, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fourVideos(
      String videoId1, String videoId2, String videoId3, String videoId4) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$videoId1/mqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                      ),
                    ),
                    Center(
                      child: Icon(Icons.play_circle_fill,
                          size: 25, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$videoId2/mqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                      ),
                    ),
                    Center(
                      child: Icon(Icons.play_circle_fill,
                          size: 25, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$videoId3/mqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                      ),
                    ),
                    Center(
                      child: Icon(Icons.play_circle_fill,
                          size: 25, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$videoId4/mqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                      ),
                    ),
                    Center(
                      child: Icon(Icons.play_circle_fill,
                          size: 25, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
