# Configuración de Firestore

## 1. Crear la Base de Datos en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto "Memory Companion"
3. En el menú izquierdo, ve a **Firestore Database**
4. Haz clic en **Create Database**
5. Selecciona tu región (recomendado: `us-central1` o la más cercana a Guatemala)
6. Elige **Start in test mode** (después cambiaremos a las reglas de seguridad)
7. Confirma y espera a que se cree la base de datos

## 2. Copiar las Reglas de Seguridad

1. En Firebase Console, ve a **Firestore Database** → **Rules**
2. Reemplaza el contenido con las reglas del archivo `firestore.rules`:

```firestore
rules_version = '3';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to authenticated users on their own data
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      allow read: if true;
    }

    match /users/{uid}/matches/{matchId} {
      allow read, write: if request.auth.uid == uid;
      allow read: if true;
    }

    match /users/{uid}/achievements/{achievementId} {
      allow read, write: if request.auth.uid == uid;
    }

    match /daily_challenges/{challengeId} {
      allow read: if true;
      allow write: if false;
    }

    match /leaderboards/{leaderboardId} {
      allow read: if true;
      allow write: if false;
    }

    match /user_index/{uid} {
      allow read: if true;
      allow write: if request.auth.uid == uid;
    }
  }
}
```

3. Haz clic en **Publish**

## 3. Estructura de la Base de Datos

La base de datos se estructura así:

```
Firestore/
├── users/
│   └── {uid}/
│       ├── email: string
│       ├── displayName: string
│       ├── level: number
│       ├── currentXp: number
│       ├── totalCoins: number
│       ├── gamesWon: number
│       ├── bestStreak: number
│       ├── rank: string
│       ├── avatarSeed: number
│       ├── createdAt: timestamp
│       ├── updatedAt: timestamp
│       └── matches/
│           └── {matchId}/
│               ├── gameMode: string (solo, versus, daily_challenge)
│               ├── score: number
│               ├── moves: number
│               ├── secondsElapsed: number
│               ├── timeLimit: number
│               ├── coinsEarned: number
│               ├── xpEarned: number
│               ├── won: boolean
│               └── playedAt: timestamp
├── daily_challenges/
│   └── {challengeId}/
│       ├── title: string
│       ├── description: string
│       ├── reward: number
│       └── endsAt: timestamp
└── leaderboards/
    └── {leaderboardId}/
        └── scores: array
```

## 4. Crear Índices (Opcional pero Recomendado)

Para mejorar el rendimiento, crea estos índices en Firestore:

### Índice 1: User Match History
- Collection: `users/{uid}/matches`
- Campos:
  - `playedAt` (Descending)

### Índice 2: User Wins
- Collection: `users/{uid}/matches`
- Campos:
  - `won` (Ascending)
  - `playedAt` (Descending)

### Índice 3: Matches by Game Mode
- Collection: `users/{uid}/matches`
- Campos:
  - `gameMode` (Ascending)
  - `playedAt` (Descending)

## 5. Exportar la Aplicación (IMPORTANTE)

Después de crear la base de datos:

1. En Firebase Console, ve a **Project Settings** (esquina superior derecha)
2. En la pestaña **General**, baja hasta **Your apps**
3. Busca tu app de Flutter y haz clic en el ícono de configuración
4. Selecciona **google-services.json** y descárgalo
5. Reemplaza el archivo en: `android/app/google-services.json`

## 6. Configuración en el Código

Todo ya está configurado en tu código Flutter:

- ✅ `FirebaseAuth` para autenticación
- ✅ `Cloud Firestore` para almacenamiento
- ✅ `UserRepository` para operaciones de usuario
- ✅ `MatchRepository` para historial de juegos
- ✅ `GameController` para lógica del juego
- ✅ Integración en `BoardController` para guardar resultados

## 7. Pruebas

Cuando ejecutes la app:

1. Registra un nuevo usuario
2. Juega una partida
3. Completa el juego
4. Ve a Firebase Console → Firestore → Collections
5. Deberías ver tu usuario y sus partidas guardadas

## Próximos Pasos

- [ ] Implementar leaderboards globales
- [ ] Agregar daily challenges
- [ ] Implementar sistema multiplayer
- [ ] Agregar notificaciones
- [ ] Crear funciones Cloud para procesar datos

## Troubleshooting

Si tienes errores de permisos:
- Verifica que tu usuario esté autenticado
- Comprueba que las reglas de Firestore estén correctamente publicadas
- Revisa la consola de Chrome DevTools (en web) o Logcat (en Android)

Si la app se conecta pero no guarda datos:
- Asegúrate de que `google-services.json` está actualizado
- Verifica que Firebase esté inicializado correctamente
- Revisa los logs en Firebase Console
