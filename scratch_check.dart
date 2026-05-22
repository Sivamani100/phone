import 'package:flutter_contacts/flutter_contacts.dart';

void main() {
  print('Phone fields:');
  final phone = Phone('');
  print('phone.label: ${phone.label.runtimeType}');
  // We can compile this using dart to see if it has compile errors
}
