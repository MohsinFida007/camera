import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:record_video/recorded_screen.dart';
import 'package:video_player/video_player.dart';

class RecordingScreen extends StatefulWidget {
  final CameraController cameraController;

  RecordingScreen({required this.cameraController, String? audioFilePath});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isRecording = false;
  bool _isProgressVisible = false;
  double _progress = 0.0;
  bool _showIcons = false;
  VideoPlayerController? _videoPlayerController;
  String? _videoPath;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    if (!widget.cameraController.value.isRecordingVideo) {
      try {
        setState(() {
          _isRecording = true;
          _isProgressVisible = true;
        });
        await widget.cameraController.startVideoRecording();
        _simulateProgress();
      } catch (e) {}
    }
  }

  Future<void> _stopRecording() async {
    if (widget.cameraController.value.isRecordingVideo) {
      try {
        final videoFile = await widget.cameraController.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _isProgressVisible = false;
          _progress = 0.0;
          _showIcons = true;
          _videoPath = videoFile.path;
          _videoPlayerController = VideoPlayerController.file(File(_videoPath!))
            ..initialize().then((_) {
              setState(() {});
              _videoPlayerController?.play();
              _isPlaying = true;
            });
        });
      } catch (e) {}
    }
  }

  void _simulateProgress() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isRecording && _progress < 1.0) {
        setState(() {
          _progress += 0.1;
        });
        if (_progress >= 1.0) {
          _stopRecording();
        } else {
          _simulateProgress();
        }
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _videoPlayerController?.pause();
      } else {
        _videoPlayerController?.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _onCheckIconPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordedScreen(videoPath: _videoPath!),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    widget.cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        height: height,
        width: width,
        color: Color(0xffFFFFFF),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: height * 0.1),
                if (_isProgressVisible)
                  Container(
                    width: width,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.white),
                    child: Stack(
                      children: [
                        Container(
                          width: width,
                          height: 5,
                          color: Colors.transparent,
                        ),
                        Container(
                          width: width * _progress,
                          height: 5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF75BA95),
                                Color(0xFF46787D),
                                Color(0xFF163665),
                              ],
                              stops: [0.0, 0.5, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: height * 0.1),
                Container(
                  height: height * 0.6,
                  width: width,
                  child: _videoPath != null
                      ? Stack(
                          children: [
                            VideoPlayer(_videoPlayerController!),
                            if (_videoPlayerController != null &&
                                _videoPlayerController!.value.isInitialized)
                              Center(
                                child: GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: AnimatedOpacity(
                                    opacity: _isPlaying ? 0.0 : 1.0,
                                    duration: Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : CameraPreview(widget.cameraController),
                ),
                SizedBox(height: height * 0.15),
                Container(
                  height: height * 0.006,
                  width: width * 0.4,
                  decoration: BoxDecoration(
                      color: Color(0xffEDEDED),
                      borderRadius: BorderRadius.circular(5)),
                ),
              ],
            ),
            if (_showIcons) ...[
              Positioned(
                right: 20,
                top: height * 0.1 + 5,
                child: Row(
                  children: [
                    CircleAvatar(
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
                  ],
                ),
              ),
              Positioned(
                right: 50,
                top: 530,
                child: GestureDetector(
                  onTap: _onCheckIconPressed,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xff9B9B9B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        color: Color(0xffFFFFFF),
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 500,
                left: 130,
                child: GestureDetector(
                  onTap: () {
                    if (_isRecording) {
                      _stopRecording();
                    } else if (_videoPath == null) {
                      _startRecording();
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90.0,
                        height: 90.0,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF75BA95),
                              Color(0xFF46787D),
                              Color(0xFF163665),
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.transparent,
                            width: _isRecording ? 10.0 : 5.0,
                          ),
                        ),
                      ),
                      Container(
                        width: 80.0,
                        height: 80.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 70.0,
                        height: 70.0,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF75BA95),
                              Color(0xFF46787D),
                              Color(0xFF163665),
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _isRecording
                              ? Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF75BA95),
                                        Color(0xFF46787D),
                                        Color(0xFF163665),
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                )
                              : Container(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
