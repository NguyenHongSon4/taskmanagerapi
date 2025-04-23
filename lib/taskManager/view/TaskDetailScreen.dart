import 'package:flutter/material.dart';
import 'dart:io';
import '../model/TaskModel.dart';
import '../model/UserModel.dart';
import '../db/ApiService.dart';
import 'TaskFormScreen.dart';
import 'package:taskmanagerapi/main.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final User currentUser;

  const TaskDetailScreen({super.key, required this.task, required this.currentUser});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> with SingleTickerProviderStateMixin {
  late Task _task;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isUpdatingStatus = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    print('Attachments: ${_task.attachments}');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  Future<void> _updateStatus(TaskStatus newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });
    try {
      final updatedTask = _task.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await _apiService.updateTask(updatedTask);
      setState(() {
        _task = updatedTask;
        _isUpdatingStatus = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isUpdatingStatus = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
        );
      }
    }
  }

  bool _isImageFile(String path) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  Future<void> _editTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(
          currentUser: widget.currentUser,
          task: _task,
        ),
      ),
    );

    if (result == true) {
      try {
        final tasks = await _apiService.getAllTasks(widget.currentUser.id);
        final updatedTask = tasks.firstWhere((task) => task.id == _task.id);
        if (updatedTask != null) {
          setState(() {
            _task = updatedTask;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật công việc')),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải công việc: $e')),
        );
      }
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

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.chuaLam:
        return Colors.grey;
      case TaskStatus.dangLam:
        return Colors.blueAccent;
      case TaskStatus.hoanThanh:
        return Colors.green;
      case TaskStatus.daHuy:
        return Colors.red;
    }
  }

  String _getPriorityDisplay(int priority) {
    switch (priority) {
      case 1:
        return 'Cao';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Thấp';
      default:
        return 'Không xác định';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeSwitching = ThemeSwitchingWidget.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết Công việc',
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
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editTask,
          ),
          IconButton(
            icon: Icon(
              themeSwitching?.isDarkMode ?? false ? Icons.brightness_7 : Icons.brightness_4,
              color: Colors.white,
            ),
            onPressed: themeSwitching?.toggleTheme,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _task.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.description, color: Colors.blueAccent),
                          title: Text(
                            'Mô tả',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _task.description ?? 'Không có',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.flag, color: Colors.blueAccent),
                          title: Text(
                            'Độ ưu tiên',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Chip(
                            label: Text(
                              _getPriorityDisplay(_task.priority),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getPriorityColor(_task.priority),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                          title: Text(
                            'Hạn hoàn thành',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _task.dueDate != null ? _task.dueDate.toString().split('.')[0] : 'Không có',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.access_time, color: Colors.blueAccent),
                          title: Text(
                            'Thời gian tạo',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _task.createdAt.toString().split('.')[0],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.update, color: Colors.blueAccent),
                          title: Text(
                            'Cập nhật gần nhất',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _task.updatedAt.toString().split('.')[0],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.blueAccent),
                          title: Text(
                            'Người được giao',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _task.assignedTo ?? 'Không có',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person_add, color: Colors.blueAccent),
                          title: Text(
                            'Người tạo',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _task.createdBy,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.category, color: Colors.blueAccent),
                          title: Text(
                            'Danh mục',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _task.category ?? 'Không có',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.blueAccent),
                          title: Text(
                            'Hoàn thành',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _task.completed ? 'Có' : 'Không',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              'Tệp đính kèm',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _task.attachments != null && _task.attachments!.isNotEmpty
                            ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _task.attachments!.map((attachment) {
                            return _isImageFile(attachment)
                                ? GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(attachment),
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            child: const Text(
                                              'Không thể tải hình ảnh',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(attachment),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        attachment.split('/').last,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.description,
                                  color: Colors.blueAccent,
                                ),
                                title: Text(
                                  attachment.split('/').last,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Mở tệp: $attachment')),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        )
                            : const Text(
                          'Không có tệp đính kèm',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.update, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              'Trạng thái hiện tại',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Chip(
                          label: Text(
                            _getStatusDisplay(_task.status),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _getStatusColor(_task.status),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.edit_attributes, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              'Cập nhật trạng thái',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<TaskStatus>(
                          value: _task.status,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).cardColor.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: TaskStatus.values
                              .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              _getStatusDisplay(status),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                              .toList(),
                          onChanged: _isUpdatingStatus
                              ? null
                              : (value) {
                            if (value != null) {
                              _updateStatus(value);
                            }
                          },
                          dropdownColor: Theme.of(context).cardColor,
                          icon: _isUpdatingStatus
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}