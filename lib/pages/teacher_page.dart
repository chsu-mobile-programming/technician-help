import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/call_manager_service.dart';

/// Страница преподавателя
class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key, this.onGoToSettings});

  final VoidCallback? onGoToSettings;

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  int _selected = -1;
  int _selectedCallButton = 0;
  int _selectedCancelButton = 0;
  bool _isCancelEnabled = false;
  String _selectedOffice = AppSettings.defaultOffice.value;

  /// Частые причины вызова
  static const List<String> _commonReasons = [
    'Проектор не работает',
    'Нет интернета',
    'Не работает компьютер',
    'Проблема со звуком',
    'Не работает доска',
    'Другое',
  ];

  /// Выбранная частая причина (null — не выбрана)
  String? _selectedReason;

  /// Контроллер для собственной причины
  late final TextEditingController _customReasonCtrl;

  @override
  void initState() {
    super.initState();
    _customReasonCtrl = TextEditingController();
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

  Widget _buildToggleButton(int index) {
    final bool isSelected = _selected == index;

    return GestureDetector(
      onTap: () => isSelected ? _select(-1) : _select(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 50,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          border: Border.all(color: Colors.deepPurple, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          AppSettings.offices[index],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  /// Итоговая причина: собственная (если введена) или выбранная из списка
  String get _reasonText {
    final custom = _customReasonCtrl.text.trim();
    if (custom.isNotEmpty) return custom;
    if (_selectedReason != null && _selectedReason != 'Другое') {
      return _selectedReason!;
    }
    return '';
  }

  void _selectdCallButton() {
    setState(() {
      _selectedCallButton = 1;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _selectedCallButton = 0;
        });
      }
    });

    final office = _selectedOffice;
    final firstName = AppSettings.firstName.value;
    final lastName = AppSettings.lastName.value;
    final teacherName = '$lastName $firstName'.trim();
    final reason = _reasonText;

    if (office.isNotEmpty && teacherName.isNotEmpty) {
      // Передаём причину (см. правки CallManager ниже)
      CallManager.addCall(office, teacherName, reason);

      setState(() {
        _isCancelEnabled = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Вызов из ауд. $office отправлен')),
      );
    }
  }

  Widget _buildCallButton() {
    final bool isSelected = _selectedCallButton == 1;

    return GestureDetector(
      onTap: () => _selectdCallButton(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 150,
        height: 150,
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  void _selectdOfficeButton() {
    widget.onGoToSettings?.call();
  }

  Widget _buildOfficeButton(String defaultText) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.defaultOffice,
      builder: (context, defaultOffice, _) {
        final displayText = _selectedOffice.isNotEmpty ? _selectedOffice : defaultOffice;

        return GestureDetector(
          onTap: _selectdOfficeButton,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 150,
            height: 100,
            alignment: Alignment.lerp(Alignment.topCenter, null, 0.4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.deepPurple, width: 2.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              "Аудитория: $displayText",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.deepPurple,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Обработчик кнопки отмены
  void _cancelCall() {
    // Логика пока не реализована.
  }

  Widget _buildCancelButton() {
    final bool isSelected = _selectedCancelButton == 1 && _isCancelEnabled;
    final bool enabled = _isCancelEnabled;

    final Color borderColor = enabled ? Colors.deepPurple : Colors.grey;
    final Color textColor = enabled
        ? (isSelected ? Colors.white : Colors.deepPurple)
        : Colors.grey;
    final Color fillColor = isSelected ? Colors.deepPurple : Colors.white;

    return GestureDetector(
      onTap: enabled ? () => _cancelCall() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 150,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor, width: 2.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          "Отмена",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// Выпадающий список частых причин
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
          hint: const Text(
            'Причина',
            style: TextStyle(fontSize: 14, color: Colors.deepPurple),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
          style: const TextStyle(fontSize: 14, color: Colors.deepPurple),
          items: _commonReasons
              .map((r) => DropdownMenuItem<String>(
                    value: r,
                    child: Text(r, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
            });
          },
        ),
      ),
    );
  }

  /// Поле для собственной причины
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

    for (int i = 0; i < 5; i++) {
      stack.add(
        Positioned(
          top: 40,
          left: 10 + 70.0 * i,
          child: _buildToggleButton(4 - i),
        ),
      );
    }

    for (int i = 0; i < 10; i++) {
      stack.add(
        Positioned(
          top: 100 + 55.0 * i,
          left: 290,
          child: _buildToggleButton(6 + i),
        ),
      );
    }

    for (int i = 0; i < 9; i++) {
      stack.add(
        Positioned(
          top: 155 + 55.0 * i,
          left: 220,
          child: _buildToggleButton(24 - i),
        ),
      );
    }

    stack.add(
      Positioned(
        top: 100,
        left: 150,
        child: _buildToggleButton(5),
      ),
    );

    /// Кнопка аудитории
    stack.add(
      Positioned(
        top: 430,
        left: 10,
        child: _buildOfficeButton(""),
      ),
    );

    /// Выпадающий список причин
    stack.add(
      Positioned(
        top: 200,
        left: 10,
        child: _buildReasonDropdown(),
      ),
    );

    /// Поле собственной причины
    stack.add(
      Positioned(
        top: 285,
        left: 10,
        child: _buildCustomReasonField(),
      ),
    );

    /// Кнопка вызова
    stack.add(
      Positioned(
        top: 480,
        left: 10,
        child: _buildCallButton(),
      ),
    );

    /// Кнопка отмены
    stack.add(
      Positioned(
        top: 650,
        left: 10,
        child: _buildCancelButton(),
      ),
    );

    Container baseLayout = Container(
      width: 350,
      height: 740,
      color: Colors.transparent,
      child: Stack(children: stack),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
    );
  }
}