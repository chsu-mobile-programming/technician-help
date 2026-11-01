import 'package:flutter/material.dart';

class CallRequest {
  final String office;
  final String time;
  final String teacherName;

  CallRequest({
    required this.office,
    required this.time,
    required this.teacherName,
  });
}

class CallManager {
  /// Список активных вызовов
  static final ValueNotifier<List<CallRequest>> calls = ValueNotifier([]);

  /// Добавить новый вызов
  static void addCall(String office, String teacherName) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Создаем новый список, чтобы ValueNotifier точно уведомил слушателей
    calls.value = [
      ...calls.value,
      CallRequest(office: office, time: timeStr, teacherName: teacherName),
    ];
  }

  /// Удалить вызов (когда техник нажал на галочку)
  static void completeCall(CallRequest request) {
    calls.value = calls.value.where((c) => c != request).toList();
  }
}