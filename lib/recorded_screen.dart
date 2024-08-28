import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecordedScreen extends StatefulWidget {
  final String videoPath;

  const RecordedScreen({super.key, required this.videoPath});

  @override
  _RecordedScreenState createState() => _RecordedScreenState();
}

class _RecordedScreenState extends State<RecordedScreen> {
  late VideoPlayerController _videoPlayerController;
  bool _isPlaying = false;
  bool _isMuted = false;

  String _overlayText = '';
  bool _showTextInput = false;
  final TextEditingController _textController = TextEditingController();
  Offset _textPosition = Offset(50, 50);

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController.play();
        _isPlaying = true;
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _videoPlayerController.pause();
      } else {
        _videoPlayerController.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoPlayerController.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _addTextOverlay() {
    setState(() {
      _overlayText = _textController.text;
      _showTextInput = false;
      _textController.clear();
    });
  }

  void _onTextInputFocusChange(bool hasFocus) {
    if (!hasFocus) {
      _addTextOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: height,
              width: width,
              color: Color(0xffFFFFFF),
              child: Column(
                children: [
                  SizedBox(height: height * 0.15),
                  Container(
                    height: height * 0.6,
                    width: width,
                    child: _videoPlayerController.value.isInitialized
                        ? Stack(
                            children: [
                              VideoPlayer(_videoPlayerController),
                              if (_overlayText.isNotEmpty)
                                Positioned(
                                  left: _textPosition.dx,
                                  top: _textPosition.dy,
                                  child: Draggable(
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: 200,
                                        ),
                                        child: Text(
                                          _overlayText,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Container(),
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: 200,
                                      ),
                                      child: Text(
                                        _overlayText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    onDragUpdate: (details) {
                                      setState(() {
                                        _textPosition = details.localPosition;
                                      });
                                    },
                                    onDragEnd: (details) {
                                      setState(() {
                                        _textPosition = _textPosition.translate(
                                          details.offset.dx,
                                          details.offset.dy,
                                        );
                                      });
                                    },
                                  ),
                                ),
                              Center(
                                child: GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Icon(
                                    _isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: 80,
                                  ),
                                ),
                              ),
                              if (_showTextInput)
                                Positioned(
                                  left: width * 0.25,
                                  top: height * 0.1,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: 200,
                                    ),
                                    child: TextField(
                                      controller: _textController,
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        hintText: "Enter text",
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                      ),
                                      onSubmitted: (_) => _addTextOverlay(),
                                      onTap: () {
                                        setState(() {
                                          _textPosition = _textPosition;
                                        });
                                      },
                                      onEditingComplete: () =>
                                          _onTextInputFocusChange(false),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Center(child: CircularProgressIndicator()),
                  ),
                  SizedBox(
                    height: height * 0.03,
                  ),
                  Container(
                    height: height * 0.05,
                    width: width,
                    color: Colors.amber,
                  ),
                  SizedBox(
                    height: height * 0.04,
                  ),
                  Row(
                    children: [
                      SizedBox(width: width * 0.05),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showTextInput = !_showTextInput;
                          });
                        },
                        child: _buildBottomBarButton('Text', Icons.text_format),
                      ),
                      SizedBox(width: width * 0.05),
                      _buildBottomBarButton('Effects', Icons.refresh),
                      SizedBox(width: width * 0.05),
                      _buildBottomBarButton('Stickers', Icons.emoji_emotions),
                      Spacer(),
                      Container(
                        height: height * 0.07,
                        width: width * 0.25,
                        decoration: BoxDecoration(
                          color: Color(0xff3F3BFF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF75BA95), Color(0xFF46787D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .transparent, // Set the background color to transparent
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () {},
                            child: Center(
                              child: Text(
                                "Next",
                                style: TextStyle(
                                  color: Color(0xffFFFFFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.05),
                    ],
                  ),
                  SizedBox(height: height * 0.02),
                  Container(
                    height: height * 0.006,
                    width: width * 0.4,
                    decoration: BoxDecoration(
                        color: Color(0xffFFFFFF),
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 220,
              right: 0,
              child: Container(
                height: height * 0.33,
                width: width * 0.15,
                decoration: BoxDecoration(
                    border: Border.all(color: Color(0xffFFFFFF)),
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        topLeft: Radius.circular(20))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeature(Icons.filter, "Filter", () {}),
                    SizedBox(height: 15),
                    _buildFeature(Icons.mic, "Voice Over", () {}),
                    SizedBox(height: 15),
                    GestureDetector(
                      onTap: _toggleMute,
                      child: Column(
                        children: [
                          Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Volume",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 60,
              left: 10,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xff9B9B9B),
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.close,
                      size: 15,
                      color: Color(0xffFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 25),
          SizedBox(height: 5),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomBarButton(String label, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Color(0xff9B9B9B),
            size: 30,
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(color: Color(0xff9B9B9B), fontSize: 12)),
        ],
      ),
    );
  }
}
