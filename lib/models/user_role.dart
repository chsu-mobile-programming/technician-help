/// Роль пользователя в приложении
enum UserRole {
  teacher,
  technician;

  String get label {
    switch (this) {
      case UserRole.teacher:
        return 'Преподаватель';
      case UserRole.technician:
        return 'Техник';
    }
  }
}