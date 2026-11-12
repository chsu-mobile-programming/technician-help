import 'package:flutter/material.dart';
import '../models/call_request.dart';
import '../services/call_manager_service.dart';

class TechnicianPage extends StatefulWidget {
  const TechnicianPage({super.key});

  @override
  State<TechnicianPage> createState() => _TechnicianPageState();
}

class _TechnicianPageState extends State<TechnicianPage> {
  /// Индекс раскрытой карточки (null — все свёрнуты)
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вызовы')),
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
              return _buildCallCard(
                calls[index],
                isExpanded: _expandedIndex == index,
                onTap: () {
                  setState(() {
                    _expandedIndex = _expandedIndex == index ? null : index;
                  });
                },
                onComplete: () {
                  setState(() {
                    if (_expandedIndex == index) _expandedIndex = null;
                  });
                  CallManager.completeCall(calls[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCallCard(
    CallRequest call, {
    required bool isExpanded,
    required VoidCallback onTap,
    required VoidCallback onComplete,
  }) {
    final hasReason = call.reason.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Свёрнутая строка (всегда видна) ===
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Номер аудитории
                Text(
                  call.office,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 16),

                // Время, ФИО (сокращённое), причина
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        call.time,
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Преподаватель:',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        call.shortTeacherName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (hasReason) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Причина: ${call.reason}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Кнопка «выполнено»
                GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    width: 80,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.check, size: 32, color: Colors.black),
                  ),
                ),
              ],
            ),

            // === Развёрнутая часть (полная информация) ===
            if (isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _infoRow('Аудитория', call.office),
              const SizedBox(height: 6),
              _infoRow('Время', call.time),
              const SizedBox(height: 6),
              _infoRow('Преподаватель', call.teacherName), // полное ФИО
              const SizedBox(height: 6),
              _infoRow(
                'Причина',
                hasReason ? call.reason : 'Не указана',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}