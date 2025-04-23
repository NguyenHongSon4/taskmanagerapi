import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taskmanagerapi/taskManager/model/TaskModel.dart';
import 'package:taskmanagerapi/taskManager/model/UserModel.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Sử dụng 10.0.2.2 thay cho localhost khi chạy trên emulator

  // Lấy tất cả tasks của user
  Future<List<Task>> getAllTasks(String createdBy) async {
    final response = await http.get(Uri.parse('$baseUrl/tasks/$createdBy'));
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Task.fromMap(data)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  // Tạo task mới
  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toMap()),
    );
    if (response.statusCode == 201) {
      return Task.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create task');
    }
  }

  // Cập nhật task
  Future<Task> updateTask(Task task) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/${task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toMap()),
    );
    if (response.statusCode == 200) {
      return Task.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update task');
    }
  }

  // Xóa task
  Future<void> deleteTask(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  // Lấy tất cả users
  Future<List<User>> getAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => User.fromMap(data)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Tạo user mới
  Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toMap()),
    );
    if (response.statusCode == 201) {
      return User.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user');
    }
  }

  // Cập nhật user
  Future<User> updateUser(User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toMap()),
    );
    if (response.statusCode == 200) {
      return User.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user');
    }
  }

  // Xóa user
  Future<void> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}