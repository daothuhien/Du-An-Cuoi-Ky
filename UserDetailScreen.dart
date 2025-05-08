import 'package:flutter/material.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';
import 'package:ck/Flutter_Task_Manage/db/UserDatabaseHelper.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;
  final VoidCallback onUserUpdated;
  final bool isCurrentUser; // Thêm biến này
  UserDetailScreen(
      {Key? key,
        required this.user,
        required this.onUserUpdated,
        this.isCurrentUser = false})
      : super(key: key);

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết người dùng'),
        actions: [
          // Chỉ hiển thị nút sửa nếu là tài khoản của chính mình
          if (widget.isCurrentUser)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditDialog(context, widget.user);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên đăng nhập: ${widget.user.username}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Email: ${widget.user.email}'),
            // Hiển thị các thông tin khác của người dùng
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, User user) async {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditingController(text: user.username);
    final _emailController = TextEditingController(text: user.email);
    final _oldPasswordController =
    TextEditingController(); // Thêm controller cho mật khẩu cũ
    final _newPasswordController =
    TextEditingController(); // Thêm controller cho mật khẩu mới

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sửa thông tin người dùng'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: 'Tên đăng nhập'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Mật khẩu cũ'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu cũ';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration:
                    InputDecoration(labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)'),
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  // Thêm các trường khác nếu cần
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Lưu'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Kiểm tra mật khẩu cũ
                  if (widget.user.password != _oldPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mật khẩu cũ không đúng.')),
                    );
                    return;
                  }

                  // Cập nhật thông tin người dùng
                  final updatedUser = User(
                    id: widget.user.id,
                    username: _usernameController.text,
                    password: _newPasswordController.text.isNotEmpty
                        ? _newPasswordController.text
                        : widget.user
                        .password, // Chỉ cập nhật mật khẩu nếu có mật khẩu mới
                    email: _emailController.text,
                    avatar: widget.user.avatar,
                    createdAt: widget.user.createdAt,
                    lastActive: widget.user.lastActive,
                  );
                  await UserDatabaseHelper.instance.updateUser(updatedUser);
                  widget.onUserUpdated();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}