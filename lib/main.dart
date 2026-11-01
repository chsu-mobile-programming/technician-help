import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Техник, помоги',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

/// Главный экран
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    TeacherPage(),
    TechnicianPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Преподаватель',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Техник',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}

/// Страница преподавателя
class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  int _selected = -1;

  final List<String> _options = [
    '201', '202', '203', '204', '205', // 0-4
    '212', '213', '214', '215', '216', '217', '218', '218а', '219', '220', '221', // 5-15
    '222', '223', '224', '225', '226', '227', '228', '229', '230' // 16-24
  ];

  void _select(int index) {
    setState(() {
      _selected = index;
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
          _options[index],
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

/// Страница техника
class TechnicianPage extends StatefulWidget {
  const TechnicianPage({super.key});

  @override
  State<TechnicianPage> createState() => _TechnicianPageState();
}

class _TechnicianPageState extends State<TechnicianPage> {
  @override
  Widget build(BuildContext context) {
    return const Center();
  }
}

/// Страница настроек
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return const Center();
  }
}