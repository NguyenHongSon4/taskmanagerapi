import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/ApiService.dart';
import '../model/TaskModel.dart';
import '../model/UserModel.dart';
import 'TaskDetailScreen.dart';
import 'TaskFormScreen.dart';
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
  String? _sortOption;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
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
        _applySort();
      });
      final prefs = await SharedPreferences.getInstance();
      final hasShownDialog = prefs.getBool('hasShownDueTaskDialog_${widget.currentUser.id}') ?? false;
      if (!hasShownDialog) {
        final nearestDueTask = _findNearestDueTask(tasks);
        if (nearestDueTask != null && mounted) {
          _showNearestDueTaskDialog(nearestDueTask);
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
        _applySort();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lọc công việc: $e')),
      );
    }
  }

  void _applySort() {
    if (_sortOption == null) return;
    switch (_sortOption) {
      case 'dueDateAsc':
        _filteredTasks.sort((a, b) => (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999)));
        break;
      case 'dueDateDesc':
        _filteredTasks.sort((a, b) => (b.dueDate ?? DateTime(9999)).compareTo(a.dueDate ?? DateTime(9999)));
        break;
      case 'priorityAsc':
        _filteredTasks.sort((a, b) => a.priority.compareTo(b.priority));
        break;
      case 'priorityDesc':
        _filteredTasks.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'alphabetical':
        _filteredTasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedCategory = null;
      _sortOption = null;
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

  Task? _findNearestDueTask(List<Task> tasks) {
    final now = DateTime.now();
    final pendingTasks = tasks.where((task) =>
    (task.status == TaskStatus.chuaLam || task.status == TaskStatus.dangLam) &&
        task.dueDate != null &&
        task.dueDate!.isAfter(now)).toList();

    if (pendingTasks.isEmpty) return null;

    pendingTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return pendingTasks.first;
  }

  void _showNearestDueTaskDialog(Task task) {
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

  void _showFilterSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lọc và Sắp xếp',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lọc theo trạng thái',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tất cả'),
                          selected: _selectedStatus == null,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedStatus = null;
                              _filterTasks();
                            });
                          },
                        ),
                        ...TaskStatus.values.map((status) => FilterChip(
                          label: Text(_getStatusDisplay(status)),
                          selected: _selectedStatus == status.toString().split('.').last,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedStatus = status.toString().split('.').last;
                              _filterTasks();
                            });
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lọc theo danh mục',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tất cả'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedCategory = null;
                              _filterTasks();
                            });
                          },
                        ),
                        ..._tasks
                            .map((task) => task.category)
                            .where((category) => category != null)
                            .toSet()
                            .map((category) => FilterChip(
                          label: Text(category!),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedCategory = category;
                              _filterTasks();
                            });
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sắp xếp danh sách',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Mặc định'),
                          selected: _sortOption == null,
                          onSelected: (selected) {
                            setModalState(() {
                              _sortOption = null;
                              _filterTasks();
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Hạn gần nhất'),
                          selected: _sortOption == 'dueDateAsc',
                          onSelected: (selected) {
                            setModalState(() {
                              _sortOption = 'dueDateAsc';
                              _filterTasks();
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Hạn xa nhất'),
                          selected: _sortOption == 'dueDateDesc',
                          onSelected: (selected) {
                            setModalState(() {
                              _sortOption = 'dueDateDesc';
                              _filterTasks();
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Ưu tiên cao đến thấp'),
                          selected: _sortOption == 'priorityAsc',
                          onSelected: (selected) {
                            setModalState(() {
                              _sortOption = 'priorityAsc';
                              _filterTasks();
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Ưu tiên thấp đến cao'),
                          selected: _sortOption == 'priorityDesc',
                          onSelected: (selected) {
                            setModalState(() {
                              _sortOption = 'priorityDesc';
                              _filterTasks();
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Theo bảng chữ cái (A-Z)'),
                          selected: _sortOption == 'alphabetical',
                          onSelected: (selected) {
                            setModalState(() {
                              _sortOption = 'alphabetical';
                              _filterTasks();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Đóng'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            fontSize: 20,
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
            ),
            onPressed: themeSwitching?.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterSortBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _resetFilters();
              _loadTasks();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).cardColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Tìm kiếm công việc',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                  filled: true,
                  fillColor: Theme.of(context).cardColor.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                onChanged: (_) => _filterTasks(),
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
                        size: 50,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Không có công việc nào',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Opacity(
                      opacity: task.completed ? 0.5 : 1.0, // Làm mờ nếu đã hoàn thành
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: task.status == TaskStatus.hoanThanh
                                ? Colors.green
                                : Colors.orange,
                            child: Icon(
                              task.status == TaskStatus.hoanThanh
                                  ? Icons.check
                                  : Icons.pending,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none, // Gạch ngang nếu hoàn thành
                              color: task.completed
                                  ? Colors.grey
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Text(
                            'Hạn: ${task.dueDate?.day}/${task.dueDate?.month}/${task.dueDate?.year} • Trạng thái: ${_getStatusDisplay(task.status)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: task.completed
                                  ? Colors.grey
                                  : Colors.grey[600],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  task.completed
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: task.completed ? Colors.green : Colors.grey,
                                ),
                                onPressed: () async {
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
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Xác nhận xóa'),
                                      content: Text(
                                          'Bạn có chắc chắn muốn xóa công việc "${task.title}" không?'),
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
                                      await _apiService.deleteTask(task.id);
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
                              ),
                            ],
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(
                                  task: task,
                                  currentUser: widget.currentUser,
                                ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskFormScreen(currentUser: widget.currentUser),
            ),
          );
          if (result == true) {
            _loadTasks();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}