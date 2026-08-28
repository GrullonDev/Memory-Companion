/// Localization keys and translation maps for the app.
///
/// Use `AppLocale.someKey.getString(context)` to resolve the current
/// language's value at runtime.
mixin AppLocale {
  static const String appTitle = 'appTitle';
  static const String homeGreeting = 'homeGreeting';
  static const String bannerEyebrow = 'bannerEyebrow';
  static const String bannerHeadline = 'bannerHeadline';
  static const String startGame = 'startGame';
  static const String chipArcade = 'chipArcade';
  static const String chipAchievements = 'chipAchievements';
  static const String chipDailyRewards = 'chipDailyRewards';
  static const String chipSettings = 'chipSettings';
  static const String modePlaySolo = 'modePlaySolo';
  static const String modeMultiplayer = 'modeMultiplayer';
  static const String modeDailyChallenge = 'modeDailyChallenge';
  static const String modeShop = 'modeShop';
  static const String badgePro = 'badgePro';
  static const String chooseMode = 'chooseMode';
  static const String recentMatches = 'recentMatches';
  static const String scoreLabel = 'scoreLabel';
  static const String sampleMatchTitle = 'sampleMatchTitle';
  static const String sampleMatchTimeAgo = 'sampleMatchTimeAgo';
  static const String movesLabel = 'movesLabel';
  static const String pausedTitle = 'pausedTitle';
  static const String pausedSubtitle = 'pausedSubtitle';
  static const String resumeGame = 'resumeGame';
  static const String completedTitle = 'completedTitle';
  static const String completedSubtitle = 'completedSubtitle';
  static const String playAgain = 'playAgain';
  static const String backToHome = 'backToHome';

  static const Map<String, dynamic> es = {
    appTitle: 'Memory Arcade',
    homeGreeting: '¡Hola de nuevo!',
    bannerEyebrow: 'Reto del día listo',
    bannerHeadline: 'Entrena tu memoria hoy',
    startGame: 'COMENZAR A JUGAR',
    chipArcade: 'Arcade',
    chipAchievements: 'Logros',
    chipDailyRewards: 'Regalo diario',
    chipSettings: 'Ajustes',
    modePlaySolo: 'Jugar Solo',
    modeMultiplayer: 'Multijugador',
    modeDailyChallenge: 'Reto Diario',
    modeShop: 'Tienda',
    badgePro: 'Pro',
    chooseMode: 'Elige un modo',
    recentMatches: 'Partidas recientes',
    scoreLabel: 'Puntaje',
    sampleMatchTitle: 'Venciste a "Memory Master"',
    sampleMatchTimeAgo: 'Hace 2h',
    movesLabel: 'Movimientos',
    pausedTitle: 'Juego en pausa',
    pausedSubtitle: 'Toca continuar cuando estés listo',
    resumeGame: 'CONTINUAR',
    completedTitle: '¡Lo lograste!',
    completedSubtitle: 'Encontraste todas las parejas',
    playAgain: 'JUGAR DE NUEVO',
    backToHome: 'Volver al inicio',
  };

  static const Map<String, dynamic> en = {
    appTitle: 'Memory Arcade',
    homeGreeting: 'Welcome back!',
    bannerEyebrow: "Today's challenge is ready",
    bannerHeadline: 'Train your memory today',
    startGame: 'START GAME',
    chipArcade: 'Arcade',
    chipAchievements: 'Achievements',
    chipDailyRewards: 'Daily Gift',
    chipSettings: 'Settings',
    modePlaySolo: 'Play Solo',
    modeMultiplayer: 'Multiplayer',
    modeDailyChallenge: 'Daily Challenge',
    modeShop: 'Shop',
    badgePro: 'Pro',
    chooseMode: 'Choose a mode',
    recentMatches: 'Recent Matches',
    scoreLabel: 'Score',
    sampleMatchTitle: "Beat 'Memory Master'",
    sampleMatchTimeAgo: '2h ago',
    movesLabel: 'Moves',
    pausedTitle: 'Game paused',
    pausedSubtitle: 'Tap resume whenever you are ready',
    resumeGame: 'RESUME',
    completedTitle: 'You did it!',
    completedSubtitle: 'You found every pair',
    playAgain: 'PLAY AGAIN',
    backToHome: 'Back to home',
  };
}
