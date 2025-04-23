import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/ApiService.dart';
import '../model/TaskModel.dart';
import '../model/UserModel.dart';
import 'TaskDetailScreen.dart';
import 'TaskFormScreen.dart';
import 'TaskItem.dart';
import 'package:taskmanagerapi/main.dart';

class TaskListScreen extends StatefulWidget {
  final User currentUser;

  const TaskListScreen({super.key, required this.currentUser});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCategory;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isStatusFilterExpanded = false;
  bool _isCategoryFilterExpanded = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadTasks();
    _searchController.addListener(_filterTasks);
    _animationController.forward();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _apiService.getAllTasks(widget.currentUser.id);
      setState(() {
        _tasks = tasks;
        _filteredTasks = tasks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải công việc: $e')),
      );
    }
  }

  Future<void> _filterTasks() async {
    final keyword = _searchController.text;
    try {
      final tasks = await _apiService.getAllTasks(widget.currentUser.id);
      setState(() {
        _filteredTasks = tasks.where((task) {
          bool matchesKeyword = keyword.isEmpty ||
              task.title.toLowerCase().contains(keyword.toLowerCase()) ||
              task.description.toLowerCase().contains(keyword.toLowerCase());
          bool matchesStatus = _selectedStatus == null ||
              task.status.toString().split('.').last == _selectedStatus;
          bool matchesCategory = _selectedCategory == null ||
              task.category == _selectedCategory;
          return matchesKeyword && matchesStatus && matchesCategory;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lọc công việc: $e')),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedCategory = null;
      _filteredTasks = _tasks;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('loggedInUserId');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _getStatusDisplay(TaskStatus status) {
    switch (status) {
      case TaskStatus.chuaLam:
        return 'Chưa làm';
      case TaskStatus.dangLam:
        return 'Đang làm';
      case TaskStatus.hoanThanh:
        return 'Hoàn thành';
      case TaskStatus.daHuy:
        return 'Đã hủy';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeSwitching = ThemeSwitchingWidget.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách Công việc',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeSwitching?.isDarkMode ?? false ? Icons.brightness_7 : Icons.brightness_4,
              color: Colors.white,
            ),
            onPressed: themeSwitching?.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetFilters,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                labelText: 'Tìm kiếm công việc',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                filled: true,
                fillColor: Theme.of(context).cardColor.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpansionTile(
                  title: Text(
                    'Lọc theo trạng thái',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  initiallyExpanded: _isStatusFilterExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isStatusFilterExpanded = expanded;
                    });
                  },
                  trailing: Icon(
                    _isStatusFilterExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  backgroundColor: Theme.of(context).cardColor.withOpacity(0.1),
                  collapsedBackgroundColor: Theme.of(context).cardColor.withOpacity(0.05),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Tất cả'),
                            selected: _selectedStatus == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatus = null;
                                  _filterTasks();
                                });
                              }
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedStatus == null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          ...TaskStatus.values.map((status) => FilterChip(
                            label: Text(_getStatusDisplay(status)),
                            selected: _selectedStatus == status.toString().split('.').last,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatus = status.toString().split('.').last;
                                  _filterTasks();
                                });
                              }
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedStatus == status.toString().split('.').last
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: Text(
                    'Lọc theo danh mục',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  initiallyExpanded: _isCategoryFilterExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isCategoryFilterExpanded = expanded;
                    });
                  },
                  trailing: Icon(
                    _isCategoryFilterExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  backgroundColor: Theme.of(context).cardColor.withOpacity(0.1),
                  collapsedBackgroundColor: Theme.of(context).cardColor.withOpacity(0.05),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Tất cả'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = null;
                                  _filterTasks();
                                });
                              }
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedCategory == null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          ..._tasks
                              .map((task) => task.category)
                              .where((category) => category != null)
                              .toSet()
                              .map((category) => FilterChip(
                            label: Text(category!),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                  _filterTasks();
                                });
                              }
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedCategory == category
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(
              child: Text(
                'Không có công việc nào',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(_fadeAnimation),
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TaskItem(
                        task: _filteredTasks[index],
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: Text(
                                  'Bạn có chắc chắn muốn xóa công việc "${_filteredTasks[index].title}" không?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await _apiService.deleteTask(_filteredTasks[index].id);
                              _loadTasks();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã xóa công việc')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi khi xóa công việc: $e')),
                                );
                              }
                            }
                          }
                        },
                        onToggleComplete: () async {
                          final task = _filteredTasks[index];
                          final updatedTask = task.copyWith(
                            completed: !task.completed,
                            updatedAt: DateTime.now(),
                          );
                          try {
                            await _apiService.updateTask(updatedTask);
                            _loadTasks();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
                            );
                          }
                        },
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => TaskDetailScreen(
                                task: _filteredTasks[index],
                                currentUser: widget.currentUser,
                              ),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                          if (result == true) {
                            _loadTasks();
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => TaskFormScreen(currentUser: widget.currentUser),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
            if (result == true) {
              _loadTasks();
            }
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 6,
          highlightElevation: 12,
          child: const Icon(
            Icons.add,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}