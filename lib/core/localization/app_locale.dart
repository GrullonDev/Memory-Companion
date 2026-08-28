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
  };
}
