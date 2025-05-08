import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';
import 'package:ck/Flutter_Task_Manage/db/TaskDatabaseHelper.dart';
import 'package:ck/Flutter_Task_Manage/view/TaskForm.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final VoidCallback onTaskUpdated;

  const TaskDetailScreen({Key? key, required this.task, required this.onTaskUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết công việc'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskForm(task: task, onTaskSaved: (updatedTask) async {
                    await TaskDatabaseHelper.instance.updateTask(updatedTask);
                    onTaskUpdated();
                    Navigator.pop(context); // Pop form
                    Navigator.pop(context); // Pop detail screen
                  }),
                ),
              );
              if (result != null && result == true) {
                onTaskUpdated();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Divider(),
            SizedBox(height: 16),
            Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(task.description),
            SizedBox(height: 16),
            Text('Trạng thái:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(task.status),
            SizedBox(height: 16),
            Text('Độ ưu tiên:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(task.priority.toString()),
            if (task.dueDate != null) ...[
              SizedBox(height: 16),
              Text('Hạn hoàn thành:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(task.dueDate!)),
            ],
            SizedBox(height: 16),
            Text('Ngày tạo:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt)),
            SizedBox(height: 16),
            Text('Ngày cập nhật:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(DateFormat('dd/MM/yyyy HH:mm').format(task.updatedAt)),
            if (task.assignedTo != null && task.assignedTo!.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Được giao cho:', style: TextStyle(fontWeight: FontWeight.bold)),
              // Hiển thị thông tin người dùng được giao (cần truy vấn từ database)
              Text(task.assignedTo!),
            ],
            if (task.createdBy.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Người tạo:', style: TextStyle(fontWeight: FontWeight.bold)),
              // Hiển thị thông tin người dùng tạo (cần truy vấn từ database)
              Text(task.createdBy),
            ],
            if (task.category != null && task.category!.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(task.category!),
            ],
            if (task.attachments != null && task.attachments!.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Tệp đính kèm:', style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: task.attachments!.map((attachment) => Text(attachment)).toList(),
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final updatedTask = Task(
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  status: task.status == 'To do' ? 'Done' : 'To do', // Ví dụ cập nhật trạng thái
                  priority: task.priority,
                  dueDate: task.dueDate,
                  createdAt: task.createdAt,
                  updatedAt: DateTime.now(),
                  assignedTo: task.assignedTo,
                  createdBy: task.createdBy,
                  category: task.category,
                  attachments: task.attachments,
                  completed: !task.completed,
                );
                await TaskDatabaseHelper.instance.updateTask(updatedTask);
                onTaskUpdated();
                Navigator.pop(context); // Quay lại danh sách
              },
              child: Text(task.completed ? 'Đánh dấu chưa hoàn thành' : 'Đánh dấu hoàn thành'),
            ),
          ],
        ),
      ),
    );
  }
}