import 'package:flutter/material.dart';
import 'package:ck/Flutter_Task_Manage/db/UserDatabaseHelper.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';
import 'package:ck/Flutter_Task_Manage/view/TaskListScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    if (_loginFormKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      final user = await UserDatabaseHelper.instance.getUserByUsername(username);
      if (user != null && user.password == password) {
        // Đăng nhập thành công
        // Cập nhật lastActive
        await UserDatabaseHelper.instance.updateLastActive(user.id);

        // Lưu thông tin đăng nhập
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.id);

        // Chuyển đến màn hình danh sách công việc, truyền đối tượng User
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListScreen(currentUser: user),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tên đăng nhập hoặc mật khẩu không đúng.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            children: <Widget>[
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
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Đăng nhập'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text('Chưa có tài khoản? Đăng ký ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Đăng ký
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registerFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  void _register() async {
    if (_registerFormKey.currentState!.validate()) {
      final id = DateTime.now().millisecondsSinceEpoch.toString(); // Tạo ID đơn giản
      final username = _usernameController.text;
      final password = _passwordController.text;
      final email = _emailController.text;
      final now = DateTime.now();

      final existingUser = await UserDatabaseHelper.instance.getUserByUsername(username);
      if (existingUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tên đăng nhập đã tồn tại.')),
        );
        return;
      }

      final newUser = User(
        id: id,
        username: username,
        password: password,
        email: email,
        createdAt: now,
        lastActive: now,
      );

      final result = await UserDatabaseHelper.instance.insertUser(newUser);
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng ký thành công. Vui lòng đăng nhập.')),
        );
        Navigator.pop(context); // Quay lại màn hình đăng nhập
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã có lỗi xảy ra khi đăng ký.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _registerFormKey,
          child: Column(
            children: <Widget>[
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
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}