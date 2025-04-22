import 'package:flutter_test/flutter_test.dart';
import 'package:danentang/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FirebaseService', () {
    late FirebaseService firebaseService;

    setUp(() async {
      firebaseService = FirebaseService();
      await firebaseService.initialize();
    });

    test('initialize should set up database reference', () {
      expect(firebaseService.databaseReference, isNotNull);
    });

    test('setData should write data to database', () async {
      await firebaseService.setData('testPath', {'key': 'value'});
      final data = await firebaseService.getData('testPath');
      expect(data, equals({'key': 'value'}));
    });

    test('updateData should update existing data', () async {
      await firebaseService.setData('testPath', {'key': 'value'});
      await firebaseService.updateData('testPath', {'newKey': 'newValue'});
      final data = await firebaseService.getData('testPath');
      expect(data, equals({'key': 'value', 'newKey': 'newValue'}));
    });

    test('deleteData should remove data from database', () async {
      await firebaseService.setData('testPath', {'key': 'value'});
      await firebaseService.deleteData('testPath');
      final data = await firebaseService.getData('testPath');
      expect(data, isNull);
    });
  });
}