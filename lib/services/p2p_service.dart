import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'client.dart';
import '../models/app_settings.dart';
import 'call_manager_service.dart';
import '../models/user_role.dart';
import '../models/history_call.dart';
import '../services/history_manager_service.dart';

class P2PService {
  static final P2PService _instance = P2PService._internal();
  factory P2PService() => _instance;
  P2PService._internal();

  Teacher? _teacher;
  Technician? _technician;

  Future<void> initForRole(UserRole role) async {
    // Если уже запущено для этой роли — выходим
    if (role == UserRole.teacher && _teacher != null) return;
    if (role == UserRole.technician && _technician != null) return;

    await stop(); // Останавливаем предыдущие соединения при смене роли
    if (!await _requestPermissions()) return;

    final userName = '${AppSettings.lastName.value} ${AppSettings.firstName.value}'.trim();
    final finalName = userName.isNotEmpty ? userName : (role == UserRole.teacher ? 'Teacher' : 'Technician');

    if (role == UserRole.teacher) {
      final teacher = Teacher(name: finalName);

      teacher.onAnswerRecieved = (msg, fromId) async {
        final type = msg['type'] as String?;
        final callId = msg['callId'] as String?;
        if (callId == null) return;

        if (type == 'answer') {
          // Техник принял вызов
          final answeredBy = msg['from'] as String? ?? 'Техник';
          CallManager.markAsAnswered(callId, answeredBy);
          // Ретранслируем всем техникам, чтобы они видели, кто взял
          teacher.sendTicket({
            'type': 'status_update',
            'callId': callId,
            'answeredBy': answeredBy,
          });
        } else if (type == 'complete') {
          // Техник завершил вызов
          CallManager.removeCall(callId);
          teacher.sendTicket({'type': 'cancel', 'callId': callId});
        }
      };

      if (await teacher.start()) {
        _teacher = teacher;
        debugPrint('P2P: Teacher started (Discovery)');
      }
    } else {
      final tech = Technician(name: finalName);

      tech.onTicketRecieved = (msg, fromId) {
        final type = msg['type'] as String? ?? 'ticket';
        final callId = msg['id'] as String? ?? msg['callId'] as String?;
        if (callId == null) return;

        if (type == 'cancel') {
          // Находим вызов перед удалением, чтобы сохранить в историю
          final existing = CallManager.calls.value.where((c) => c.id == callId).firstOrNull;
          if (existing != null) {
             HistoryManager.addToHistory(HistoryCall(
               id: existing.id,
               office: existing.office,
               time: existing.time,
               teacherName: existing.teacherName,
               reason: existing.reason,
               status: 'Отменен преподавателем',
             ));
          }
          CallManager.removeCall(callId);
        }
        
        else if (type == 'status_update') {
          CallManager.markAsAnswered(callId, msg['answeredBy'] as String? ?? 'Техник');
        } else if (type == 'ticket') {
          CallManager.addCall(
            callId,
            msg['office'] as String? ?? 'Неизвестно',
            msg['from'] as String? ?? 'Преподаватель',
            msg['reason'] as String? ?? '',
            fromId, // Сохраняем ID учителя, чтобы знать кому отвечать
          );
        }
      };

      if (await tech.start()) {
        _technician = tech;
        debugPrint('P2P: Technician started (Advertising)');
      }
    }
  }

  // Отправка вызова (Преподаватель)
  Future<void> sendCall(String office, String reason, String callId) async {
    await _teacher?.sendTicket({
      'type': 'ticket',
      'id': callId,
      'office': office,
      'reason': reason,
    });
  }

  // Отмена вызова (Преподаватель)
  Future<void> cancelCall(String callId) async {
    await _teacher?.sendTicket({'type': 'cancel', 'callId': callId});
  }

  // Ответ на вызов (Техник)
  Future<void> sendAnswerToTeacher(String teacherEndpointId, String callId) async {
    final myName = '${AppSettings.lastName.value} ${AppSettings.firstName.value}'.trim();
    await _technician?.sendAnswer({
      'type': 'answer',
      'callId': callId,
      'from': myName.isNotEmpty ? myName : 'Техник',
    }, toEndpointId: teacherEndpointId);
  }

  // Завершение вызова (Техник)
  Future<void> sendCompleteToTeacher(String teacherEndpointId, String callId) async {
    await _technician?.sendAnswer({
      'type': 'complete',
      'callId': callId,
    }, toEndpointId: teacherEndpointId);
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();
    return statuses[Permission.locationWhenInUse]?.isGranted ?? false;
  }

  Future<void> stop() async {
    await _teacher?.stop();
    await _technician?.stop();
    _teacher = null;
    _technician = null;
  }
}