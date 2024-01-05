import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("baghali ...................");
    return const Scaffold(
      backgroundColor: Colors.amber,
      body: Center(
        child: Text("loading ..."),
      ),
    );
  }
}
