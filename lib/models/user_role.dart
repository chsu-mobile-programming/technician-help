import 'package:flutter/material.dart';

/// Роль пользователя в приложении
enum UserRole {
  teacher,
  technician,
  admin;

  /// Читаемое название роли
  String get title {
    switch (this) {
      case UserRole.teacher:
        return 'Преподаватель';
      case UserRole.technician:
        return 'Техник';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  /// Иконка роли
  IconData get icon {
    switch (this) {
      case UserRole.teacher:
        return Icons.person;
      case UserRole.technician:
        return Icons.build;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  /// Доступные вкладки навигации (индексы: 0 — преподаватель, 1 — техник, 2 — настройки)
  List<int> get availableTabs {
    switch (this) {
      case UserRole.teacher:
        return [0, 2];
      case UserRole.technician:
        return [1, 2];
      case UserRole.admin:
        return [0, 1, 2];
    }
  }
}