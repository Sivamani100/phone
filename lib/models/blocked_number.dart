class BlockedNumber {
  final int? id;
  final String phone;
  final String name;

  BlockedNumber({
    this.id,
    required this.phone,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'phone': phone,
      'name': name,
    };
  }

  factory BlockedNumber.fromMap(Map<String, dynamic> map) {
    return BlockedNumber(
      id: map['id'],
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
