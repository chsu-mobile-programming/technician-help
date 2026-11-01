import 'package:flutter/material.dart';
import '../models/user_role.dart';
import 'teacher_page.dart';
import 'technician_page.dart';
import 'settings_page.dart';

/// Главный экран
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserRole _role = UserRole.teacher; // Текущая роль пользователя
  int _selectedIndex = 0; // Индекс выбранной вкладки


  /// Доступна ли страница по индексу для текущей роли
  /// Индексы: 0 — преподаватель, 1 — техник, 2 — настройки
  bool _isDestinationEnabled(int index) {
    switch (index) {
      case 0:
        return _role == UserRole.teacher;
      case 1:
        return _role == UserRole.technician;
      case 2:
        return true;
      default:
        return false;
    }
  }

  /// Получить страницу по индексу
  Widget _pageAt(int index) {
    switch (index) {
      case 0:
        return TeacherPage();
      case 1:
        return TechnicianPage();
      case 2:
      default:
        return SettingsPage(
          role: _role,
          onRoleChanged: _onRoleChanged,
        );
    }
  }

  /// Смена роли (Происходит при смене роли)
  void _onRoleChanged(UserRole newRole) {
    setState(() {
      _role = newRole;
    });
  }

  /// Обработка нажатий на кнопки на нижней панели навигации
  void _onItemTapped(int index) {
    // Игнорируем нажатия по заблокированным пунктам
    if (!_isDestinationEnabled(index)) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _pageAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          _buildDestination(0, Icons.person_outline, Icons.person,'Преподаватель'),
          _buildDestination(1, Icons.build_outlined, Icons.build,'Техник'),
          _buildDestination(2, Icons.settings, Icons.settings, 'Настройки'),
        ],
      ),
    );
  }

  NavigationDestination _buildDestination(int index, IconData icon, IconData selectedIcon, String label) {
    final enabled = _isDestinationEnabled(index);

    // Для заблокированного пункта — серая иконка (enabled: false сам
    // делает подпись серой и отключает реакцию на нажатие).
    return NavigationDestination(
      icon: Icon(
        icon,
        color: enabled ? null : Colors.grey.shade400,
      ),
      selectedIcon: Icon(
        selectedIcon,
        color: enabled ? null : Colors.grey.shade400,
      ),
      label: label,
      enabled: enabled,
    );
  }
}