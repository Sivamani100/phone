import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

void main() {
  test('inspect flutter_contacts types', () {
    print('FLUTTER CONTACTS INSPECTION:');
    final phone = Phone('123456');
    print('Phone class exists, type of phone.label: ${phone.label.runtimeType}');
    // Print what enum values exist on PhoneLabel
    print('PhoneLabel values: ${PhoneLabel.values}');
    
    final email = Email('abc@gmail.com');
    print('Email class exists, type of email.label: ${email.label.runtimeType}');
    print('EmailLabel values: ${EmailLabel.values}');
  });
}
