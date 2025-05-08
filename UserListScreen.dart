import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ck/Flutter_Task_Manage/db/UserDatabaseHelper.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';
import 'package:ck/Flutter_Task_Manage/view/LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ck/Flutter_Task_Manage/view/UserDetailScreen.dart';

class UserListScreen extends StatefulWidget {
  final User? currentUser; // Nhận vào người dùng hiện tại
  UserListScreen({required this.currentUser});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _usersFuture = UserDatabaseHelper.instance.getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách người dùng'),
      ),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Không có người dùng nào.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final user = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      // Hiển thị avatar hoặc chữ cái đầu
                      child: user.avatar != null
                          ? Image.network(user.avatar!)
                          : Text(user.username[0].toUpperCase()),
                    ),
                    title: Text(user.username),
                    subtitle: Text('Email: ${user.email}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chỉ hiển thị nút sửa và xóa nếu là tài khoản của chính mình
                        if (widget.currentUser!.id == user.id)
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailScreen(
                                      user: user,
                                      onUserUpdated: _loadUsers,
                                      isCurrentUser: true),
                                ),
                              );
                            },
                          ),
                        if (widget.currentUser!.id == user.id)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteUser(user.id);
                            },
                          ),
                      ],
                    ),
                    onTap: () {
                      // Khi nhấn vào, chỉ xem chi tiết
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserDetailScreen(
                              user: user,
                              onUserUpdated: _loadUsers,
                              isCurrentUser:
                              widget.currentUser!.id == user.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Cho phép người dùng hiện tại tạo tài khoản mới
          if (widget.currentUser!.id == widget.currentUser!.id)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterScreen(),
              ),
            ).then((value) {
              if (value == true) {
                _loadUsers();
              }
            });
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteUser(String id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Xác nhận"),
          content: Text("Bạn có chắc chắn muốn xóa tài khoản này?"),
          actions: [
            TextButton(
              child: Text("Hủy"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("Xóa"),
              onPressed: () async {
                Navigator.of(context).pop(); // Đóng dialog xác nhận
                await UserDatabaseHelper.instance.deleteUser(id);
                if (widget.currentUser!.id == id) {
                  // Nếu xóa chính mình, thực hiện đăng xuất
                  _logout(context,
                      "Tài khoản của bạn đã bị xóa."); // Truyền thêm thông báo
                } else {
                  _loadUsers(); // Nếu không, chỉ tải lại danh sách người dùng
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, String? message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
