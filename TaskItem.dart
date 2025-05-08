import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool?> onCompleteChanged;

  const TaskItem({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onCompleteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color priorityColor = Colors.grey;
    if (task.priority == 3) {
      priorityColor = Colors.red;
    } else if (task.priority == 2) {
      priorityColor = Colors.orange;
    } else if (task.priority == 1) {
      priorityColor = Colors.green;
    }

    IconData statusIcon;
    Color statusColor;
    switch (task.status) {
      case 'To do':
        statusIcon = Icons.radio_button_unchecked;
        statusColor = Colors.grey;
        break;
      case 'In progress':
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.blue;
        break;
      case 'Done':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'Cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.black;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: priorityColor.withOpacity(0.3),
          child: Text(task.priority.toString(), style: TextStyle(color: priorityColor)),
        ),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (task.dueDate != null)
              Text('Hạn: ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}', style: TextStyle(fontSize: 12)),
            if (task.category != null && task.category!.isNotEmpty)
              Text('Danh mục: ${task.category}', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task.completed,
              onChanged: onCompleteChanged,
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}