import 'package:flutter/material.dart';
import '../models/call_request.dart';

class TechnicianPage extends StatelessWidget {
  const TechnicianPage({super.key});

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
              return _buildCallCard(calls[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildCallCard(CallRequest call) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Номер аудитории (крупно)
          Text(
            call.office,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(width: 16),

          // Время и ФИО
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  call.teacherName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Кнопка с галочкой
          GestureDetector(
            onTap: () => CallManager.completeCall(call),
            child: Container(
              width: 80,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(30), // Овальная
              ),
              child: const Icon(Icons.check, size: 32, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}