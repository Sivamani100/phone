class ContactModel {
  final int? id;
  final String nativeId;
  final String name;
  final String phone;
  final String email;
  final bool isFavorite;

  // Rich metadata fields
  final List<Map<String, String>> phones; // Each contains 'number' and 'label'
  final List<Map<String, String>> emails; // Each contains 'address' and 'label'
  final String company;
  final String jobTitle;
  final String notes;
  final String address;

  ContactModel({
    this.id,
    this.nativeId = '',
    required this.name,
    required this.phone,
    required this.email,
    this.isFavorite = false,
    this.phones = const [],
    this.emails = const [],
    this.company = '',
    this.jobTitle = '',
    this.notes = '',
    this.address = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    final String p = map['phone'] ?? '';
    final String e = map['email'] ?? '';
    return ContactModel(
      id: map['id'],
      nativeId: (map['id'] ?? '').toString(),
      name: map['name'] ?? '',
      phone: p,
      email: e,
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      phones: p.isNotEmpty ? [{'number': p, 'label': 'Mobile'}] : [],
      emails: e.isNotEmpty ? [{'address': e, 'label': 'Home'}] : [],
    );
  }

  ContactModel copyWith({
    int? id,
    String? nativeId,
    String? name,
    String? phone,
    String? email,
    bool? isFavorite,
    List<Map<String, String>>? phones,
    List<Map<String, String>>? emails,
    String? company,
    String? jobTitle,
    String? notes,
    String? address,
  }) {
    return ContactModel(
      id: id ?? this.id,
      nativeId: nativeId ?? this.nativeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isFavorite: isFavorite ?? this.isFavorite,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      notes: notes ?? this.notes,
      address: address ?? this.address,
    );
  }
}

