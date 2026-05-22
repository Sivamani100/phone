class CallLogModel {
  final int? id;
  final String name; // Holds name if resolved, or empty if unknown
  final String phone;
  final String type; // 'incoming', 'outgoing', 'missed'
  final DateTime timestamp;
  final int durationSeconds;

  CallLogModel({
    this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.timestamp,
    required this.durationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'duration_seconds': durationSeconds,
    };
  }

  factory CallLogModel.fromMap(Map<String, dynamic> map) {
    return CallLogModel(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] ?? 'outgoing',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      durationSeconds: map['duration_seconds'] ?? 0,
    );
  }
}
