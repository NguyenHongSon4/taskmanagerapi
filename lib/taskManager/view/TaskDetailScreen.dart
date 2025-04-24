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
  late Animation<double> _scaleAnimation; // NEW: Added for card scale animation
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
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    )); // NEW: Scale animation for cards
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
            fontWeight: FontWeight.w600, // CHANGED: Slightly lighter weight for elegance
            fontSize: 20, // CHANGED: Slightly smaller for balance
          ),
        ),
        elevation: 0, // CHANGED: Removed elevation for a flatter design
        backgroundColor: Colors.transparent, // CHANGED: Transparent for blur effect
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.withOpacity(0.9), Colors.cyan.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editTask,
            splashRadius: 24, // CHANGED: Added for better tap feedback
          ),
          IconButton(
            icon: Icon(
              themeSwitching?.isDarkMode ?? false ? Icons.brightness_7 : Icons.brightness_4,
              color: Colors.white,
            ),
            onPressed: themeSwitching?.toggleTheme,
            splashRadius: 24, // CHANGED: Added for better tap feedback
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), // CHANGED: Increased vertical padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Details Card
                ScaleTransition(
                  scale: _scaleAnimation, // NEW: Added scale animation
                  child: Card(
                    elevation: 6, // CHANGED: Slightly higher elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // CHANGED: Larger radius for modern look
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // CHANGED: Increased padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _task.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                              fontSize: 24, // CHANGED: Larger for emphasis
                            ),
                          ),
                          const SizedBox(height: 20), // CHANGED: Increased spacing
                          _buildListTile(
                            icon: Icons.description,
                            title: 'Mô tả',
                            subtitle: _task.description ?? 'Không có',
                          ),
                          const Divider(height: 24), // CHANGED: Added spacing
                          _buildListTile(
                            icon: Icons.flag,
                            title: 'Độ ưu tiên',
                            subtitleWidget: Chip(
                              label: Text(
                                _getPriorityDisplay(_task.priority),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _getPriorityColor(_task.priority),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // CHANGED: Added padding
                            ),
                          ),
                          const Divider(height: 24),
                          _buildListTile(
                            icon: Icons.calendar_today,
                            title: 'Hạn hoàn thành',
                            subtitle: _task.dueDate != null ? _task.dueDate.toString().split('.')[0] : 'Không có',
                          ),
                          const Divider(height: 24),
                          _buildListTile(
                            icon: Icons.access_time,
                            title: 'Thời gian tạo',
                            subtitle: _task.createdAt.toString().split('.')[0],
                          ),
                          const Divider(height: 24),
                          _buildListTile(
                            icon: Icons.update,
                            title: 'Cập nhật gần nhất',
                            subtitle: _task.updatedAt.toString().split('.')[0],
                          ),
                          const Divider(height: 24),
                          _buildListTile(
                            icon: Icons.person,
                            title: 'Người được giao',
                            subtitle: _task.assignedTo ?? 'Không có',
                          ),
                          const Divider(height: 24),
                          _buildListTile(
                            icon: Icons.person_add,
                            title: 'Người tạo',
                            subtitle: _task.createdBy,
                          ),
                          const Divider(height: 24),
                          _buildListTile(
                            icon: Icons.category,
                            title: 'Danh mục',
                            subtitle: _task.category ?? 'Không có',
                          ),
                          const Divider(height: 24),
                          _buildListTile(
                            icon: Icons.check_circle,
                            title: 'Hoàn thành',
                            subtitle: _task.completed ? 'Có' : 'Không',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24), // CHANGED: Increased spacing
                // Attachments Card
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attach_file, color: Colors.blueAccent),
                              const SizedBox(width: 12),
                              Text(
                                'Tệp đính kèm',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _task.attachments != null && _task.attachments!.isNotEmpty
                              ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: _task.attachments!.length,
                            itemBuilder: (context, index) {
                              final attachment = _task.attachments![index];
                              return _isImageFile(attachment)
                                  ? _buildImageAttachment(attachment)
                                  : _buildFileAttachment(attachment);
                            },
                          )
                              : Text(
                            'Không có tệp đính kèm',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Status Card
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.update, color: Colors.blueAccent),
                              const SizedBox(width: 12),
                              Text(
                                'Trạng thái hiện tại',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Chip(
                            label: Text(
                              _getStatusDisplay(_task.status),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getStatusColor(_task.status),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // CHANGED: Rounded chip
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.edit_attributes, color: Colors.blueAccent),
                              const SizedBox(width: 12),
                              Text(
                                'Cập nhật trạng thái',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<TaskStatus>(
                            value: _task.status,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).cardColor.withOpacity(0.2), // CHANGED: Slightly darker fill
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Helper method to build ListTile for consistency
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blueAccent, size: 28), // CHANGED: Larger icon
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
      subtitle: subtitleWidget ??
          Text(
            subtitle ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
    );
  }

  // NEW: Helper method to build image attachment
  Widget _buildImageAttachment(String attachment) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(attachment),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                attachment.split('/').last,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Helper method to build file attachment
  Widget _buildFileAttachment(String attachment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mở tệp: $attachment')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(
                Icons.description,
                color: Colors.blueAccent,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  attachment.split('/').last,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}