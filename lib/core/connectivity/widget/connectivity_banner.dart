import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/connectivity/controller/connection_status_controller.dart';
import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

enum _BannerMode { hidden, offline, backOnline }

/// Wraps the whole app to show a floating banner whenever the device goes
/// offline, and a brief confirmation once the connection returns, letting
/// the player know their scores will sync automatically.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivityBanner> createState() =>
      _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  _BannerMode _mode = _BannerMode.hidden;
  Timer? _autoHideTimer;

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _showBackOnlineThenHide() {
    setState(() => _mode = _BannerMode.backOnline);
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _mode = _BannerMode.hidden);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectionStatusControllerProvider, (previous, next) {
      if (next == ConnectionStatus.offline) {
        _autoHideTimer?.cancel();
        setState(() => _mode = _BannerMode.offline);
      } else if (previous == ConnectionStatus.offline &&
          next == ConnectionStatus.online) {
        _showBackOnlineThenHide();
      }
    });

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedSlide(
                offset: _mode == _BannerMode.hidden
                    ? const Offset(0, -2)
                    : Offset.zero,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _mode == _BannerMode.hidden ? 0 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: _BannerContent(mode: _mode),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.mode});

  final _BannerMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == _BannerMode.hidden) {
      return const SizedBox.shrink();
    }

    final isOffline = mode == _BannerMode.offline;
    final color = isOffline ? AppColors.error : AppColors.mintGreen;
    final onColor = isOffline ? AppColors.onError : AppColors.onMintGreen;
    final icon = isOffline
        ? Icons.cloud_off_rounded
        : Icons.cloud_done_rounded;
    final label = isOffline
        ? AppLocale.offlineBannerMessage.getString(context)
        : AppLocale.backOnlineBannerMessage.getString(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onColor, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
