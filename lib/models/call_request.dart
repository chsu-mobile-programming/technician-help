class CallRequest {
  final String office;
  final String time;
  final String teacherName;
  final String reason;

  CallRequest({
    required this.office,
    required this.time,
    required this.teacherName,
    this.reason = '',
  });

  /// «Фамилия И.» — фамилия полностью, имя сокращено до первой буквы.
  /// Если в строке только одно слово — возвращаем его как есть.
  String get shortTeacherName {
    final parts = teacherName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return teacherName;
    final lastName = parts.first;
    final firstName = parts[1];
    if (firstName.isEmpty) return lastName;
    return '$lastName ${firstName[0]}.';
  }
}