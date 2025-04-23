enum TaskStatus { chuaLam, dangLam, hoanThanh, daHuy }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final int priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedTo;
  final String createdBy;
  final String? category;
  final List<String>? attachments;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    required this.createdBy,
    this.category,
    this.attachments,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'category': category,
      'attachments': attachments, // API chấp nhận mảng chuỗi trực tiếp
      'completed': completed,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'].toString(),
      title: map['title'],
      description: map['description'],
      status: TaskStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
        orElse: () => TaskStatus.chuaLam,
      ),
      priority: map['priority'] is String ? int.parse(map['priority']) : map['priority'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      assignedTo: map['assignedTo']?.toString(),
      createdBy: map['createdBy'].toString(),
      category: map['category'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      completed: map['completed'] is int ? map['completed'] == 1 : map['completed'],
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    int? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedTo,
    String? createdBy,
    String? category,
    List<String>? attachments,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, priority: $priority, completed: $completed)';
  }
}