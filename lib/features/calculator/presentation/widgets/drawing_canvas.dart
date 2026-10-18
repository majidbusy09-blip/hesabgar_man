import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as mlkit;

class DrawingCanvas extends StatefulWidget {
  final Function(String) onTextRecognized;

  const DrawingCanvas({super.key, required this.onTextRecognized});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<mlkit.Stroke> _strokes = [];
  mlkit.Stroke? _currentStroke;
  bool _isProcessing = false;

  Future<void> _recognizeText() async {
    if (_strokes.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final recognizer = mlkit.DigitalInkRecognizer(languageCode: 'en-US');
      final ink = mlkit.Ink(strokes: _strokes);
      final candidates = await recognizer.processInk(ink);
      
      if (candidates.isNotEmpty) {
        widget.onTextRecognized(candidates.first.text);
      }
      recognizer.close();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() {
        _strokes.clear();
        _currentStroke = null;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نوشتن دستی', style: TextStyle(fontFamily: 'Vazirmatn')),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.red),
            onPressed: () => setState(() {
              _strokes.clear();
              _currentStroke = null;
            }),
            tooltip: 'پاک کردن همه',
          ),
          IconButton(
            icon: _isProcessing 
                ? const CircularProgressIndicator() 
                : const Icon(Icons.check, color: Colors.green),
            onPressed: _isProcessing ? null : _recognizeText,
            tooltip: 'تشخیص متن',
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: (details) {
          _currentStroke = mlkit.Stroke();
          _currentStroke!.points.add(mlkit.StrokePoint(
            x: details.localPosition.dx,
            y: details.localPosition.dy,
            t: DateTime.now().millisecondsSinceEpoch,
          ));
        },
        onPanUpdate: (details) {
          if (_currentStroke != null) {
            setState(() {
              _currentStroke!.points.add(mlkit.StrokePoint(
                x: details.localPosition.dx,
                y: details.localPosition.dy,
                t: DateTime.now().millisecondsSinceEpoch,
              ));
            });
          }
        },
        onPanEnd: (details) {
          if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
            setState(() {
              _strokes.add(_currentStroke!);
              _currentStroke = null;
            });
          }
        },
        child: Container(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: _DrawingPainter(_strokes, _currentStroke, isDark),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'عدد یا فرمول ریاضی را با انگشت روی صفحه بنویسید (مثل 12+5)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: isDark ? Colors.grey : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<mlkit.Stroke> strokes;
  final mlkit.Stroke? currentStroke;
  final bool isDark;

  _DrawingPainter(this.strokes, this.currentStroke, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(mlkit.Stroke stroke) {
      if (stroke.points.isEmpty) return;
      final path = Path();
      path.moveTo(stroke.points.first.x, stroke.points.first.y);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].x, stroke.points[i].y);
      }
      canvas.drawPath(path, paint);
    }

    for (var stroke in strokes) {
      drawStroke(stroke);
    }
    if (currentStroke != null) {
      drawStroke(currentStroke!);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
