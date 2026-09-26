# 🔥 Comandos de Firebase - Guía Rápida

## ⚡ OPCIÓN 1: Script Automatizado (RECOMENDADO)

Si tienes macOS/Linux, ejecuta este comando:

```bash
cd ~/Volumes/WorkDiskDev/DevTools/flutter_projects/Memory-Companion
chmod +x firebase_setup.sh
./firebase_setup.sh
```

El script hará todo automáticamente:
- ✅ Verifica Firebase CLI
- ✅ Te autentica
- ✅ Crea los índices
- ✅ Verifica la conexión

---

## 📝 OPCIÓN 2: Comandos Manuales

Si prefieres ejecutar paso a paso o estás en Windows:

### Paso 1: Instalar Firebase CLI

**macOS/Linux:**
```bash
npm install -g firebase-tools
```

**Windows (PowerShell como Admin):**
```powershell
npm install -g firebase-tools
```

Verifica la instalación:
```bash
firebase --version
```

---

### Paso 2: Autenticarte con Firebase

```bash
firebase login
```

Esto abrirá una ventana del navegador para que inicies sesión con tu cuenta de Google/Firebase.

---

### Paso 3: Listar tus proyectos

```bash
firebase projects:list
```

Busca tu proyecto "Memory Companion" en la lista y copia su ID (ejemplo: `memory-companion-abc123`)

---

### Paso 4: Crear los Índices

Reemplaza `YOUR_PROJECT_ID` con el ID de tu proyecto:

```bash
cd ~/Volumes/WorkDiskDev/DevTools/flutter_projects/Memory-Companion

firebase deploy --only firestore:indexes --project=YOUR_PROJECT_ID
```

**Ejemplo completo:**
```bash
firebase deploy --only firestore:indexes --project=memory-companion-7a8b9c
```

---

### Paso 5: Verificar que los índices se crearon

```bash
firebase firestore:indexes --project=YOUR_PROJECT_ID
```

Deberías ver 3 índices:
```
✔ Collection group "matches" has index with fields: playedAt (Descending)
✔ Collection group "matches" has index with fields: won (Ascending), playedAt (Descending)  
✔ Collection group "matches" has index with fields: gameMode (Ascending), playedAt (Descending)
```

---

## 🎮 Paso 6: Preparar la App

Una vez creados los índices:

```bash
cd ~/Volumes/WorkDiskDev/DevTools/flutter_projects/Memory-Companion

# Descargar dependencias
flutter pub get

# Limpiar cualquier build anterior
flutter clean

# Ejecutar la app
fvm flutter run
```

---

## ✅ Paso 7: Probar la Conexión

1. **Cuando la app inicie:**
   - Registra un nuevo usuario (email + password)
   - Verifica que se guarde en Firestore

2. **Juega una partida:**
   - Completa un juego
   - Verifica que se guarde el resultado

3. **Ve a Firebase Console:**
   - https://console.firebase.google.com/
   - Selecciona tu proyecto
   - Ve a Firestore Database
   - Expande "users" → tu UID
   - Deberías ver:
     - Tu email
     - Tu nivel
     - Tu historial de matches

---

## 🔧 Troubleshooting

### Error: "firebase command not found"

**Solución:**
```bash
# Reinstalar Firebase CLI
npm uninstall -g firebase-tools
npm install -g firebase-tools

# Verifica la instalación
firebase --version
```

---

### Error: "Authentication failed"

**Solución:**
```bash
# Cerrar sesión y reintentar
firebase logout
firebase login
```

---

### Error: "Project not found"

**Solución:**
- Verifica que el proyecto ID es correcto
- Copia exactamente del listado de `firebase projects:list`
- No uses espacios adicionales

---

### Los índices tardan en crearse

**Esto es normal:** Los índices de Firestore pueden tardar 5-15 minutos en crearse, especialmente la primera vez. 

Verifica el estado en Firebase Console:
1. Ve a Firestore Database
2. Click en la pestaña "Indexes"
3. Espera a que el estado cambie de "Creating" a "Enabled"

---

### La app no puede conectar a Firestore

**Checklist:**
- [ ] ¿Descargaste el `google-services.json` actualizado?
- [ ] ¿Lo copiaste a `android/app/google-services.json`?
- [ ] ¿Ejecutaste `flutter pub get` después?
- [ ] ¿Las reglas de Firestore están publicadas?
- [ ] ¿Estás autenticado en la app?

---

## 🚀 Próximos Pasos Después de Conectar

Una vez que todo funcione:

1. **Implementar Leaderboards**
   ```bash
   # Archivos a crear:
   # lib/features/leaderboard/
   #   ├── model/leaderboard_entry.dart
   #   ├── repository/leaderboard_repository.dart
   #   └── controller/leaderboard_controller.dart
   ```

2. **Agregar Daily Challenges**
   ```bash
   # lib/features/challenges/
   #   ├── model/daily_challenge.dart
   #   ├── repository/challenge_repository.dart
   #   └── controller/challenge_controller.dart
   ```

3. **Implementar Multiplayer**
   ```bash
   # lib/features/multiplayer/
   #   ├── model/multiplayer_match.dart
   #   ├── repository/multiplayer_repository.dart
   #   └── controller/multiplayer_controller.dart
   ```

---

## 📚 Documentación Útil

- [Firebase CLI Docs](https://firebase.google.com/docs/cli)
- [Firestore Indexes](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firebase Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Flutter Firebase](https://firebase.flutter.dev/)

---

## ⏱️ Tiempo Estimado

- Instalar Firebase CLI: 2 minutos
- Autenticarse: 1 minuto
- Crear índices: 10-15 minutos (automático, espera en background)
- Preparar app: 5 minutos
- **Total: 20-25 minutos**

---

¡Cualquier problema, ejecuta los comandos de troubleshooting! 🎯
