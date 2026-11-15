class HistoryCall {
  final String id;
  final String office;
  final String time;
  final String teacherName;
  final String reason;
  final String status; // 'Завершен' или 'Отменен преподавателем'

  HistoryCall({
    required this.id,
    required this.office,
    required this.time,
    required this.teacherName,
    required this.reason,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'office': office,
    'time': time,
    'teacherName': teacherName,
    'reason': reason,
    'status': status,
  };

  factory HistoryCall.fromJson(Map<String, dynamic> json) {
    return HistoryCall(
      id: json['id'] ?? '',
      office: json['office'] ?? '',
      time: json['time'] ?? '',
      teacherName: json['teacherName'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
    );
  }
}