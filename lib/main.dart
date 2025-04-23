import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskmanagerapi/taskManager/view/LoginScreen.dart';
import 'package:taskmanagerapi/taskManager/view/RegisterScreen.dart';
import 'package:taskmanagerapi/taskManager/view/TaskDetailScreen.dart';
import 'package:taskmanagerapi/taskManager/view/TaskListScreen.dart';
import 'package:taskmanagerapi/taskManager/view/TaskFormScreen.dart';
import 'package:taskmanagerapi/taskManager/model/UserModel.dart';
import 'package:taskmanagerapi/taskManager/db/ApiService.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const TaskManagerApp());
}

class ThemeSwitchingWidget extends InheritedWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const ThemeSwitchingWidget({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeSwitchingWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeSwitchingWidget>();
  }

  @override
  bool updateShouldNotify(ThemeSwitchingWidget oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  bool _isDarkMode = false;
  User? _currentUser;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('loggedInUserId');
      if (userId != null) {
        final users = await _apiService.getAllUsers();
        final user = users.firstWhere(
              (user) => user.id == userId,
          orElse: () => User(
            id: '',
            username: '',
            password: '',
            email: '',
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          ),
        );
        if (user.id.isNotEmpty) {
          setState(() {
            _currentUser = user;
          });
        }
      }
    } catch (e) {
      developer.log('Error checking login status: $e', name: 'TaskManagerApp');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeSwitchingWidget(
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      child: MaterialApp(
        title: 'Task Manager',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
          cardColor: _isDarkMode ? Colors.grey[800] : Colors.white,
          scaffoldBackgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
          textTheme: TextTheme(
            bodyMedium: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
            bodyLarge: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        home: _isLoading
            ? const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        )
            : _currentUser != null
            ? TaskListScreen(currentUser: _currentUser!)
            : const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/task_list': (context) => TaskListScreen(
            currentUser: ModalRoute.of(context)!.settings.arguments as User,
          ),
        },
      ),
    );
  }
}