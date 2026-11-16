import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/call_manager_service.dart';
import '../services/p2p_service.dart';
import '../models/call_request.dart';
import '../models/user_role.dart';

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key, this.onGoToSettings});
  final VoidCallback? onGoToSettings;

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  int _selected = -1;
  int _selectedCallButton = 0;
  String _selectedOffice = AppSettings.defaultOffice.value;

  static const List<String> _commonReasons = [
    'Проектор не работает', 'Нет интернета', 'Не работает компьютер',
    'Проблема со звуком', 'Не работает доска', 'Другое',
  ];

  String? _selectedReason;
  late final TextEditingController _customReasonCtrl;

  @override
  void initState() {
    super.initState();
    _customReasonCtrl = TextEditingController();
    P2PService().initForRole(UserRole.teacher);
  }

  @override
  void dispose() {
    _customReasonCtrl.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() {
      _selected = index;
      _selectedOffice = index >= 0 ? AppSettings.offices[index] : '';
    });
  }

  String get _reasonText {
    final custom = _customReasonCtrl.text.trim();
    if (custom.isNotEmpty) return custom;
    if (_selectedReason != null && _selectedReason != 'Другое') return _selectedReason!;
    return '';
  }

  void _call() {
    setState(() => _selectedCallButton = 1);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _selectedCallButton = 0);
    });

    final office = _selectedOffice;
    final teacherName = '${AppSettings.lastName.value} ${AppSettings.firstName.value}'.trim();
    final reason = _reasonText;
    final callId = DateTime.now().millisecondsSinceEpoch.toString();

    if (office.isNotEmpty && teacherName.isNotEmpty) {
      CallManager.addCall(callId, office, teacherName, reason);
      P2PService().sendCall(office, reason, callId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Вызов из ауд. $office отправлен')),
      );
    }
  }

  void _showActiveCalls() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ValueListenableBuilder<List<CallRequest>>(
          valueListenable: CallManager.calls,
          builder: (context, calls, _) {
            if (calls.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Нет активных вызовов')),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final call = calls[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Ауд. ${call.office}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(width: 8),
                                  if (call.isAnswered)
                                    Text('(Принят: ${call.answeredBy})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Причина: ${call.reason.isEmpty ? "не указана" : call.reason}', maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('Время: ${call.time}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            CallManager.removeCall(call.id);
                            P2PService().cancelCall(call.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildToggleButton(int index) {
    final bool isSelected = _selected == index;
    return GestureDetector(
      onTap: () => isSelected ? _select(-1) : _select(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 50, height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          border: Border.all(color: Colors.deepPurple, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          AppSettings.offices[index],
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.deepPurple,
          ),
        ),
      ),
    );
  }


  Widget _buildToggleButtonDisable(int index) {
    final bool isSelected = _selected == index;
    return GestureDetector(
      onTap: null, // отключаем нажатие — кнопка недоступна
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 50, height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade400 : Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          AppSettings.offices[index],
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton() {
    final bool isSelected = _selectedCallButton == 1;
    return GestureDetector(
      onTap: _call,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 150, height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          border: Border.all(color: Colors.deepPurple, width: 2.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          "Быстрый вызов",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  // Кнопка для открытия списка вызовов
  Widget _buildCallsListButton() {
    return GestureDetector(
      onTap: _showActiveCalls,
      child: Container(
        width: 150,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.deepPurple, width: 2.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Text(
          "Мои вызовы",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildOfficeButton(String defaultText) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.defaultOffice,
      builder: (context, defaultOffice, _) {
        final displayText = _selectedOffice.isNotEmpty ? _selectedOffice : defaultOffice;
        return GestureDetector(
          onTap: () => widget.onGoToSettings?.call(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 150, height: 100,
            alignment: Alignment.lerp(Alignment.topCenter, null, 0.4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.deepPurple, width: 2.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              "Аудитория: $displayText",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReasonDropdown() {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.deepPurple, width: 2.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReason,
          isExpanded: true,
          hint: const Text('Причина', style: TextStyle(fontSize: 14, color: Colors.deepPurple)),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
          style: const TextStyle(fontSize: 14, color: Colors.deepPurple),
          items: _commonReasons.map((r) => DropdownMenuItem<String>(
            value: r, child: Text(r, overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (value) => setState(() => _selectedReason = value),
        ),
      ),
    );
  }

  Widget _buildCustomReasonField() {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: _customReasonCtrl,
        maxLines: 1,
        style: const TextStyle(fontSize: 14, color: Colors.deepPurple),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Своя причина',
          hintStyle: TextStyle(fontSize: 13, color: Colors.deepPurple.shade200),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2.5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stack = [];
    for (int i = 0; i < 5; i++) stack.add(Positioned(top: 40, left: 10 + 70.0 * i, child: _buildToggleButton(4 - i)));
    for (int i = 0; i < 10; i++) stack.add(Positioned(top: 100 + 55.0 * i, left: 290, child: _buildToggleButton(6 + i)));


    // Оставить все кабинеты доступными
    //for (int i = 0; i < 9; i++) stack.add(Positioned(top: 155 + 55.0 * i, left: 220, child: _buildToggleButton(24 - i)));

    // Оставить все кабинеты, некотоые заблокированы
    for (int i = 0; i < 5; i++) stack.add(Positioned(top: 375 + 55.0 * i, left: 220, child: _buildToggleButtonDisable(20 - i)));
    for (int i = 0; i < 4; i++) stack.add(Positioned(top: 155 + 55.0 * i, left: 220, child: _buildToggleButton(24 - i)));

    // Оставить только нужные кабинеты
    //stack.add(Positioned(top: 155, left: 220, child: _buildToggleButton(19)));
    //stack.add(Positioned(top: 155 + 75, left: 220, child: _buildToggleButton(18)));
    //stack.add(Positioned(top: 155 + 140, left: 220, child: _buildToggleButton(17)));
    //stack.add(Positioned(top: 155 + 220, left: 220, child: _buildToggleButton(16)));
    
    stack.add(Positioned(top: 100, left: 150, child: _buildToggleButton(5)));
    stack.add(Positioned(top: 430, left: 10, child: _buildOfficeButton("")));
    stack.add(Positioned(top: 200, left: 10, child: _buildReasonDropdown()));
    stack.add(Positioned(top: 285, left: 10, child: _buildCustomReasonField()));
    stack.add(Positioned(top: 480, left: 10, child: _buildCallButton()));
    
    // Добавляем кнопку "Мои вызовы" под кнопкой быстрого вызова (отступ 15 пикселей)
    stack.add(Positioned(top: 645, left: 10, child: _buildCallsListButton()));

    Container baseLayout = Container(
      width: 350, height: 740, color: Colors.transparent,
      child: Stack(children: stack),
    );

    return Scaffold(
      // Убрали AppBar с верхней надписью
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: baseLayout,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}