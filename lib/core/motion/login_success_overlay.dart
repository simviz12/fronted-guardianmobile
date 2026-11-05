// Full-screen "access granted" animation shown right after a successful
// sign-in. It lives in the root Overlay (above the Navigator), so it keeps
// playing while the router swaps the login page for the dashboard, then fades
// out to reveal it.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/guardian_theme.dart';
import '../theme/guardian_tokens.dart';

/// Plays the sign-in success animation on [overlay].
///
/// Capture the overlay *before* awaiting the login call
/// (`Overlay.of(context, rootOverlay: true)`), since the login page may be
/// gone by the time the call returns.
void showLoginSuccess(OverlayState overlay, {String? name, bool isEn = false}) {
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _LoginSuccess(
      name: name,
      isEn: isEn,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _LoginSuccess extends StatefulWidget {
  const _LoginSuccess({required this.name, required this.isEn, required this.onDone});
  final String? name;
  final bool isEn;
  final VoidCallback onDone;

  @override
  State<_LoginSuccess> createState() => _LoginSuccessState();
}

class _LoginSuccessState extends State<_LoginSuccess> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  // Timeline (fractions of the full duration).
  late final _fadeIn = _curve(0.00, 0.12, Curves.easeOut);
  late final _shield = _curve(0.05, 0.40, GMotion.spring);
  late final _ring = _curve(0.18, 0.62, Curves.easeOutCubic);
  late final _check = _curve(0.30, 0.50, GMotion.standard);
  late final _text = _curve(0.38, 0.60, GMotion.enter);
  late final _fadeOut = _curve(0.82, 1.00, GMotion.exit);

  Animation<double> _curve(double a, double b, Curve curve) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.duration != null) return;
    final reduced = GMotion.reduced(context);
    _c.duration = Duration(milliseconds: reduced ? 700 : 1900);
    HapticFeedback.mediumImpact();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final first = widget.name?.trim().split(' ').first;
    final hello = first != null && first.isNotEmpty
        ? (widget.isEn ? 'Welcome, $first' : 'Bienvenido, $first')
        : (widget.isEn ? 'Welcome back' : 'Bienvenido de nuevo');

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final opacity = (_fadeIn.value * (1 - _fadeOut.value)).clamp(0.0, 1.0);
          return IgnorePointer(
            ignoring: _fadeOut.value > 0,
            child: Opacity(
              opacity: opacity,
              child: ColoredBox(
                color: c.bg,
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox.square(
                      dimension: 180,
                      child: Stack(alignment: Alignment.center, children: [
                        // Expanding ring
                        Transform.scale(
                          scale: 0.6 + 0.9 * _ring.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c.brand.withValues(alpha: (1 - _ring.value) * .6),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                        // Soft halo
                        Transform.scale(
                          scale: _shield.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: c.brandSoft),
                          ),
                        ),
                        // Shield badge: lock → verified shield
                        Transform.scale(
                          scale: _shield.value,
                          child: Transform.rotate(
                            angle: (1 - _shield.value) * -math.pi / 8,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: c.brand,
                                borderRadius: BorderRadius.circular(GRadius.xl),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.brand.withValues(alpha: .45),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                    spreadRadius: -8,
                                  ),
                                ],
                              ),
                              // Lock morphs into a verified shield, driven by the
                              // main timeline so it never lags behind the text.
                              child: Stack(alignment: Alignment.center, children: [
                                Opacity(
                                  opacity: 1 - _check.value,
                                  child: Transform.scale(
                                    scale: 1 - .5 * _check.value,
                                    child: Icon(Icons.lock_rounded, color: c.onBrand, size: 42),
                                  ),
                                ),
                                Opacity(
                                  opacity: _check.value,
                                  child: Transform.scale(
                                    scale: .5 + .5 * GMotion.spring.transform(_check.value),
                                    child: Icon(Icons.verified_user_rounded, color: c.onBrand, size: 42),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: GSpace.s6),
                    Opacity(
                      opacity: _text.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - _text.value) * 14),
                        child: Column(children: [
                          Text(widget.isEn ? 'Access granted' : 'Acceso concedido',
                              style: context.text.headlineSmall),
                          const SizedBox(height: GSpace.s1),
                          Text(hello, style: context.text.bodyLarge?.copyWith(color: c.brandInk)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
