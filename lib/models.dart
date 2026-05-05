import 'dart:ui';

class ChessArrow {
  final String from; // e.g. "e2"
  final String to;   // e.g. "e4"
  final Color color;

  ChessArrow({required this.from, required this.to, required this.color});
}

class BoardCalibration {
  final Offset topLeft;     // A8 corner
  final Offset bottomRight; // H1 corner

  BoardCalibration({required this.topLeft, required this.bottomRight});

  double get squareSize =>
      (bottomRight.dx - topLeft.dx) / 8;

  // Convert chess square (e.g. "e4") to screen center offset
  Offset squareToOffset(String square) {
    final file = square[0].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0); // 0-7
    final rank = int.parse(square[1]) - 1; // 0-7
    final sq = squareSize;
    final x = topLeft.dx + (file + 0.5) * sq;
    final y = bottomRight.dy - (rank + 0.5) * sq;
    return Offset(x, y);
  }

  // Convert screen tap to chess square string
  String? offsetToSquare(Offset pos) {
    final sq = squareSize;
    final boardHeight = bottomRight.dy - topLeft.dy;
    final fileIdx = ((pos.dx - topLeft.dx) / sq).floor();
    final rankIdx = ((bottomRight.dy - pos.dy) / sq).floor();
    if (fileIdx < 0 || fileIdx > 7 || rankIdx < 0 || rankIdx > 7) return null;
    final file = String.fromCharCode('a'.codeUnitAt(0) + fileIdx);
    final rank = (rankIdx + 1).toString();
    return '$file$rank';
  }

  Map<String, dynamic> toJson() => {
        'tlx': topLeft.dx,
        'tly': topLeft.dy,
        'brx': bottomRight.dx,
        'bry': bottomRight.dy,
      };

  factory BoardCalibration.fromJson(Map<String, dynamic> json) =>
      BoardCalibration(
        topLeft: Offset(json['tlx'], json['tly']),
        bottomRight: Offset(json['brx'], json['bry']),
      );
}
