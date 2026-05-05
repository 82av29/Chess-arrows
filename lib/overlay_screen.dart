import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'arrow_painter.dart';

enum AppMode { hidden, drawing, calibrating }

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  BoardCalibration? _calibration;
  List<ChessArrow> _arrows = [];
  AppMode _mode = AppMode.drawing;
  Color _selectedColor = const Color(0xFFFFCC00); // Chess.com yellow
  String? _pendingFrom;
  int _calibrationStep = 0; // 0 = tap A8, 1 = tap H1
  Offset? _calibA8;

  final TextEditingController _colorController =
      TextEditingController(text: 'FFCC00');

  @override
  void initState() {
    super.initState();
    _loadCalibration();
  }

  Future<void> _loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('calibration');
    if (json != null) {
      setState(() {
        _calibration =
            BoardCalibration.fromJson(jsonDecode(json));
      });
    } else {
      // First launch, go straight to calibration
      setState(() => _mode = AppMode.calibrating);
    }
  }

  Future<void> _saveCalibration() async {
    if (_calibration == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'calibration', jsonEncode(_calibration!.toJson()));
  }

  void _onTap(Offset pos) {
    if (_mode == AppMode.calibrating) {
      if (_calibrationStep == 0) {
        setState(() {
          _calibA8 = pos;
          _calibrationStep = 1;
        });
      } else {
        final tl = _calibA8!;
        final br = pos;
        setState(() {
          _calibration = BoardCalibration(topLeft: tl, bottomRight: br);
          _calibrationStep = 0;
          _mode = AppMode.drawing;
        });
        _saveCalibration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Board calibrated!')),
        );
      }
      return;
    }

    if (_mode == AppMode.drawing && _calibration != null) {
      final square = _calibration!.offsetToSquare(pos);
      if (square == null) return;

      if (_pendingFrom == null) {
        setState(() => _pendingFrom = square);
      } else {
        if (_pendingFrom != square) {
          setState(() {
            _arrows.add(ChessArrow(
              from: _pendingFrom!,
              to: square,
              color: _selectedColor,
            ));
            _pendingFrom = null;
          });
        } else {
          setState(() => _pendingFrom = null);
        }
      }
    }
  }

  void _startCalibration() {
    setState(() {
      _mode = AppMode.calibrating;
      _calibrationStep = 0;
      _calibA8 = null;
      _pendingFrom = null;
    });
  }

  void _applyColor() {
    final hex = _colorController.text.replaceAll('#', '');
    try {
      final color = Color(int.parse('FF$hex', radix: 16));
      setState(() => _selectedColor = color);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid color code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tap area
          if (_mode != AppMode.hidden)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (d) => _onTap(d.localPosition),
                child: _mode == AppMode.drawing && _calibration != null
                    ? CustomPaint(
                        painter: ArrowPainter(
                          arrows: _arrows,
                          calibration: _calibration!,
                        ),
                      )
                    : _buildCalibrationOverlay(),
              ),
            ),

          // Control panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _calibrationStep == 0
                  ? 'Tap the TOP-LEFT corner of the board\n(Square A8)'
                  : 'Tap the BOTTOM-RIGHT corner of the board\n(Square H1)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_calibA8 != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'A8 set. Now tap H1.',
                  style: TextStyle(color: Colors.green[300], fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      color: Colors.black.withOpacity(0.88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status
          if (_mode == AppMode.drawing && _calibration != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _pendingFrom != null
                    ? 'From: $_pendingFrom — tap destination'
                    : 'Tap a square to start an arrow',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),

          // Color input row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white30),
                ),
              ),
              const SizedBox(width: 8),
              const Text('#', style: TextStyle(color: Colors.white70)),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _colorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'FFCC00',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  ),
                  maxLength: 6,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                ),
              ),
              TextButton(
                onPressed: _applyColor,
                child: const Text('Apply'),
              ),
              const Spacer(),
              // Clear all arrows
              IconButton(
                tooltip: 'Clear arrows',
                icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                onPressed: () => setState(() {
                  _arrows = [];
                  _pendingFrom = null;
                }),
              ),
              // Hide/show overlay
              IconButton(
                tooltip: _mode == AppMode.hidden ? 'Show overlay' : 'Hide overlay',
                icon: Icon(
                  _mode == AppMode.hidden
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() {
                  _mode =
                      _mode == AppMode.hidden ? AppMode.drawing : AppMode.hidden;
                }),
              ),
              // Recalibrate
              IconButton(
                tooltip: 'Recalibrate board',
                icon: const Icon(Icons.grid_on, color: Colors.white70),
                onPressed: _startCalibration,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
