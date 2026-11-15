import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:technicianhelp/models/user_role.dart';

/// Глобальные настройки приложения с сохранением на диск.
class AppSettings {
  static const _FirstName = 'first_name';
  static const _LastName = 'last_name';
  static const _DefaultOffice = 'default_office';
  static const _Role = 'role';
  static const _OnboardingDone = 'onboarding_done';

  static final ValueNotifier<String> defaultOffice = ValueNotifier<String>('205');
  static final ValueNotifier<String> firstName = ValueNotifier<String>('');
  static final ValueNotifier<String> lastName = ValueNotifier<String>('');
  static final ValueNotifier<UserRole> role =
      ValueNotifier<UserRole>(UserRole.teacher);

  /// true — пользователь уже прошёл первичную настройку
  static final ValueNotifier<bool> onboardingDone = ValueNotifier<bool>(false);

  static const List<String> offices = [
    '201', '202', '203', '204', '205',
    '212', '213', '214', '215', '216', '217', '218', '218а', '219', '220', '221',
    '222', '223', '224', '225', '226', '227', '228', '229', '230',
  ];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    defaultOffice.value = prefs.getString(_DefaultOffice) ?? '205';
    firstName.value = prefs.getString(_FirstName) ?? '';
    lastName.value = prefs.getString(_LastName) ?? '';
    role.value = takeRole1(prefs.getString(_Role) ?? '');
    onboardingDone.value = prefs.getBool(_OnboardingDone) ?? false;
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_DefaultOffice, defaultOffice.value);
    await prefs.setString(_FirstName, firstName.value);
    await prefs.setString(_LastName, lastName.value);
    await prefs.setString(_Role, takeRole2(role.value));
    await prefs.setBool(_OnboardingDone, onboardingDone.value);
  }

  static UserRole takeRole1(String role) {
    switch (role) {
      case 'teacher':
        return UserRole.teacher;
      case 'technician':
        return UserRole.technician;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.teacher;
    }
  }

  static String takeRole2(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return 'teacher';
      case UserRole.technician:
        return 'technician';
      case UserRole.admin:
        return 'admin';
    }
  }
}