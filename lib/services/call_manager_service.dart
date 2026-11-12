import 'package:flutter/material.dart';
import '../models/call_request.dart';

class CallManager {
  static final ValueNotifier<List<CallRequest>> calls = ValueNotifier([]);

  static void addCall(String office, String teacherName, [String reason = '']) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    calls.value = [
      ...calls.value,
      CallRequest(
        office: office,
        time: timeStr,
        teacherName: teacherName,
        reason: reason,
      ),
    ];
  }

  static void completeCall(CallRequest request) {
    calls.value = calls.value.where((c) => c != request).toList();
  }
}