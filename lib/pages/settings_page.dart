import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../models/app_settings.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({
    super.key,
    required this.role,
    required this.onRoleChanged,
  });

  final UserRole role;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: AppSettings.firstName.value);
    _lastNameCtrl = TextEditingController(text: AppSettings.lastName.value);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    AppSettings.firstName.value = _firstNameCtrl.text.trim();
    AppSettings.lastName.value = _lastNameCtrl.text.trim();
    await AppSettings.save();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранено')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === Аккаунт ===
          const Text(
            'Аккаунт',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _lastNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Фамилия',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveAccount(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saveAccount,
                      icon: const Icon(Icons.save),
                      label: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // === Аудитория по умолчанию ===
          const Text(
            'Аудитория по умолчанию',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: AppSettings.defaultOffice.value,
                decoration: const InputDecoration(
                  labelText: 'Аудитория',
                  border: InputBorder.none,
                ),
                items: AppSettings.offices
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  AppSettings.defaultOffice.value = value;
                  await AppSettings.save(); // сохраняем сразу
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // === Роль ===
          const Text(
            'Роль',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<UserRole>(
                  value: UserRole.teacher,
                  groupValue: widget.role,
                  onChanged: (value) {
                    if (value != null && value != widget.role) {
                      widget.onRoleChanged(value);
                    }
                  },
                  title: const Text('Преподаватель'),
                  subtitle: const Text('Доступ: страница преподавателя и настройки'),
                  secondary: const Icon(Icons.person),
                ),
                const Divider(height: 1),
                RadioListTile<UserRole>(
                  value: UserRole.technician,
                  groupValue: widget.role,
                  onChanged: (value) {
                    if (value != null && value != widget.role) {
                      widget.onRoleChanged(value);
                    }
                  },
                  title: const Text('Техник'),
                  subtitle: const Text('Доступ: страница техника и настройки'),
                  secondary: const Icon(Icons.build),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}