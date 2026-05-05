import 'package:flutter/material.dart';
import 'overlay_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChessArrowsApp());
}

class ChessArrowsApp extends StatelessWidget {
  const ChessArrowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Arrows',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF769656),
          secondary: const Color(0xFFBECA44),
        ),
      ),
      home: const OverlayScreen(),
    );
  }
}
