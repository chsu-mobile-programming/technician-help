import 'package:flutter/material.dart';
import '../models/app_settings.dart';

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
  String? _selectedOffice;

  void _select(int index) {
    setState(() {
      _selected = index;
      _selectedOffice = index >= 0 ? AppSettings.offices[index] : null;
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


  void _selectdCallButton() {
    setState(() {
      _selectedCallButton = 1;
    });

    // Возврат в исходное состояние через 200 мс
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
        _selectedCallButton = 0;
        });
      }
    });

    /// ToDo логика при нажатии
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
            fontWeight:FontWeight.bold,
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
        final displayText = _selectedOffice ?? defaultOffice;

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


    /// Добавление кнопки аудитории
    stack.add(
      Positioned(
        top: 430,
        left: 10,
        child: _buildOfficeButton(""),
      ),
    );

    /// Добавление кнопки вызова
    stack.add(
      Positioned(
        top: 480,
        left: 10,
        child: _buildCallButton(),
      ),
    );


    Container baseLayout = Container(
      width: 350,
      height: 680,
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