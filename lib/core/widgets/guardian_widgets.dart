// Guardian Mobile — core widgets built on the tokens and motion helpers.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/guardian_motion.dart';
import '../theme/guardian_theme.dart';
import '../theme/guardian_tokens.dart';

// ───────────────────────────── Status badge ─────────────────────────────
enum GTone { ok, warn, danger, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = GTone.ok, this.live = false});
  final String label;
  final GTone tone;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final (bg, fg) = switch (tone) {
      GTone.ok => (c.brandSoft, c.brandInk),
      GTone.warn => (c.warningSoft, c.warningInk),
      GTone.danger => (c.dangerSoft, c.dangerInk),
      GTone.neutral => (c.surfaceSunken, c.inkMuted),
    };
    return AnimatedContainer(
      duration: GMotion.base,
      curve: GMotion.standard,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(GRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        PulsingDot(color: fg, live: live),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ───────────────────────────── Icon box ─────────────────────────────
class IconBox extends StatelessWidget {
  const IconBox(this.icon, {super.key, this.size = 44, this.danger = false, this.onFill = false});
  final IconData icon;
  final double size;
  final bool danger, onFill;

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final bg = onFill ? Colors.white.withValues(alpha: .18) : (danger ? c.dangerSoft : c.brandSoft);
    final fg = onFill ? (danger ? c.onDanger : c.onBrand) : (danger ? c.dangerInk : c.brandInk);
    return AnimatedContainer(
      duration: GMotion.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size > 48 ? GRadius.lg : GRadius.md)),
      child: Icon(icon, size: size * .5, color: fg),
    );
  }
}

// ───────────────────────────── Action tile ─────────────────────────────
/// Quick-action tile. If [runFor] is set, the tile turns active while the
/// remote command runs, shows a progress bar and animates its icon.
class ActionTile extends StatefulWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.runFor,
    this.danger = false,
    this.navigates = false,
  });

  final IconData icon;
  final String title, subtitle;

  /// Runs the action. Return `false` (e.g. the command failed or the user
  /// cancelled) to skip the "running" animation.
  final Future<bool> Function() onTap;
  final Duration? runFor;
  final bool danger, navigates;

  @override
  State<ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<ActionTile> with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(vsync: this);
  bool get _active => _run.isAnimating;

  Future<void> _handle() async {
    if (_active) {
      _run.stop();
      _run.value = 0;
      setState(() {});
      return;
    }
    final ok = await widget.onTap();
    final d = widget.runFor;
    if (!ok || d == null || !mounted) return;
    _run.duration = d;
    setState(() {});
    await _run.forward(from: 0).orCancel.catchError((_) {});
    if (mounted) setState(() => _run.value = 0);
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final active = _active;
    final fill = widget.danger ? c.danger : c.brand;
    final on = widget.danger ? c.onDanger : c.onBrand;

    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: Pressable(
        onTap: _handle,
        child: AnimatedContainer(
          duration: GMotion.base,
          curve: GMotion.standard,
          constraints: const BoxConstraints(minHeight: 132),
          decoration: BoxDecoration(
            color: active ? fill : c.surface,
            borderRadius: GRadius.rLg,
            border: Border.all(color: active ? fill : c.border),
            boxShadow: active
                ? [BoxShadow(color: fill.withValues(alpha: .45), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -10)]
                : [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.all(GSpace.s4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _AnimatedIcon(active: active, child: IconBox(widget.icon, danger: widget.danger, onFill: active)),
                  const Spacer(),
                  if (widget.navigates) Icon(Icons.chevron_right_rounded, color: active ? on : c.inkSubtle),
                ]),
                const SizedBox(height: GSpace.s5),
                Text(widget.title, style: context.text.titleMedium?.copyWith(color: active ? on : c.ink)),
                const SizedBox(height: 2),
                Text(widget.subtitle, style: context.text.bodyMedium?.copyWith(color: active ? on.withValues(alpha: .86) : c.inkMuted)),
              ]),
            ),
            if (widget.runFor != null)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: AnimatedBuilder(
                  animation: _run,
                  builder: (_, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _run.value,
                    child: Container(height: 3, color: on.withValues(alpha: .5)),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Rocks the icon while a command runs (bell swing).
class _AnimatedIcon extends StatefulWidget {
  const _AnimatedIcon({required this.active, required this.child});
  final bool active;
  final Widget child;
  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _a = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -.24), weight: 15),
    TweenSequenceItem(tween: Tween(begin: -.24, end: .2), weight: 15),
    TweenSequenceItem(tween: Tween(begin: .2, end: -.14), weight: 15),
    TweenSequenceItem(tween: Tween(begin: -.14, end: .08), weight: 15),
    TweenSequenceItem(tween: Tween(begin: .08, end: 0), weight: 40),
  ]).animate(_c);

  @override
  void didUpdateWidget(covariant _AnimatedIcon old) {
    super.didUpdateWidget(old);
    if (widget.active && !GMotion.reduced(context)) {
      _c.repeat();
    } else {
      _c.animateTo(0, duration: GMotion.fast);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _a, child: widget.child, builder: (_, child) => Transform.rotate(angle: _a.value, child: child));
}

// ───────────────────────────── Hold to confirm ─────────────────────────────
/// Destructive button that only fires after being held for [hold].
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({super.key, required this.label, required this.onConfirmed, this.hold = const Duration(milliseconds: 1600)});
  final String label;
  final VoidCallback onConfirmed;
  final Duration hold;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.hold)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
        _c.value = 0;
      }
    });

  void _down(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _c.forward();
  }

  void _up([Object? _]) {
    if (!_c.isCompleted) _c.animateBack(0, duration: GMotion.base, curve: GMotion.exit);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    return Semantics(
      button: true,
      label: '${widget.label}. Mantén presionado para confirmar',
      child: GestureDetector(
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _up,
        child: ClipRRect(
          borderRadius: GRadius.rMd,
          child: SizedBox(
            height: GSpace.s12,
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: c.danger),
              AnimatedBuilder(
                animation: _c,
                builder: (_, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _c.value,
                  child: ColoredBox(color: c.dangerPressed),
                ),
              ),
              Center(child: Text(widget.label, style: context.text.labelLarge?.copyWith(color: c.onDanger))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Shield banner ─────────────────────────────
class ShieldBanner extends StatelessWidget {
  const ShieldBanner({super.key, required this.devices, this.theftMode = false, this.title, this.subtitle});
  final int devices;
  final bool theftMode;

  /// The orb only pulses while something is actually being protected.
  bool get _live => devices > 0 || theftMode;

  /// Optional overrides (e.g. for localisation). Defaults are Spanish.
  final String? title, subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final bg = theftMode ? c.dangerSoft : c.brandSoft;
    final fg = theftMode ? c.dangerInk : c.brandInk;
    final orb = theftMode ? c.danger : c.brand;
    return AnimatedContainer(
      duration: GMotion.base,
      curve: GMotion.standard,
      padding: const EdgeInsets.symmetric(horizontal: GSpace.s5, vertical: GSpace.s4),
      decoration: BoxDecoration(color: bg, borderRadius: GRadius.rLg),
      child: Row(children: [
        Stack(alignment: Alignment.center, children: [
          PulsingDot(color: orb, size: 44, live: _live),
          AnimatedSwitcher(
            duration: GMotion.base,
            transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
            child: Icon(theftMode ? Icons.gpp_maybe_rounded : Icons.verified_user_rounded,
                key: ValueKey(theftMode), color: theftMode ? c.onDanger : c.onBrand, size: 22),
          ),
        ]),
        const SizedBox(width: GSpace.s4),
        Expanded(
          child: AnimatedSwitcher(
            duration: GMotion.base,
            child: Column(key: ValueKey(theftMode), crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title ?? (theftMode ? 'Modo Robo activo' : 'Escudo activo'), style: context.text.titleMedium),
              Text(subtitle ?? (theftMode ? 'Rastreo cada 30 s · pantalla bloqueada' : '$devices ${devices == 1 ? 'dispositivo' : 'dispositivos'} bajo vigilancia'),
                  style: context.text.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────────── Friendly errors ─────────────────────────────
/// Maps backend error codes to human text. NEVER show raw server messages.
String friendlyError(Object error) {
  final code = switch (error) {
    final Map m => m['code']?.toString(),
    _ => null,
  };
  return switch (code) {
    'INVALID_CREDENTIALS' => 'Correo o contraseña incorrectos.',
    'EMAIL_TAKEN' => 'Ya existe una cuenta con ese correo.',
    'RATE_LIMITED' => 'Demasiados intentos. Espera un minuto.',
    'DEVICE_OFFLINE' => 'El teléfono no está conectado. La orden se enviará cuando vuelva a estar en línea.',
    _ => 'Algo salió mal en el servidor. Inténtalo de nuevo en unos minutos.',
  };
}
