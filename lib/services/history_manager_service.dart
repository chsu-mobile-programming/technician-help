import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_call.dart';

class HistoryManager {
  static const String _historyKey = 'calls_history';
  
  // Реактивный список для UI
  static final ValueNotifier<List<HistoryCall>> history = ValueNotifier([]);

  /// Загрузить историю из памяти телефона
  static Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        history.value = decoded.map((e) => HistoryCall.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Ошибка при загрузке истории: $e');
        history.value = [];
      }
    }
  }

  /// Добавить вызов в историю
  static Future<void> addToHistory(HistoryCall call) async {
    // Добавляем в начало списка (чтобы новые были сверху)
    history.value = [call, ...history.value];
    await _saveHistory();
  }

  /// Очистить всю историю
  static Future<void> clearHistory() async {
    history.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(history.value.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }
}