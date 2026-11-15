import 'package:flutter/material.dart';
import '../models/call_request.dart';

class CallManager {
  static final ValueNotifier<List<CallRequest>> calls = ValueNotifier([]);

  static void addCall(String id, String office, String teacherName, [String reason = '', String endpointId = '']) {
    if (calls.value.any((c) => c.id == id)) return; // Защита от дубликатов

    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    calls.value = [
      ...calls.value,
      CallRequest(
        id: id,
        office: office,
        time: timeStr,
        teacherName: teacherName,
        reason: reason,
        endpointId: endpointId,
      ),
    ];
  }

  static void removeCall(String callId) {
    calls.value = calls.value.where((c) => c.id != callId).toList();
  }

  static void markAsAnswered(String callId, String answeredBy) {
    calls.value = calls.value.map((c) {
      if (c.id == callId) return c.copyWith(isAnswered: true, answeredBy: answeredBy);
      return c;
    }).toList();
  }
}