import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/firebase/firestore_database.dart';

void main() {
  test('los tests (debug) usan la base de datos de desarrollo', () {
    expect(firestoreDatabaseId, defaultDatabaseId);
  });

  test('producción es la base de datos creada en la consola', () {
    expect(productionDatabaseId, 'produccion');
  });
}
