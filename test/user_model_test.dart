import 'package:flutter_test/flutter_test.dart';
import 'package:catchybus/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel parsing tests', () {
    test('UserModel.fromJson parses status field correctly', () {
      final json = {
        'id': 'test-student-id',
        'name': 'John Doe',
        'email': 'john@example.com',
        'status': 'INACTIVE',
        'phone': '1234567890',
        'type': 'student',
        'college': 'Engineering College',
        'busNumber': 'BUS-001',
        'isMultiAccount': false,
        'accounts': []
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'test-student-id');
      expect(model.name, 'John Doe');
      expect(model.status, 'INACTIVE');
    });

    test('UserModel.toEntity preserves the status field', () {
      const model = UserModel(
        id: 'test-student-id',
        name: 'John Doe',
        email: 'john@example.com',
        status: 'INACTIVE',
        phone: '1234567890',
        type: 'student',
        college: 'Engineering College',
        busNumber: 'BUS-001',
        isMultiAccount: false,
        accounts: [],
      );

      final entity = model.toEntity();

      expect(entity.id, 'test-student-id');
      expect(entity.name, 'John Doe');
      expect(entity.status, 'INACTIVE');
    });
  });
}
