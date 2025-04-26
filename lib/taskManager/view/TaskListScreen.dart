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
      // Kiểm tra nếu chưa hiển thị dialog sau đăng nhập
      final prefs = await SharedPreferences.getInstance();
      final hasShownDialog = prefs.getBool('hasShownDueTaskDialog_${widget.currentUser.id}') ?? false;
      if (!hasShownDialog) {
        final nearestDueTask = _findNearestDueTask(tasks);
        if (nearestDueTask != null && mounted) {
          _showNearestDueTaskDialog(nearestDueTask);
          // Đánh dấu là đã hiển thị dialog
          await prefs.setBool('hasShownDueTaskDialog_${widget.currentUser.id}', true);
        }
      }
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
      // Xóa trạng thái hiển thị dialog khi đăng xuất
      await prefs.remove('hasShownDueTaskDialog_${widget.currentUser.id}');
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

  // Hàm tìm công việc gần hạn nhất chưa hoàn thành
  Task? _findNearestDueTask(List<Task> tasks) {
    final now = DateTime.now();
    // Lọc các công việc chưa hoàn thành (chưa làm hoặc đang làm) và có hạn
    final pendingTasks = tasks.where((task) =>
    (task.status == TaskStatus.chuaLam || task.status == TaskStatus.dangLam) &&
        task.dueDate != null &&
        task.dueDate!.isAfter(now)).toList();

    if (pendingTasks.isEmpty) return null;

    // Sắp xếp theo dueDate và lấy công việc gần nhất
    pendingTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return pendingTasks.first;
  }

  // Hàm hiển thị thông báo công việc gần hạn nhất
  void _showNearestDueTaskDialog(Task task) {
    // Tính số ngày còn lại
    final now = DateTime.now();
    final daysRemaining = task.dueDate!.difference(now).inDays;
    final daysText = daysRemaining > 0 ? '$daysRemaining ngày' : 'Hôm nay';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Công việc gần hạn nhất',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        content: Container(
          constraints: BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hạn: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: task.dueDate!.isBefore(DateTime.now().add(const Duration(days: 1)))
                          ? Colors.redAccent
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Trạng thái: ${_getStatusDisplay(task.status)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    size: 16,
                    color: daysRemaining <= 1 ? Colors.redAccent : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Còn lại: $daysText',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: daysRemaining <= 1 ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(
                    task: task,
                    currentUser: widget.currentUser,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  _loadTasks();
                }
              });
            },
            child: const Text(
              'Xem chi tiết',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 10,
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
      ),
    );
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
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.5,
            shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(2, 2))],
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.withOpacity(0.7), Colors.cyan.withOpacity(0.7)],
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
              size: 28,
            ),
            onPressed: themeSwitching?.toggleTheme,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: () {
              _resetFilters();
              _loadTasks(); // Không hiển thị dialog khi làm mới thủ công
            },
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            onPressed: _logout,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks, // Không hiển thị dialog khi kéo xuống làm mới
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).cardColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Tìm kiếm công việc',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 24),
                  filled: true,
                  fillColor: Theme.of(context).cardColor.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                ),
                onChanged: (_) => _filterTasks(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ExpansionTile(
                      title: Text(
                        'Lọc theo trạng thái',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
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
                      backgroundColor: Theme.of(context).cardColor,
                      collapsedBackgroundColor: Theme.of(context).cardColor,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
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
                                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                checkmarkColor: Theme.of(context).colorScheme.primary,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _selectedStatus == null
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                ),
                                elevation: 1,
                                pressElevation: 4,
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
                                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                checkmarkColor: Theme.of(context).colorScheme.primary,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _selectedStatus == status.toString().split('.').last
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                ),
                                elevation: 1,
                                pressElevation: 4,
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ExpansionTile(
                      title: Text(
                        'Lọc theo danh mục',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
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
                      backgroundColor: Theme.of(context).cardColor,
                      collapsedBackgroundColor: Theme.of(context).cardColor,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
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
                                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                checkmarkColor: Theme.of(context).colorScheme.primary,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _selectedCategory == null
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                ),
                                elevation: 1,
                                pressElevation: 4,
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
                                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                checkmarkColor: Theme.of(context).colorScheme.primary,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _selectedCategory == category
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                ),
                                elevation: 1,
                                pressElevation: 4,
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredTasks.isEmpty
                  ? FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có công việc nào',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_fadeAnimation),
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Theme.of(context).cardColor.withOpacity(0.95),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).cardColor,
                                Theme.of(context).cardColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
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
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.95),
          elevation: 8,
          highlightElevation: 16,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(
            Icons.add,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}