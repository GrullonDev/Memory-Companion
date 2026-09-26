/// Selecciona la implementación de conexión según la plataforma de destino.
///
/// El resto del proyecto importa únicamente este archivo y nunca
/// `dart:io` ni `package:drift/native.dart` directamente, que es lo que
/// permite que `flutter build web` siga compilando.
library;

export 'native.dart' if (dart.library.js_interop) 'web.dart';
