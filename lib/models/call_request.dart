class CallRequest {
  final String id;
  final String office;
  final String time;
  final String teacherName;
  final String reason;
  final String endpointId; // ID преподавателя в P2P (для ответа)
  final bool isAnswered;   // Флаг: техник принял вызов
  final String answeredBy; // Имя техника, который принял вызов

  CallRequest({
    required this.id,
    required this.office,
    required this.time,
    required this.teacherName,
    this.reason = '',
    this.endpointId = '',
    this.isAnswered = false,
    this.answeredBy = '',
  });

  String get shortTeacherName {
    final parts = teacherName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return teacherName;
    final lastName = parts.first;
    final firstName = parts[1];
    if (firstName.isEmpty) return lastName;
    return '$lastName ${firstName[0]}.';
  }

  CallRequest copyWith({bool? isAnswered, String? answeredBy}) {
    return CallRequest(
      id: id,
      office: office,
      time: time,
      teacherName: teacherName,
      reason: reason,
      endpointId: endpointId,
      isAnswered: isAnswered ?? this.isAnswered,
      answeredBy: answeredBy ?? this.answeredBy,
    );
  }
}