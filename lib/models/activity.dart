class Activity {
  final int id;
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? regStart;
  final DateTime? regEnd;
  final int? capacity;
  final String? status;
  final int? createdBy;
  final String? location;

  Activity({
    required this.id,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.regStart,
    this.regEnd,
    this.capacity,
    this.status,
    this.createdBy,
    this.location,
  });

  factory Activity.fromJson(Map<String, dynamic> j) {
    DateTime? _dt(dynamic v) => (v == null || (v is String && v.trim().isEmpty))
        ? null
        : DateTime.tryParse(v.toString());

    return Activity(
      id: j['id'] as int,
      title: j['title'] ?? '',
      description: j['description'],
      startTime: _dt(j['start_time']),
      endTime: _dt(j['end_time']),
      regStart: _dt(j['reg_start']),
      regEnd: _dt(j['reg_end']),
      capacity: j['capacity'],
      status: j['status'],
      createdBy: j['created_by'],
      location: j['location'],
    );
  }
}
