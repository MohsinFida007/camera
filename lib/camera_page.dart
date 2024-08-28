import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';

import 'package:video_player/video_player.dart';
import 'recording_screen.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  late CameraDescription _currentCamera;

  final List<String> buttonLabels = [
    "0.5x",
    "1x",
    "2x",
    "3x",
    "5x",
  ];
  String _selectedLabel = "";
  File? _imageFile;
  File? _videoFile;
  VideoPlayerController? _videoPlayerController;
  Timer? _timer;
  int _timerDuration = 0;
  bool _isTimerActive = false;

  String _formatTime(int seconds) {
    return seconds.toString();
  }

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      _initializeCamera();
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _videoFile = null;
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _imageFile = null;
        _initializeVideoPlayer();
      });
    } else {
      print('No video selected.');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoFile != null) {
      _videoPlayerController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoPlayerController?.play();
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted ||
        microphoneStatus != PermissionStatus.granted) {
      showErrorSnackbar('Permissions are not granted');
    }
  }

  Future<void> _initializeCamera({int cameraIndex = 0}) async {
    _cameras = await availableCameras();
    _currentCamera = _cameras[cameraIndex];

    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _takePicture() async {
    try {
      if (!_controller.value.isInitialized) {
        return;
      }

      final XFile? picture = await _controller.takePicture();
      if (picture != null) {
        setState(() {
          _imageFile = File(picture.path);
          _videoFile = null;
        });
      }
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<void> _flipCamera() async {
    final newIndex = (_cameras.indexOf(_currentCamera) + 1) % _cameras.length;
    final newCamera = _cameras[newIndex];

    setState(() {
      _currentCamera = newCamera;
      _initializeCamera(cameraIndex: newIndex);
    });
  }

  Future<void> _setZoomLevel(double zoomFactor) async {
    if (_controller.value.isInitialized) {
      await _controller.setZoomLevel(zoomFactor);
    }
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _startTimer(int seconds) {
    setState(() {
      _timerDuration = seconds;
      _isTimerActive = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timerDuration > 0) {
        setState(() {
          _timerDuration--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerActive = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RecordingScreen(
              cameraController: _controller,
            ),
          ),
        );
      }
    });
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      final file = result.files.single;
      print('Picked audio file: ${file.path}');
    } else {
      print('No file selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(
              height: height,
              width: width,
              color: Color(0xffFFFFFF),
              child: Column(
                children: [
                  SizedBox(
                    height: height * 0.1,
                  ),
                  Container(
                    height: height * 0.6,
                    width: width,
                    color: Colors.white,
                    child: _imageFile != null
                        ? Image.file(_imageFile!)
                        : _videoFile != null
                            ? _videoPlayerController != null &&
                                    _videoPlayerController!.value.isInitialized
                                ? VideoPlayer(_videoPlayerController!)
                                : Center(child: CircularProgressIndicator())
                            : FutureBuilder<void>(
                                future: _initializeControllerFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    return CameraPreview(_controller);
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Error initializing camera'));
                                  } else {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }
                                },
                              ),
                  ),
                  SizedBox(
                    height: height * 0.01,
                  ),
                  Expanded(
                    child: Container(
                      width: width,
                      color: Color(0xffFFFFFF),
                      child: Column(
                        children: [
                          SizedBox(
                            height: height * 0.005,
                          ),
                          Container(
                            height: 60,
                            width: width,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: buttonLabels.length,
                              itemBuilder: (context, index) {
                                final label = buttonLabels[index];
                                final zoomFactor =
                                    double.parse(label.split('x').first);
                                final isSelected = _selectedLabel == label;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedLabel = label;
                                      _setZoomLevel(zoomFactor);
                                    });
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      _selectedLabel = label;
                                      _setZoomLevel(zoomFactor);
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 4.0),
                                    height: isSelected ? 40 : 30,
                                    width: isSelected ? 80 : 69,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(0xffE7E7E7)
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Color(0xff495057)
                                              : Color(0xff333333),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            height: height * 0.03,
                          ),
                          SizedBox(
                            height: height * 0.02,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Photos",
                                style: TextStyle(
                                    fontSize: 16, color: Color(0xff333333)),
                              ),
                              SizedBox(
                                width: width * 0.04,
                              ),
                              Column(
                                children: [
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "Videos",
                                    style: TextStyle(
                                        fontSize: 16, color: Color(0xff333333)),
                                  ),
                                  SizedBox(
                                    height: height * 0.005,
                                  ),
                                  Icon(
                                    Icons.circle,
                                    color: Color(0xff333333),
                                    size: 10,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isTimerActive)
              Positioned(
                top: height * 0.3,
                left: width * 0.4,
                child: Text(
                  _formatTime(_timerDuration),
                  style: TextStyle(
                    fontSize: 120,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.6),
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 10,
              top: 30,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xff9B9B9B),
                child: Center(
                  child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        size: 15,
                        Icons.arrow_back_ios_new,
                        color: Color(0xffFFFFFF),
                      )),
                ),
              ),
            ),
            Positioned(
              top: 430,
              left: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.transparent,
                        backgroundImage: AssetImage("images/effects.png"),
                      ),
                      Text(
                        "Effects",
                        style:
                            TextStyle(fontSize: 14, color: Color(0xffFFFFFF)),
                      )
                    ],
                  ),
                  SizedBox(
                    width: width * 0.1,
                  ),
                  GestureDetector(
                      onTap: () async {
                        await _takePicture();
                      },
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecordingScreen(
                              cameraController: _controller,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 80.0,
                        height: 80.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
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
                        child: Center(
                          child: Container(
                            width: 70.0,
                            height: 70.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 100),
                                width: 60.0,
                                height: 60.0,
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
                              ),
                            ),
                          ),
                        ),
                      )),
                  SizedBox(
                    width: width * 0.1,
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    colors: [
                                      Color(0xFF75BA95),
                                      Color(0xFF46787D),
                                      Color(0xFF163665),
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: Text('Select Media',
                                        style: TextStyle(color: Colors.black)),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _pickImage();
                                        },
                                        child: Text('Pick Image',
                                            style:
                                                TextStyle(color: Colors.black)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _pickVideo();
                                        },
                                        child: Text('Pick Video',
                                            style:
                                                TextStyle(color: Colors.black)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage("images/upload.png")),
                              borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                      Text(
                        "Upload",
                        style:
                            TextStyle(fontSize: 14, color: Color(0xffFFFFFF)),
                      )
                    ],
                  )
                ],
              ),
            ),
            Positioned(
              top: 100,
              right: 0,
              child: Container(
                height: height * 0.43,
                width: width * 0.15,
                decoration: BoxDecoration(
                    border: Border.all(color: Color(0xffFFFFFF)),
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        topLeft: Radius.circular(20))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildFeature(
                        Icons.flip_camera_android, "Flip", _flipCamera),
                    SizedBox(height: 10),
                    _buildFeature(Icons.speed, "Speed", _onSpeed),
                    SizedBox(height: 10),
                    _buildFeature(Icons.timer, "Timer", _onTimer),
                    SizedBox(height: 10),
                    _buildFeature(Icons.filter, "Filter", _onFilter),
                    SizedBox(height: 10),
                    _buildFeature(Icons.music_note, " Audio", _pickAudio),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _onSpeed() {}

  void _onFilter() {}

  void _onTimer() {
    const int timerDurationInSeconds = 9;
    _startTimer(timerDurationInSeconds);
  }
}
