import 'package:flutter/material.dart';

class DecryptAnimation extends StatefulWidget {
  final String fileType;

  DecryptAnimation({Key? key, required this.fileType}) : super(key: key);

  @override
  _DecryptAnimationState createState() => _DecryptAnimationState();
}

class _DecryptAnimationState extends State<DecryptAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: _getDuration(widget.fileType)),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward();
  }

  int _getDuration(String fileType) {
    switch (fileType) {
      case 'image':
        return 3;
      case 'audio':
        return 5;
      case 'video':
        return 8;
      case 'document':
        return 4;
      default:
        return 5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
            child: Icon(Icons.lock_open, size: 100, color: Colors.green),
          ),
          SizedBox(height: 20),
          Text(
            'Decrypting...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          LinearProgressIndicator(value: _animation.value),
          SizedBox(height: 10),
          Text(
            '${(_animation.value * 100).toInt()}%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}