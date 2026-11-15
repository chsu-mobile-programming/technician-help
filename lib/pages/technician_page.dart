import 'package:flutter/material.dart';
import '../models/call_request.dart';
import '../models/history_call.dart';
import '../services/call_manager_service.dart';
import '../services/history_manager_service.dart'; // Импорт сервиса истории
import '../services/p2p_service.dart';
import '../models/app_settings.dart';
import '../models/user_role.dart';

class TechnicianPage extends StatefulWidget {
  const TechnicianPage({super.key});

  @override
  State<TechnicianPage> createState() => _TechnicianPageState();
}

class _TechnicianPageState extends State<TechnicianPage> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    P2PService().initForRole(UserRole.technician);
  }

  void _handleAction(CallRequest call) {
    final myName = '${AppSettings.lastName.value} ${AppSettings.firstName.value}'.trim();
    final isMine = call.answeredBy == myName && call.answeredBy.isNotEmpty;

    if (!call.isAnswered) {
      // Принимаем вызов
      P2PService().sendAnswerToTeacher(call.endpointId, call.id);
      CallManager.markAsAnswered(call.id, myName); 
    } else if (isMine) {
      // Завершаем вызов и переносим в историю
      P2PService().sendCompleteToTeacher(call.endpointId, call.id);
      
      final historyEntry = HistoryCall(
        id: call.id,
        office: call.office,
        time: call.time,
        teacherName: call.teacherName,
        reason: call.reason,
        status: 'Завершен',
      );
      HistoryManager.addToHistory(historyEntry); // Сохраняем в память
      
      CallManager.removeCall(call.id); // Убираем из активных
      setState(() => _expandedIndex = null);
    }
  }

  // Окно истории
  void _showHistory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ValueListenableBuilder<List<HistoryCall>>(
          valueListenable: HistoryManager.history,
          builder: (context, historyList, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('История вызовов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (historyList.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          tooltip: 'Очистить историю',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Очистить историю?'),
                                content: const Text('Все записи будут безвозвратно удалены.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Отмена')),
                                  TextButton(
                                    onPressed: () {
                                      HistoryManager.clearHistory();
                                      Navigator.pop(dialogCtx);
                                    },
                                    child: const Text('Очистить', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: historyList.isEmpty
                      ? const Center(child: Text('История пуста'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: historyList.length,
                          itemBuilder: (context, index) {
                            final call = historyList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text('Ауд. ${call.office}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${call.teacherName}\nПричина: ${call.reason.isEmpty ? "не указана" : call.reason}\nВремя: ${call.time} (${call.status})',
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вызовы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'История вызовов',
            onPressed: _showHistory,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<CallRequest>>(
        valueListenable: CallManager.calls,
        builder: (context, calls, _) {
          if (calls.isEmpty) {
            return const Center(child: Text('Нет активных вызовов'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];
              final isExpanded = _expandedIndex == index;
              final myName = '${AppSettings.lastName.value} ${AppSettings.firstName.value}'.trim();
              final isMine = call.answeredBy == myName && call.answeredBy.isNotEmpty;

              return GestureDetector(
                onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: call.isAnswered ? (isMine ? Colors.green.shade50 : Colors.grey.shade200) : Colors.white,
                    border: Border.all(color: call.isAnswered ? (isMine ? Colors.green : Colors.grey) : Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            call.office,
                            style: TextStyle(
                              fontSize: 48, fontWeight: FontWeight.bold, height: 1,
                              color: call.isAnswered ? (isMine ? Colors.green.shade900 : Colors.grey.shade700) : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(call.time, style: const TextStyle(fontSize: 18)),
                                Text('Преподаватель:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                Text(
                                  call.shortTeacherName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis, maxLines: 1,
                                ),
                                if (call.isAnswered)
                                  Text('Взял: ${call.answeredBy}', style: TextStyle(fontSize: 13, color: isMine ? Colors.green : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                if (call.reason.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Причина: ${call.reason}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                    overflow: TextOverflow.ellipsis, maxLines: 1,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!call.isAnswered || isMine)
                            GestureDetector(
                              onTap: () => _handleAction(call),
                              child: Container(
                                width: 80, height: 60,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: call.isAnswered ? Colors.green : Colors.white,
                                  border: Border.all(color: Colors.black, width: 1.5),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Icon(
                                  call.isAnswered ? Icons.done_all : Icons.check,
                                  size: 32, 
                                  color: call.isAnswered ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _infoRow('Аудитория', call.office),
                        const SizedBox(height: 6),
                        _infoRow('Время', call.time),
                        const SizedBox(height: 6),
                        _infoRow('Преподаватель', call.teacherName),
                        const SizedBox(height: 6),
                        _infoRow('Причина', call.reason.trim().isNotEmpty ? call.reason : 'Не указана'),
                        const SizedBox(height: 6),
                        _infoRow('Статус', call.isAnswered ? (isMine ? 'В работе (вы)' : 'В работе (${call.answeredBy})') : 'Ожидает ответа'),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text('$label:', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}