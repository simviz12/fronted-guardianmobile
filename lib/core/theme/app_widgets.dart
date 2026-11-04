import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/guardian_motion.dart';
import '../theme/app_spacing.dart';
import '../widgets/guardian_widgets.dart';
import 'guardian_theme.dart';
import 'guardian_tokens.dart';

// Shared widgets used across every screen. Public API is unchanged; the
// visuals and motion now come from the Guardian Mobile design system
// (guardian_tokens / guardian_motion / guardian_widgets).

/// Scales its child down slightly while pressed and springs back on release.
class PressableScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: GMotion.d(context, _pressed ? GMotion.instant : GMotion.slow),
        curve: _pressed ? GMotion.standard : GMotion.spring,
        child: widget.child,
      ),
    );
  }
}

/// Design-system card. Fades and rises in on first build; tappable cards
/// press-scale with a spring and paint their ripple on top.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;

  /// Entrance animation delay slot (0 = immediately). Pass the item index in
  /// lists for a staggered entrance.
  final int enterIndex;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
    this.onTap,
    this.enterIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = GRadius.rLg;

    final decoration = BoxDecoration(
      color: backgroundColor ?? c.surface,
      borderRadius: radius,
      border: border ?? Border.all(color: c.border),
      boxShadow: isDark
          ? const []
          : [
              BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 2, offset: const Offset(0, 1)),
            ],
    );

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(GSpace.s4),
      child: child,
    );

    final Widget card;
    if (onTap == null) {
      // Transparent Material above the decoration so ListTiles/Switches inside
      // the card paint their ink splashes on top instead of behind it.
      card = DecoratedBox(
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      );
    } else {
      card = PressableScale(
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: decoration,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap!();
              },
              borderRadius: radius,
              child: content,
            ),
          ),
        ),
      );
    }

    return StaggeredIn(index: enterIndex, child: card);
  }
}

class _ButtonContent extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool isLoading;
  final Color color;

  const _ButtonContent({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: GMotion.d(context, GMotion.fast),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: .85, end: 1.0).animate(a), child: child),
      ),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: GSpace.s2),
                ],
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(fontSize: 15, color: color),
                  ),
                ),
              ],
            ),
    );
  }
}

class _GButton extends StatelessWidget {
  const _GButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.haptic,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color bg, fg;
  final VoidCallback haptic;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;
    return PressableScale(
      enabled: enabled,
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: enabled
              ? () {
                  haptic();
                  onPressed!();
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: isLoading ? 0.85 : 0.4),
            disabledForegroundColor: fg,
            shape: RoundedRectangleBorder(borderRadius: GRadius.rMd),
            animationDuration: GMotion.fast,
          ),
          child: _ButtonContent(text: text, icon: icon, isLoading: isLoading, color: fg),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) => _GButton(
        text: text,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
        bg: backgroundColor ?? context.gm.brand,
        fg: foregroundColor ?? context.gm.onBrand,
        haptic: HapticFeedback.lightImpact,
      );
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => _GButton(
        text: text,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
        bg: context.gm.danger,
        fg: context.gm.onDanger,
        haptic: HapticFeedback.mediumImpact,
      );
}

enum StatusChipType { safe, warning, danger, neutral }

/// Status pill in the design-system style. Pass [live] for a pulsing dot
/// (use sparingly: only for genuinely live state).
class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipType type;
  final bool live;

  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusChipType.safe,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = switch (type) {
      StatusChipType.safe => GTone.ok,
      StatusChipType.warning => GTone.warn,
      StatusChipType.danger => GTone.danger,
      StatusChipType.neutral => GTone.neutral,
    };
    return StatusBadge(label, tone: tone, live: live);
  }
}

/// Shimmering placeholder block for loading states.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadii.regular,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final base = c.surfaceSunken;
    final highlight = c.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = GMotion.reduced(context) ? 0.5 : _controller.value * 3 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// Card-shaped skeleton list used while device/command lists load.
class AppSkeletonList extends StatelessWidget {
  final int itemCount;

  const AppSkeletonList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: GSpace.s3),
          child: AppCard(
            enterIndex: index,
            child: Row(
              children: [
                const AppSkeleton(width: 44, height: 44, radius: GRadius.md),
                const SizedBox(width: GSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 140 + (index % 2) * 40.0, height: 14),
                      const SizedBox(height: 8),
                      const AppSkeleton(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Friendly empty / error state with icon, message and optional action.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gm;
    final accent = accentColor;
    final danger = accent != null && accent.toARGB32() == c.danger.toARGB32();

    final parts = <Widget>[
      accent == null || danger
          ? IconBox(icon, size: 72, danger: danger)
          : Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: accent.withValues(alpha: .12), borderRadius: GRadius.rLg),
              child: Icon(icon, size: 36, color: accent),
            ),
      Padding(
        padding: const EdgeInsets.only(top: GSpace.s4),
        child: Text(title, textAlign: TextAlign.center, style: context.text.headlineSmall),
      ),
      if (message != null)
        Padding(
          padding: const EdgeInsets.only(top: GSpace.s2),
          child: Text(message!, textAlign: TextAlign.center, style: context.text.bodyMedium),
        ),
      if (actionLabel != null && onAction != null)
        Padding(
          padding: const EdgeInsets.only(top: GSpace.s6),
          child: SizedBox(width: 220, child: PrimaryButton(text: actionLabel!, onPressed: onAction)),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GSpace.s6, vertical: GSpace.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < parts.length; i++) StaggeredIn(index: i, child: parts[i])],
      ),
    );
  }
}
