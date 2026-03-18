import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/calendar_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final taskProvider = TaskProvider();
  
  // CRITICAL FIX: The 'await' has been removed. 
  // This allows the UI to render immediately, eliminating the white screen crash.
  // The provider handles its own internal _isLoading state.
  taskProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: taskProvider,
      child: const WirdiApp(),
    ),
  );
}

class WirdiApp extends StatelessWidget {
  const WirdiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'وردي',
          debugShowCheckedModeBanner: false,
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A6B4A)),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A6B4A),
              brightness: Brightness.dark,
            ),
            cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
          ),
          home: const CalendarScreen(),
        );
      },
    );
  }
}