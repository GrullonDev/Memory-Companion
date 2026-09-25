# 🎨 Widget Template Guide — UI/UX Skill

> Referencia para el skill `uiux-skill`. Proporciona patrones de implementación para los tipos de widgets más comunes en Memory Arcade.

---

## Patrón: Carta de memoria mejorada

```dart
// Estructura para una carta con feedback visual mejorado
class EnhancedMemoryCard extends ConsumerWidget {
  final CardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ProfileTokens.of(context);
    final isVibrant = tokens.profile == VisualProfile.vibrant;

    return Pressable(
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      onTap: _handleTap,
      onLongPress: isVibrant ? _handleLongPress : null,
      scale: AppMotion.pressScale,
      depth: AppMotion.pressDepth,
      child: AnimatedContainer(
        duration: tokens.flipDuration,
        curve: AppMotion.press,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(
            color: state.isFaceUp ? tokens.cardFaceUpBorderColor : Colors.transparent,
            width: tokens.cardBorderWidth,
          ),
          color: state.isFaceUp ? Colors.white : tokens.cardFaceDownColor,
          // Glow cuando se revela (solo en vibrant)
          boxShadow: state.isFaceUp && isVibrant
              ? [
                  BoxShadow(
                    color: AppColors.sun.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: state.isFaceUp
            ? GameIcon(symbol: state.symbol, size: tokens.cardSymbolSize)
            : _buildCardBack(context, tokens),
      ),
    );
  }
}
```

## Patrón: Animación de coincidencia

```dart
// Cuando se encuentra una pareja
class MatchAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.celebrate,
      curve: AppMotion.press,
      builder: (context, t, child) {
        return Transform.scale(
          scale: 1 + (1 - t) * 0.3, // Explode outward
          child: Opacity(
            opacity: t,
            child: ConfettiOverlay(
              pieceCount: (28 * t).round(),
              colors: [AppColors.mint, AppColors.sun, AppColors.sky],
            ),
          ),
        );
      },
    );
  }
}
```

## Patrón: Shake en error

```dart
// Cuando se falla una pareja
class ErrorShake extends StatefulWidget {
  @override
  State<ErrorShake> createState() => _ErrorShakeState();
}

class _ErrorShakeState extends State<ErrorShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.instant * 3,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = math.sin(_animation.value * math.pi * 6) * 8;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: child,
    );
  }
}
```

## Patrón: Timer circular

```dart
// Barra de tiempo circular animada
class CircularTimer extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TimerPainter(progress: progress),
      child: SizedBox.square(
        dimension: 12, // Small indicator around the board
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track
    canvas.drawCircle(center, radius, Paint()..color = AppColors.disabled);

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      -math.pi * 2 * progress,
      false,
      Paint()..color = progress < 0.3 ? AppColors.streak : AppColors.sun,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

## Patrón: Streak badge animado

```dart
// Badge de racha con efecto de fuego
class StreakBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final tokens = ProfileTokens.of(context);

    return AnimatedContainer(
      duration: AppMotion.slow,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: streak >= 7
              ? [AppColors.streak, AppColors.streakDeep]
              : [AppColors.mint, AppColors.mintDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: streak >= 7
            ? [
                BoxShadow(
                  color: AppColors.streak.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: AppColors.onStreak, size: 16),
          SizedBox(width: 4),
          Text('$streak', style: TextStyle(color: AppColors.onStreak, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
```

## Patrón: Skeleton shimmer

```dart
// Placeholder con shimmer mientras cargan datos
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerHighest,
            AppColors.surfaceContainerLow,
            AppColors.surfaceContainerHighest,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
```

## Patrón: Onboarding overlay

```dart
// Overlay de tutorial paso a paso
class OnboardingOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget targetWidget; // Widget al que apunta
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrim semitransparente
        Container(color: ProfileTokens.of(context).scrimColor),

        // Target highlight
        Positioned(
          left: /* calcular desde targetWidget */,
          top: /* calcular desde targetWidget */,
          child: TargetHighlight(
            child: targetWidget,
            highlightColor: AppColors.sun,
          ),
        ),

        // Tooltip
        Positioned(
          bottom: 80,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMd),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppColors.onSurfaceVariant)),
                SizedBox(height: AppSpacing.lg),
                Pressable(
                  onTap: onNext,
                  child: Text(AppLocale.nextLabel.getString(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

## Patrón: Animación de progreso de nivel

```dart
// Barra de nivel con efecto líquido
class LevelProgressLiquid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(xpProvider);
    final nextLevelXp = ref.watch(nextLevelXpProvider);
    final progress = xp / nextLevelXp;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: AppMotion.slow,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return ClipPath(
          clipper: _WaveClipper(progress: t),
          child: AnimatedContainer(
            duration: AppMotion.slow,
            height: 14,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sun, AppColors.sunDeep],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        );
      },
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double progress;

  _WaveClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width * progress, 0);
    // Wave effect at the leading edge
    path.lineTo(size.width * progress + 10, size.height / 2);
    path.lineTo(size.width * progress, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
```

---

## Reglas de implementación

1. **Nunca usar `InkWell`** — siempre `Pressable`
2. **Nunca usar `Container` con `BoxDecoration` directamente en el juego** — usar `AppCard`
3. **Motion siempre en `transform` y `opacity`** — nunca `left`, `top`, `width`, `height` en animaciones
4. **Todos los colores** — desde `AppColors` o `ProfileTokens.of(context)`
5. **Todos los spacing** — desde `AppSpacing` (múltiplo de 4px)
6. **Todos los textos** — desde `AppLocale` para internacionalización
7. **Haptics** — siempre acompañar el feedback visual con `HapticFeedback` apropiado
8. **Accesibilidad** — verificar `MediaQuery.disableAnimationsOf(context)` antes de cualquier animación compleja
9. **Semantics** — cada widget interactivo necesita `Semantics` widget (Pressable ya lo incluye)
10. **Testing** — cada widget nuevo necesita al menos un `test` en `test/features/`

---

## Debugging de Motion

```dart
// Verificar que las animaciones funcionan en ambos perfiles
void debugMotion(BuildContext context) {
  final tokens = ProfileTokens.of(context);
  print('Profile: ${tokens.profile}');
  print('ReduceMotion: ${tokens.reduceMotion}');
  print('ButtonMinHeight: ${tokens.buttonMinHeight}');
  print('FlipDuration: ${tokens.flipDuration}');
}
```
