import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SensorLabApp());
}

class SensorLabApp extends StatelessWidget {
  const SensorLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SensorLab Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
