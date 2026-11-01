import 'package:flutter/material.dart';
import '../models/user_role.dart';

/// Страница настроек с выбором роли
class SettingsPage extends StatelessWidget {
  SettingsPage({
    super.key,
    required this.role,
    required this.onRoleChanged,
  });

  final UserRole role;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Роль',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<UserRole>(
                  value: UserRole.teacher,
                  groupValue: role,
                  onChanged: (value) {
                    if (value != null && value != role) {
                      onRoleChanged(value);
                    }
                  },
                  title: Text('Преподаватель'),
                  subtitle: Text(
                    'Доступ: страница преподавателя и настройки',
                  ),
                  secondary: Icon(Icons.person),
                ),
                Divider(height: 1),
                RadioListTile<UserRole>(
                  value: UserRole.technician,
                  groupValue: role,
                  onChanged: (value) {
                    if (value != null && value != role) {
                      onRoleChanged(value);
                    }
                  },
                  title: Text('Техник'),
                  subtitle: Text(
                    'Доступ: страница техника и настройки',
                  ),
                  secondary: Icon(Icons.build),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}