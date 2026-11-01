import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../models/app_settings.dart'; // путь к вашему файлу с AppSettings
import 'teacher_page.dart';
import 'technician_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  bool _isDestinationEnabled(int index, UserRole role) {
    switch (index) {
      case 0:
        return role == UserRole.teacher;
      case 1:
        return role == UserRole.technician;
      case 2:
        return true;
      default:
        return false;
    }
  }

  Widget _pageAt(int index, UserRole role) {
    switch (index) {
      case 0:
        return TeacherPage(
          onGoToSettings: () => _onItemTapped(2, role),
        );
      case 1:
        return TechnicianPage();
      case 2:
      default:
        return SettingsPage(
          role: role,
          onRoleChanged: _onRoleChanged,
        );
    }
  }

  int _indexAt(UserRole role){
    switch(role){
      case UserRole.teacher:
        return 0;
      case UserRole.technician:
        return 1;
    }
  }

  /// Смена роли → пишем в AppSettings и сохраняем на диск
  Future<void> _onRoleChanged(UserRole newRole) async {
    AppSettings.role.value = newRole;
    await AppSettings.save();

    // Если текущая вкладка стала недоступной для новой роли — уводим в настройки
    if (!_isDestinationEnabled(_selectedIndex, newRole)) {
      setState(() => _selectedIndex = 2);
    }
  }

  void _onItemTapped(int index, UserRole role) {
    if (!_isDestinationEnabled(index, role)) return;
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexAt(AppSettings.role.value);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserRole>(
      valueListenable: AppSettings.role,
      builder: (context, role, _) {
        return Scaffold(
          body: _pageAt(_selectedIndex, role),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => _onItemTapped(i, role),
            destinations: [
              _buildDestination(0, role, Icons.person_outline, Icons.person, 'Преподаватель'),
              _buildDestination(1, role, Icons.build_outlined, Icons.build, 'Техник'),
              _buildDestination(2, role, Icons.settings, Icons.settings, 'Настройки'),
            ],
          ),
        );
      },
    );
  }

  NavigationDestination _buildDestination(
    int index,
    UserRole role,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final enabled = _isDestinationEnabled(index, role);
    return NavigationDestination(
      icon: Icon(icon, color: enabled ? null : Colors.grey.shade400),
      selectedIcon: Icon(selectedIcon, color: enabled ? null : Colors.grey.shade400),
      label: label,
      enabled: enabled,
    );
  }
}