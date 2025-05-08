import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';
import 'package:ck/Flutter_Task_Manage/db/TaskDatabaseHelper.dart';
import 'package:ck/Flutter_Task_Manage/view/TaskItem.dart';
import 'package:ck/Flutter_Task_Manage/view/TaskDetailScreen.dart';
import 'package:ck/Flutter_Task_Manage/view/TaskForm.dart';
import 'package:ck/Flutter_Task_Manage/db/UserDatabaseHelper.dart';
import 'package:ck/Flutter_Task_Manage/view/LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ck/Flutter_Task_Manage/view/UserListScreen.dart';

class TaskListScreen extends StatefulWidget {
  final User? currentUser;

  TaskListScreen({this.currentUser});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> _tasksFuture;
  bool _isKanbanView = false;
  String _selectedStatusFilter = 'All';
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkCurrentUserAndLogoutIfDeleted(context); //  Thêm ở đây
    _refreshTasks();
  }

  Future<void> _refreshTasks() async {
    setState(() {
      if (_searchQuery.isNotEmpty) {
        _tasksFuture = TaskDatabaseHelper.instance.searchTasks(_searchQuery);
      } else if (_selectedStatusFilter != 'All') {
        _tasksFuture = TaskDatabaseHelper.instance.getTasksByStatus(_selectedStatusFilter);
      } else if (_selectedCategoryFilter != 'All') {
        _tasksFuture = TaskDatabaseHelper.instance.getTasksByCategory(_selectedCategoryFilter);
      } else {
        _tasksFuture = TaskDatabaseHelper.instance.getAllTasks();
      }
    });
  }

  void _openTaskDetail(Task task) async {
    await _checkCurrentUserAndLogoutIfDeleted(context); //  Thêm ở đây
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task, onTaskUpdated: _refreshTasks),
      ),
    );
  }

  void _openTaskForm({Task? task}) async {
    await _checkCurrentUserAndLogoutIfDeleted(context); //  Thêm ở đây
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskForm(
          task: task,
          onTaskSaved: (newTask) {
            _refreshTasks();
          },
        ),
      ),
    );
    if (result != null && result == true) {
      _refreshTasks();
    }
  }

  Future<void> _deleteTask(Task task) async {
    await _checkCurrentUserAndLogoutIfDeleted(context); //  Thêm ở đây
    if (!mounted) return;

    await TaskDatabaseHelper.instance.deleteTask(task.id);
    _refreshTasks();
  }

  Future<void> _updateTask(Task task, bool completed) async {
    await _checkCurrentUserAndLogoutIfDeleted(context); //  Thêm ở đây
    if (!mounted) return;

    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      assignedTo: task.assignedTo,
      createdBy: task.createdBy,
      category: task.category,
      attachments: task.attachments,
      completed: completed,
    );
    TaskDatabaseHelper.instance.updateTask(updatedTask).then((_) {
      _refreshTasks();
    });
  }

  Future<void> _logout(BuildContext context) async {
    // Xóa thông tin đăng nhập
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id'); //  Xóa userId

    // Chuyển về màn hình đăng nhập
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách công việc', style: TextStyle(fontSize: 20),),
        leading: _buildUserAvatar(), // Gọi hàm tạo avatar
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _logout(context), // Nút đăng xuất
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedStatusFilter = value;
                _refreshTasks();
              });
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'All', child: Text('Tất cả trạng thái')),
                const PopupMenuItem<String>(value: 'To do', child: Text('To do')),
                const PopupMenuItem<String>(value: 'In progress', child: Text('In progress')),
                const PopupMenuItem<String>(value: 'Done', child: Text('Done')),
                const PopupMenuItem<String>(value: 'Cancelled', child: Text('Cancelled')),
              ];
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text('Trạng thái: $_selectedStatusFilter'),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          // Thêm PopupMenuButton cho lọc theo danh mục nếu cần
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _refreshTasks();
                });
              },
              decoration: InputDecoration(
                labelText: 'Tìm kiếm công việc',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Không có công việc nào.'));
                } else {
                  if (_isKanbanView) {
                    // Xây dựng giao diện Kanban Board (sẽ phức tạp hơn)
                    return Text('Chế độ Kanban (chưa triển khai)');
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final task = snapshot.data![index];
                        return TaskItem(
                          task: task,
                          onTap: () => _openTaskDetail(task),
                          onEdit: () => _openTaskForm(task: task),
                          onDelete: () async {
                            await TaskDatabaseHelper.instance.deleteTask(task.id);
                            _refreshTasks();
                          },
                          onCompleteChanged: (bool? newvalue) async {
                            if (newvalue != null) {
                              final updatedTask = Task(
                                id: task.id,
                                title: task.title,
                                description: task.description,
                                status: task.status,
                                priority: task.priority,
                                dueDate: task.dueDate,
                                createdAt: task.createdAt,
                                updatedAt: DateTime.now(),
                                assignedTo: task.assignedTo,
                                createdBy: task.createdBy,
                                category: task.category,
                                attachments: task.attachments,
                                completed: newvalue,
                              );
                              TaskDatabaseHelper.instance.updateTask(updatedTask).then((_) {
                                _refreshTasks();
                              });
                            }
                          },
                        );
                      },
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _openTaskForm(),
      ),
    );
  }

  Widget _buildUserAvatar() {
    if (widget.currentUser != null) {
      return GestureDetector(
        onTap: () {
          //  Điều hướng đến UserListScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserListScreen(currentUser: widget.currentUser)),
          );
        },
        child: CircleAvatar(
          // Hiển thị avatar
          child: widget.currentUser!.avatar != null
              ? Image.network(widget.currentUser!.avatar!)
              : Text(widget.currentUser!.username[0].toUpperCase()),
        ),
      );
    } else {
      return CircleAvatar(child: Icon(Icons.person)); // Avatar mặc định
    }
  }

  Future<void> _checkCurrentUserAndLogoutIfDeleted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      final user = await UserDatabaseHelper.instance.getUserById(userId);
      if (user == null) {
        // Người dùng đã bị xóa, tiến hành đăng xuất
        await prefs.remove('user_id');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tài khoản của bạn đã bị xóa.')),
        );
      }
    } else {
      // Không có userId trong SharedPreferences, có thể chưa đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
}
