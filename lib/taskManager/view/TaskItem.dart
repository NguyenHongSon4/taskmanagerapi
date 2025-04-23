import 'package:flutter/material.dart';
import '../model/TaskModel.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;
  final VoidCallback onTap;

  const TaskItem({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onToggleComplete,
    required this.onTap,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
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

  Color _getStatusBackgroundColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.chuaLam:
        return Colors.blue.withOpacity(0.1);
      case TaskStatus.dangLam:
        return Colors.orange.withOpacity(0.1);
      case TaskStatus.hoanThanh:
        return Colors.green.withOpacity(0.1);
      case TaskStatus.daHuy:
        return Colors.red.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: task.completed
              ? Colors.grey.withOpacity(0.1)
              : _getStatusBackgroundColor(task.status),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.blueAccent.withOpacity(0.2),
            highlightColor: Colors.blueAccent.withOpacity(0.1),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(
                Icons.circle,
                color: _getPriorityColor(),
                size: 24,
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: task.completed ? TextDecoration.lineThrough : null,
                  color: task.completed
                      ? Colors.grey
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Trạng thái: ${_getStatusDisplay(task.status)}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Hạn: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                      style: TextStyle(
                        color: task.dueDate!.isBefore(DateTime.now())
                            ? Colors.redAccent
                            : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        task.completed
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        key: ValueKey<bool>(task.completed),
                        color: task.completed ? Colors.green : Colors.grey,
                        size: 28,
                      ),
                    ),
                    onPressed: onToggleComplete,
                    splashRadius: 24,
                    tooltip: task.completed ? 'Bỏ hoàn thành' : 'Hoàn thành',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                    onPressed: onDelete,
                    splashRadius: 24,
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}