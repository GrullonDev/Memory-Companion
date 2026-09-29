import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Base de datos de Firestore que usa la app.
///
/// El proyecto `memory-compaknion` tiene dos: `(default)` para desarrollo y
/// `produccion` para la app publicada. Un build de release apunta a
/// producción; debug y profile, a desarrollo. Para forzar otra al compilar:
///
/// ```bash
/// flutter run --dart-define=FIRESTORE_DATABASE=produccion
/// flutter build apk --dart-define=FIRESTORE_DATABASE='(default)'
/// ```
const String firestoreDatabaseId = String.fromEnvironment(
  'FIRESTORE_DATABASE',
  defaultValue: kReleaseMode ? productionDatabaseId : defaultDatabaseId,
);

const String productionDatabaseId = 'produccion';
const String defaultDatabaseId = '(default)';

/// La instancia de Firestore de [firestoreDatabaseId]. Firebase tiene que
/// estar inicializado.
FirebaseFirestore appFirestore() => firestoreDatabaseId == defaultDatabaseId
    ? FirebaseFirestore.instance
    : FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: firestoreDatabaseId,
      );
