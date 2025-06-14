// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locator.dart';
import 'features/events/presentation/screens/map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Events Map',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;

  static const _screens = [
    Center(child: Text('Search')),
    MapWithBottomSheetScreen(),
    Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // sliding orange pill background
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: _currentIndex == 0
                      ? Alignment(-0.62, 0)
                      : _currentIndex == 1
                      ? Alignment(0, 0)
                      : Alignment(0.63, 0),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                // icons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 0),
                      child: Icon(
                        Icons.search,
                        size: 28,
                        color: _currentIndex == 0
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 1),
                      child: Icon(
                        Icons.whatshot,
                        size: 28,
                        color: _currentIndex == 1
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 2),
                      child: Icon(
                        Icons.circle_outlined,
                        size: 28,
                        color: _currentIndex == 2
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
