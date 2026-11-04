// Guardian Mobile — reusable motion widgets. No extra packages needed.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/guardian_tokens.dart';

/// Scales its child to 0.97 while pressed and springs back on release.
/// Wrap any tappable card: `Pressable(onTap: …, child: Card(...))`.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.haptic = true});
  final Widget child;
  final VoidCallback? onTap, onLongPress;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: _down ? GMotion.instant : GMotion.slow,
        curve: _down ? GMotion.standard : GMotion.spring,
        child: widget.child,
      ),
    );
  }
}

/// Fades + rises a child into place after `index * stagger`.
/// Use for lists, grids and the sections of a screen on first build.
class StaggeredIn extends StatefulWidget {
  const StaggeredIn({super.key, required this.index, required this.child, this.offset = 12});
  final int index;
  final Widget child;
  final double offset;

  @override
  State<StaggeredIn> createState() => _StaggeredInState();
}

class _StaggeredInState extends State<StaggeredIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: GMotion.slow);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: GMotion.enter);

  Timer? _delay;

  @override
  void initState() {
    super.initState();
    final slot = widget.index.clamp(0, 8);
    if (slot == 0) {
      _c.forward();
    } else {
      // Cancellable (unlike Future.delayed) so nothing fires after dispose.
      _delay = Timer(GMotion.stagger * slot, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GMotion.reduced(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (_, child) => Opacity(
          opacity: _t.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _t.value) * widget.offset),
            child: Transform.scale(scale: 0.985 + 0.015 * _t.value, child: child),
          ),
        ),
      );
}

/// A dot that emits a soft expanding ring — the "live" indicator.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.color, this.size = 8, this.live = true});
  final Color color;
  final double size;
  final bool live;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: GMotion.pulse);

  void _sync() {
    final run = widget.live && !GMotion.reduced(context);
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run) {
      _c.stop();
      _c.value = 1; // ring fully faded: only the solid dot stays visible
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PulsingDot old) {
    super.didUpdateWidget(old);
    if (old.live != widget.live) _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox.square(
      dimension: s,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = Curves.easeOut.transform((_c.value / .8).clamp(0, 1));
            return Transform.scale(
              scale: 1 + 1.6 * t,
              child: Container(width: s, height: s, decoration: BoxDecoration(
                shape: BoxShape.circle, color: widget.color.withValues(alpha: .55 * (1 - t)))),
            );
          },
        ),
        Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
      ]),
    );
  }
}

/// Counts a number up from its previous value (battery %, distances).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.suffix = '', this.style});
  final int value;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.toDouble()),
        duration: GMotion.d(context, const Duration(milliseconds: 900)),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text('${v.round()}$suffix',
            style: (style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      );
}

/// Horizontal shake for invalid input. Call `key.currentState!.shake()`.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child});
  final Widget child;

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  void shake() {
    HapticFeedback.mediumImpact();
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final t = _c.value;
          final dx = 6 * (1 - t) * math.sin(t * 4 * math.pi);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
}
