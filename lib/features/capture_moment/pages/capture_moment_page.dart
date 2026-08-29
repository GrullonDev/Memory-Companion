import 'package:flutter/material.dart';

class CaptureMomentPage extends StatefulWidget {
  const CaptureMomentPage({super.key});

  @override
  State<CaptureMomentPage> createState() => _CaptureMomentPageState();
}

class _CaptureMomentPageState extends State<CaptureMomentPage> {
  bool _isListening = false;

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B101B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Color(0xFF3F51B5), size: 45),
            const SizedBox(width: 12),
            const Text(
              'Instant Capture',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Center(
            child: GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3F51B5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF3F51B5,
                      ).withOpacity(_isListening ? 0.6 : 0.3),
                      blurRadius: _isListening ? 40 : 20,
                      spreadRadius: _isListening ? 10 : 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic,
                      color: Colors.white,
                      size: 100,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isListening ? 'STOP RECORDING' : 'RECORD MOMENT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isListening ? 1.0 : 0.0,
            child: const Text(
              'LISTENING FOR CONTEXT...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
