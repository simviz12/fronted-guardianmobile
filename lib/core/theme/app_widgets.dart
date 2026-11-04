import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Scales its child down slightly while pressed: tactile "native" feedback.
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
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final radius = BorderRadius.circular(AppRadii.xl);

    final decoration = BoxDecoration(
      color: backgroundColor ?? defaultBg,
      borderRadius: radius,
      border: border ?? Border.all(color: defaultBorder, width: 1),
      boxShadow: isDark
          ? const []
          : const [
              BoxShadow(
                color: Color.fromRGBO(11, 28, 48, 0.05),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
              BoxShadow(
                color: Color.fromRGBO(11, 28, 48, 0.06),
                offset: Offset(0, 8),
                blurRadius: 24,
                spreadRadius: -6,
              ),
            ],
    );

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.spaceMd),
      child: child,
    );

    if (onTap == null) {
      // Transparent Material above the decoration so ListTiles/Switches inside
      // the card paint their ink splashes on top instead of behind it.
      return DecoratedBox(
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      );
    }

    // Ink + Material so the ripple is painted ON the card, not hidden behind it.
    return PressableScale(
      pressedScale: 0.985,
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
      duration: const Duration(milliseconds: 180),
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
                  const SizedBox(width: AppSpacing.spaceSm),
                ],
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ),
              ],
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primary;
    final fg = foregroundColor ?? theme.colorScheme.onPrimary;
    final enabled = !isLoading && onPressed != null;

    return PressableScale(
      enabled: enabled,
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: isLoading ? 0.85 : 0.4),
            disabledForegroundColor: fg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            elevation: 0,
          ),
          child: _ButtonContent(text: text, icon: icon, isLoading: isLoading, color: fg),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;
    return PressableScale(
      enabled: enabled,
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.alert,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.alert.withValues(alpha: isLoading ? 0.85 : 0.4),
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            elevation: 0,
          ),
          child: _ButtonContent(
            text: text,
            icon: icon,
            isLoading: isLoading,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

enum StatusChipType { safe, warning, danger, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipType type;

  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusChipType.safe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color text;
    Color dot;

    switch (type) {
      case StatusChipType.safe:
        bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : AppColors.safeSubtle;
        text = isDark ? const Color(0xFF6EE7B7) : AppColors.safeText;
        dot = AppColors.safe;
        break;
      case StatusChipType.warning:
        bg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : AppColors.warningSubtle;
        text = isDark ? const Color(0xFFFDE68A) : AppColors.warningText;
        dot = AppColors.warning;
        break;
      case StatusChipType.danger:
        bg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : AppColors.alertContainer;
        text = isDark ? const Color(0xFFFCA5A5) : AppColors.alertText;
        dot = AppColors.alert;
        break;
      case StatusChipType.neutral:
        bg = isDark ? AppColors.darkNeutralBadge : AppColors.neutralBadge;
        text = isDark ? AppColors.darkNeutralBadgeText : AppColors.neutralBadgeText;
        dot = text;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: dot.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: dot.withValues(alpha: 0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer;
    final highlight = isDark ? const Color(0xFF2A3550) : const Color(0xFFF4F7FC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 3 - 1;
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
          padding: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
          child: AppCard(
            child: Row(
              children: [
                const AppSkeleton(width: 44, height: 44, radius: AppRadii.md),
                const SizedBox(width: AppSpacing.spaceMd),
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
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLg, vertical: AppSpacing.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: accent),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.spaceSm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.spaceLg),
            SizedBox(
              width: 220,
              child: PrimaryButton(text: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ),
    );
  }
}
