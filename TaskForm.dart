import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';
import 'package:ck/Flutter_Task_Manage/db/UserDatabaseHelper.dart';
import 'package:ck/Flutter_Task_Manage/db/TaskDatabaseHelper.dart';
import 'package:file_picker/file_picker.dart';

class TaskForm extends StatefulWidget {
  final Task? task; // Null nếu tạo mới
  final Function(Task) onTaskSaved;

  const TaskForm({Key? key, this.task, required this.onTaskSaved}) : super(key: key);

  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedStatus = 'To do';
  int _selectedPriority = 1;
  DateTime? _dueDate;
  String? _assignedToUser;
  List<String> _selectedFiles = []; // Để lưu trữ tên các tệp đã chọn
  List<String> _availableUsers = []; // Để hiển thị danh sách người dùng

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedStatus = widget.task!.status;
      _selectedPriority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      _assignedToUser = widget.task!.assignedTo;
      _selectedFiles = widget.task!.attachments ?? [];
    }
  }

  Future<void> _loadAvailableUsers() async {
    final users = await UserDatabaseHelper.instance.getAllUsers();
    setState(() {
      _availableUsers = users.map((user) => user.id).toList();
      if (widget.task != null && _assignedToUser != null && !_availableUsers.contains(_assignedToUser)) {
        _availableUsers.add(_assignedToUser!); // Đảm bảo người được giao hiện tại vẫn có trong danh sách
      }
    });
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files.map((file) => file.name));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final task = Task(
        id: widget.task?.id ?? now.millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        status: _selectedStatus,
        priority: _selectedPriority,
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt ?? now,
        updatedAt: now,
        assignedTo: _assignedToUser,
        createdBy: 'currentUser', // Cần lấy ID người dùng hiện tại
        category: null, // Thêm logic chọn category nếu cần
        attachments: _selectedFiles,
        completed: widget.task?.completed ?? false,
      );

      final taskDbHelper = TaskDatabaseHelper.instance; // Lấy instance của TaskDatabaseHelper

      if (widget.task == null) {
        // Thêm mới
        final result = await taskDbHelper.insertTask(task); // Sử dụng TaskDatabaseHelper
        if (result > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Công việc đã được thêm.')),
          );
          widget.onTaskSaved(task);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã có lỗi xảy ra khi thêm công việc.')),
          );
        }
      } else {
        // Cập nhật
        final result = await taskDbHelper.updateTask(task); // Sử dụng TaskDatabaseHelper
        if (result > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Công việc đã được cập nhật.')),
          );
          widget.onTaskSaved(task);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã có lỗi xảy ra khi cập nhật công việc.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Thêm công việc mới' : 'Sửa công việc'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                value: _selectedStatus,
                items: <String>['To do', 'In progress', 'Done', 'Cancelled']
                    .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Độ ưu tiên: '),
                  Radio<int>(
                    value: 1,
                    groupValue: _selectedPriority,
                    onChanged: (value) => setState(() => _selectedPriority = value!),
                  ),
                  Text('Thấp'),
                  Radio<int>(
                    value: 2,
                    groupValue: _selectedPriority,
                    onChanged: (value) => setState(() => _selectedPriority = value!),
                  ),
                  Text('Trung bình'),
                  Radio<int>(
                    value: 3,
                    groupValue: _selectedPriority,
                    onChanged: (value) => setState(() => _selectedPriority = value!),
                  ),
                  Text('Cao'),
                ],
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDueDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Hạn hoàn thành',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(_dueDate == null ? 'Chọn ngày và giờ' : DateFormat('dd/MM/yyyy HH:mm').format(_dueDate!)),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Giao cho (ID người dùng)', border: OutlineInputBorder()),
                value: _assignedToUser,
                items: _availableUsers
                    .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _assignedToUser = newValue;
                  });
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Tệp đính kèm: '),
                  ElevatedButton(
                    onPressed: _pickFiles,
                    child: Text('Chọn tệp'),
                  ),
                ],
              ),
              if (_selectedFiles.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text('Đã chọn:'),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final fileName = _selectedFiles[index];
                        return Row(
                          children: [
                            Expanded(child: Text(fileName)),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _removeFile(index),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  child: Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}