import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../models/app_settings.dart';
import 'teacher_page.dart';
import 'technician_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Текущий выбранный индекс СРЕДИ ДОСТУПНЫХ вкладок
  int _currentIndex = 0;

  /// Возвращает список доступных вкладок для конкретной роли
  List<_TabItem> _getTabsForRole(UserRole role) {
    final allTabs = [
      _TabItem(
        id: 0,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Преподаватель',
        page: TeacherPage(),
      ),
      _TabItem(
        id: 1,
        icon: Icons.build_outlined,
        selectedIcon: Icons.build,
        label: 'Техник',
        page: const TechnicianPage(),
      ),
      _TabItem(
        id: 2,
        icon: Icons.settings,
        selectedIcon: Icons.settings,
        label: 'Настройки',
        page: null, // Создается отдельно, так как требует параметров
      ),
    ];

    switch (role) {
      case UserRole.teacher:
        return [allTabs[0], allTabs[2]];
      case UserRole.technician:
        return [allTabs[1], allTabs[2]];
      case UserRole.admin:
        return allTabs;
    }
  }

  Future<void> _onRoleChanged(UserRole newRole) async {
    AppSettings.role.value = newRole;
    await AppSettings.save();

    // При смене роли сбрасываем индекс на первую доступную вкладку
    setState(() => _currentIndex = 0);
  }

  /// Переход на вкладку настроек (вызывается из TeacherPage)
  void _goToSettings(UserRole role) {
    final tabs = _getTabsForRole(role);
    final settingsIndex = tabs.indexWhere((t) => t.id == 2);
    if (settingsIndex != -1) {
      setState(() => _currentIndex = settingsIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserRole>(
      valueListenable: AppSettings.role,
      builder: (context, role, _) {
        final tabs = _getTabsForRole(role);

        // Защита от выхода индекса за пределы (например, при смене роли)
        if (_currentIndex >= tabs.length) {
          _currentIndex = 0;
        }

        // Формируем страницы для IndexedStack на основе доступных вкладок
        final pages = tabs.map((tab) {
          if (tab.id == 0) {
            return TeacherPage(onGoToSettings: () => _goToSettings(role));
          }
          if (tab.id == 1) {
            return const TechnicianPage();
          }
          return SettingsPage(role: role, onRoleChanged: _onRoleChanged);
        }).toList();

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: tabs.map((tab) {
              return NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Вспомогательный класс для описания вкладки
class _TabItem {
  final int id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget? page;

  _TabItem({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.page,
  });
}