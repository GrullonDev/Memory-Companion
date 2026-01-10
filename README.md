# 🧠 Memory Companion

> "La extensión de tu memoria, impulsada por micro-contextos."

**Memory Companion** es una aplicación diseñada para capturar esos pequeños pero cruciales momentos del día a día que nuestra memoria a menudo deja escapar. Mediante el uso de inteligencia artificial y contexto automático, permite registrar y recuperar información vital sin fricciones.

---

## ✨ Características Principales

- **Grabación Instantánea (Voz a Texto):** Registra pensamientos, decisiones o eventos en solo 5-10 segundos.
- **Contexto Automático Inteligente:** Cada nota guarda automáticamente:
  - 📍 **Ubicación exacta.**
  - 🕒 **Hora y fecha.**
  - 👥 **Personas cercanas** (vía escaneo Bluetooth).
- **Búsqueda Semántica Natural:** Olvida las etiquetas. Haz preguntas como: _"¿Dónde dejé las llaves el viernes?"_ o _"¿Por qué decidí cancelar la suscripción de X?"_.
- **Local-First:** Privacidad total. Tus datos se procesan y almacenan localmente primero, con sincronización opcional segura.

---

## 🏗️ Arquitectura del Proyecto

El proyecto sigue una arquitectura limpia (Clean Architecture) para asegurar la escalabilidad y mantenibilidad:

- **Data Layer:** Manejo de Isar (Base de datos local), GPS y Bluetooth.
- **Domain Layer:** Lógica de negocio, entidades de "Micro-contexto" y casos de uso.
- **Presentation Layer:** UI fluida en Flutter con gestión de estado escalable.

---

## 🛠️ Stack Tecnológico

El proyecto está construido con un stack moderno enfocado en rendimiento y privacidad:

- **Framework:** [Flutter](https://flutter.dev/) (Cross-platform)
- **Procesamiento de Voz:** [Speech-to-Text](https://pub.dev/packages/speech_to_text) para transcripción en tiempo real.
- **IA y Búsqueda:**
  - [LangChain.dart](https://github.com/davidmigloz/langchain_dart) para orquestación de LLMs.
  - Embeddings locales para búsqueda semántica.
- **Almacenamiento:** [Isar](https://isar.dev/) (Base de datos NoSQL ultra rápida y local-first).
- **Contexto:**
  - `geolocator` para ubicación.
  - `flutter_blue_plus` para detección de dispositivos cercanos.

---

## 🚀 Configuración Inicial

Sigue estos pasos para poner en marcha el proyecto en tu entorno local.

### Requisitos Previos

- Flutter SDK (versión estable más reciente)
- Dart SDK
- Android Studio / Xcode (para emuladores y dependencias nativas)

### 1. Clonar el repositorio

```bash
git clone https://github.com/GrullonDev/Memory-Companion.git
cd memory_companion
```

### 2. Instalación de Dependencias

Ejecuta el siguiente comando para descargar todos los paquetes necesarios:

```bash
flutter pub get
```

### 3. Configuración de Permisos

Asegúrate de configurar los permisos necesarios en las plataformas nativas:

#### Android (`AndroidManifest.xml`)

- `RECORD_AUDIO`
- `ACCESS_FINE_LOCATION`
- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`

#### iOS (`Info.plist`)

- `NSSpeechRecognitionUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSBluetoothAlwaysUsageDescription`

### 4. Ejecutar la Aplicación

```bash
flutter run
```

---

## 🧭 Roadmap y Próximos Pasos

- [ ] Implementación de motor de Embeddings offline.
- [ ] Refinamiento del escaneo de proximidad por Bluetooth.
- [ ] Dashboard de visualización de momentos por mapa.
- [ ] Sincronización en la nube cifrada de extremo a extremo (E2EE).

---

## 🤝 Contribuir

Si tienes ideas para mejorar la retención de micro-contextos, las Pull Requests son bienvenidas. Para cambios mayores, por favor abre un issue primero para discutir lo que te gustaría cambiar.

---

_Desarrollado con ❤️ para ayudar al cerebro humano._
