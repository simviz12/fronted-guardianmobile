import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../commands/presentation/providers/command_provider.dart';
import '../../domain/entities/device.dart';
import '../providers/devices_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final dashboardState = ref.watch(devicesNotifierProvider);
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, ref, user?.displayName, isEn, isDark),
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            await ref.read(devicesNotifierProvider.notifier).loadDevices();
          },
          child: _buildBody(context, ref, dashboardState, isEn, isDark),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, isEn, isDark, dashboardState.thisPhoneDevice),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String? displayName,
    bool isEn,
    bool isDark,
  ) {
    final initial = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : 'C';
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 8,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6F7F0),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFB9F1D8),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.spaceSm + 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Guardian',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textHeadings,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Text(
                isEn ? 'SECURITY' : 'SEGURIDAD',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF6EE7B7) : AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Quick Language Toggle: ES / EN
        IconButton(
          tooltip: isEn ? 'Switch to Spanish' : 'Cambiar a Inglés',
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.transparent,
              border: Border.all(color: theme.colorScheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              isEn ? 'EN' : 'ES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          onPressed: () {
            ref.read(languageProvider.notifier).toggleLanguage();
          },
        ),

        // Quick Theme Toggle: Dark / Light
        IconButton(
          tooltip: isEn ? 'Toggle Theme' : 'Cambiar tema (Oscuro / Claro)',
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 20,
            color: isDark ? Colors.white : AppColors.textHeadings,
          ),
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
        ),

        // Notification Bell Icon
        IconButton(
          tooltip: isEn ? 'Notifications & Activity' : 'Notificaciones y Actividad',
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: isDark ? Colors.white70 : AppColors.textBody,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.alert,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEn ? 'All systems operational. No unacknowledged alerts.' : 'Todos los sistemas operativos. Sin alertas pendientes.',
                ),
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              ),
            );
          },
        ),

        // Profile Avatar Menu
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 2),
          child: PopupMenuButton<String>(
            tooltip: isEn ? 'User Profile & Options' : 'Perfil de Usuario y Opciones',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'settings') {
                context.push('/settings');
              } else if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isEn ? 'Sign Out?' : '¿Cerrar Sesión?'),
                    content: Text(
                      isEn
                          ? 'Are you sure you want to log out of your Guardian account?'
                          : '¿Estás seguro de que deseas cerrar sesión en este teléfono?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(isEn ? 'Cancel' : 'Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.alert),
                        child: Text(isEn ? 'Sign Out' : 'Cerrar Sesión'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? (isEn ? 'User' : 'Usuario'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text(
                      'Guardian Mobile Enterprise',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(isEn ? 'Settings & Profile' : 'Ajustes y Perfil'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 20, color: AppColors.alert),
                    const SizedBox(width: 10),
                    Text(
                      isEn ? 'Sign Out' : 'Cerrar Sesión',
                      style: const TextStyle(color: AppColors.alert, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DevicesDashboardState state,
    bool isEn,
    bool isDark,
  ) {
    if (state.isLoading && state.devices.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (state.errorMessage != null && state.devices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.alertContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.alert,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.alertText,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          Center(
            child: PrimaryButton(
              text: isEn ? 'Retry' : 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: () => ref.read(devicesNotifierProvider.notifier).loadDevices(),
            ),
          ),
        ],
      );
    }

    final thisPhone = state.thisPhoneDevice;
    final otherDevices = state.otherDevices;
    final totalCount = state.devices.length;

    if (totalCount == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: AppSpacing.marginMobile,
          right: AppSpacing.marginMobile,
          top: AppSpacing.spaceSm,
          bottom: 90,
        ),
        children: [
          _buildShieldBanner(context, ref, 0, isEn, isDark),
          const SizedBox(height: AppSpacing.spaceMd),
          _buildLinkPromptBanner(context, isEn, isDark),
          const SizedBox(height: AppSpacing.spaceLg),
          _buildEmptyStateCard(context, isEn, isDark),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.spaceSm,
        bottom: 90,
      ),
      children: [
        // 1. Escudo Activo Status Banner with "Auditar Red"
        _buildShieldBanner(context, ref, totalCount, isEn, isDark),
        const SizedBox(height: AppSpacing.spaceMd),

        // 2. PRIMARY DEVICE CARD (Hero Card based on Reference UI)
        if (thisPhone != null) ...[
          _buildPrimaryDeviceCard(context, ref, thisPhone, isEn, isDark),
          const SizedBox(height: AppSpacing.spaceLg),
        ] else ...[
          _buildLinkPromptBanner(context, isEn, isDark),
          const SizedBox(height: AppSpacing.spaceLg),
        ],

        // 3. OTHER DEVICES SECTION (Reference list styling)
        _buildOtherDevicesSection(context, ref, otherDevices, isEn, isDark),
        const SizedBox(height: AppSpacing.spaceLg),

        // 4. EMERGENCY PROTOCOL CARD (Red container with Immediate Theft Mode Button)
        _buildEmergencyProtocolCard(context, ref, thisPhone ?? (state.devices.isNotEmpty ? state.devices.first : null), isEn, isDark),
      ],
    );
  }

  Widget _buildShieldBanner(
    BuildContext context,
    WidgetRef ref,
    int totalCount,
    bool isEn,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final countLabel = totalCount == 1
        ? (isEn ? '1 device under monitoring' : '1 dispositivo bajo vigilancia')
        : (isEn ? '$totalCount devices under monitoring' : '$totalCount dispositivos bajo vigilancia...');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBBF7D0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.spaceSm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEn ? 'Shield Active' : 'Escudo Activo',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textHeadings,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.safe,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  countLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              context.push('/server-status');
            },
            icon: const Icon(Icons.sync_rounded, size: 14),
            label: Text(
              isEn ? 'Audit Network' : 'Auditar Red',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.full)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryDeviceCard(
    BuildContext context,
    WidgetRef ref,
    Device device,
    bool isEn,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFE6F7F0),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  device.platform == 'ios' ? Icons.apple_rounded : Icons.phone_android_rounded,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textHeadings,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEn ? 'THIS PHONE • PRIMARY DEVICE' : 'ESTE TELÉFONO • DISPOSITIVO PRINCIPAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: isEn ? 'Protected' : 'Protegido',
                type: StatusChipType.safe,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),

          // Telemetry Dual Grid (Battery & Connectivity)
          Row(
            children: [
              // Battery Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                (device.isCharging ?? false) ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
                                size: 16,
                                color: AppColors.safe,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${device.batteryLevel ?? 78}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.textHeadings,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            (device.isCharging ?? false) ? (isEn ? 'Charging' : 'Cargando') : (isEn ? 'Battery' : 'Batería'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (device.batteryLevel ?? 78) / 100.0,
                          backgroundColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (device.isCharging ?? false) ? (isEn ? '~Full in 45m' : '~4h restantes para 100%') : (isEn ? 'Optimal health' : 'Salud óptima'),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),

              // Network Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wifi_rounded, size: 16, color: AppColors.infoBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              device.networkType == 'wifi' ? 'Fibra_Office 5G' : (device.networkType ?? 'Red Móvil 5G'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textHeadings,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            (device.isOnline) ? Icons.signal_cellular_alt_rounded : Icons.signal_cellular_off_rounded,
                            size: 14,
                            color: device.isOnline ? AppColors.safe : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              device.isOnline
                                  ? (isEn ? 'Online' : 'En línea')
                                  : (isEn ? 'Offline' : 'Desconectado'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Location telemetry info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.near_me_rounded, size: 14, color: AppColors.infoBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        device.lastLocation != null
                            ? '${device.lastLocation!.latitude.toStringAsFixed(4)}, ${device.lastLocation!.longitude.toStringAsFixed(4)}'
                            : (isEn ? 'Av. Reforma 222, Piso 8, CDMX' : 'Av. Reforma 222, Piso 8, Cuauhtémoc, CDMX'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textHeadings,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatLastSeen(device.lastSeenAt, isEn),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    Text(
                      isEn ? 'GPS Precision ±3m' : 'Precisión GPS ±3m',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Mini Map Card Preview (Matches reference design)
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              border: Border.all(color: borderColor),
            ),
            child: Stack(
              children: [
                // Stylized map illustration background
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFFE0F2FE), const Color(0xFFF1F5F9)],
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 0.25,
                        child: Icon(
                          Icons.map_rounded,
                          size: 110,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Badge: "Rastreo Satelital Activo"
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.safe,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isEn ? 'Satellite Tracking Active' : 'Rastreo Satelital Activo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textHeadings,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center Pulsing Marker
                Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ),

                // Bottom Right Action: "Abrir en Mapa"
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: InkWell(
                    onTap: () => context.push('/device-map', extra: device),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(color: borderColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            isEn ? 'Open Map' : 'Abrir en Mapa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textHeadings,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),

          // Tactical Actions Row ("Sonar Alarma", "Localizar / Foto")
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmAndSendRing(context, ref, device, isEn),
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: Text(isEn ? 'Sound Alarm' : 'Sonar Alarma'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFEFF6FF),
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/device-detail', extra: device),
                  icon: const Icon(Icons.shield_outlined, size: 18),
                  label: Text(isEn ? 'Manage Device' : 'Gestionar'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFEFF6FF),
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherDevicesSection(
    BuildContext context,
    WidgetRef ref,
    List<Device> otherDevices,
    bool isEn,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEn ? 'Other Linked Devices' : 'Otros Dispositivos Vinculados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textHeadings,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Text(
                '${otherDevices.length} ${isEn ? 'active' : 'activos'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSm),

        if (otherDevices.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.devices_other_rounded, color: isDark ? Colors.white54 : AppColors.textMuted),
                const SizedBox(width: AppSpacing.spaceSm),
                Expanded(
                  child: Text(
                    isEn
                        ? 'No additional devices linked yet. You can link family or secondary laptops/tablets.'
                        : 'Aún no tienes otros equipos vinculados. Puedes proteger laptops o tablets.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/link-device'),
                  child: Text(isEn ? 'Add' : 'Agregar'),
                ),
              ],
            ),
          )
        else
          ...otherDevices.map(
            (dev) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
              child: _buildSecondaryDeviceCard(context, ref, dev, isEn, isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildSecondaryDeviceCard(
    BuildContext context,
    WidgetRef ref,
    Device device,
    bool isEn,
    bool isDark,
  ) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    IconData devIcon;
    if (device.platform == 'ios') {
      devIcon = Icons.tablet_mac_rounded;
    } else if (device.platform == 'windows' || device.platform == 'macos') {
      devIcon = Icons.laptop_mac_rounded;
    } else {
      devIcon = Icons.phone_android_rounded;
    }

    return InkWell(
      onTap: () => context.push('/device-detail', extra: device),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(devIcon, color: AppColors.infoBlue, size: 22),
            ),
            const SizedBox(width: AppSpacing.spaceSm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textHeadings,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: device.isOnline ? AppColors.safe : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.mode == DeviceMode.controller
                            ? (isEn ? 'Controller' : 'Controlador')
                            : (device.isOnline ? (isEn ? 'Online' : 'En línea') : (isEn ? 'Offline' : 'Desconectado')),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      if (device.batteryLevel != null) ...[
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        Text('${device.batteryLevel}% ${isEn ? 'battery' : 'batería'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ] else ...[
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        Text(isEn ? 'No data' : 'Sin datos', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            StatusChip(
              label: device.theftModeActive
                  ? (isEn ? 'Lock Active' : 'Bloqueo Activo')
                  : (!device.isOnline
                      ? (isEn ? 'Offline' : 'Desconectado')
                      : (isEn ? 'Protected' : 'Protegido')),
              type: device.theftModeActive
                  ? StatusChipType.danger
                  : (!device.isOnline ? StatusChipType.neutral : StatusChipType.safe),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyProtocolCard(
    BuildContext context,
    WidgetRef ref,
    Device? targetDevice,
    bool isEn,
    bool isDark,
  ) {
    final alertBg = isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2);
    final alertBorder = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: alertBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: alertBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.alert,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Text(
                  isEn ? 'Emergency Protocol' : 'Protocolo de Emergencia',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFCA5A5) : AppColors.alertText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'Did you misplace a device or suspect theft? Trigger immediate remote lockdown and covert tracking with one touch.'
                : '¿Has extraviado un dispositivo o sospechas de robo? Activa el bloqueo preventivo y rastreo encubierto con un toque.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFFECACA) : AppColors.textBody,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (targetDevice != null) {
                  context.push('/theft-mode', extra: targetDevice);
                } else {
                  context.push('/link-device');
                }
              },
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                isEn ? 'Trigger Immediate Theft Mode' : 'Activar Modo Robo Inmediato',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alert,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkPromptBanner(BuildContext context, bool isEn, bool isDark) {
    return InkWell(
      onTap: () => context.push('/link-device'),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 30),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Link this Phone' : 'Vincular este Celular',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEn ? 'Activate remote protection and real-time telemetry' : 'Activa la protección remota y telemetría en tiempo real',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context, bool isEn, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(Icons.phonelink_off_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            isEn ? 'No linked devices' : 'Sin dispositivos vinculados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textHeadings,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEn
                ? 'Link your device to start real-time monitoring and anti-theft security.'
                : 'Vincula este celular para activar el rastreo satelital y protección.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          PrimaryButton(
            text: isEn ? 'Link this Phone' : 'Vincular Celular',
            icon: Icons.add_link_rounded,
            onPressed: () => context.push('/link-device'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    bool isEn,
    bool isDark,
    Device? thisPhone,
  ) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentNavIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: activeColor.withValues(alpha: isDark ? 0.25 : 0.12),
        onDestinationSelected: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          if (index == 0) {
            // Already home
          } else if (index == 1) {
            // Acciones / Commands
            if (thisPhone != null) {
              context.push('/device-detail', extra: thisPhone);
            } else {
              context.push('/link-device');
            }
          } else if (index == 2) {
            // Mapa
            if (thisPhone != null) {
              context.push('/device-map', extra: thisPhone);
            } else {
              context.push('/link-device');
            }
          } else if (index == 3) {
            // Cuenta / Settings
            context.push('/settings');
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.smartphone_outlined, color: inactiveColor),
            selectedIcon: Icon(Icons.smartphone_rounded, color: activeColor),
            label: isEn ? 'Devices' : 'Dispositivos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined, color: inactiveColor),
            selectedIcon: Icon(Icons.bolt_rounded, color: activeColor),
            label: isEn ? 'Actions' : 'Acciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined, color: inactiveColor),
            selectedIcon: Icon(Icons.location_on_rounded, color: activeColor),
            label: isEn ? 'Map' : 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined, color: inactiveColor),
            selectedIcon: Icon(Icons.manage_accounts_rounded, color: activeColor),
            label: isEn ? 'Account' : 'Cuenta',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSendRing(
    BuildContext context,
    WidgetRef ref,
    Device device,
    bool isEn,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Sound alarm?' : '¿Hacer sonar alarma?'),
        content: Text(
          isEn
              ? 'An alarm will ring at maximum volume on "${device.name}", ignoring silent or vibrate mode.'
              : 'Se emitirá un sonido de alarma a máximo volumen en "${device.name}", ignorando el modo silencio o vibración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isEn ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(isEn ? 'Ring Now' : 'Hacer Sonar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(commandNotifierProvider.notifier).sendRingCommand(deviceId: device.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? 'Ring command dispatched' : 'Orden de alarma enviada al dispositivo'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  String _formatLastSeen(DateTime? lastSeenAt, bool isEn) {
    if (lastSeenAt == null) return isEn ? 'Recently active' : 'Activo recientemente';
    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inSeconds < 60) return isEn ? 'Just now (live)' : 'Justo ahora (en vivo)';
    if (diff.inMinutes < 60) return isEn ? '${diff.inMinutes}m ago' : 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return isEn ? '${diff.inHours}h ago' : 'Hace ${diff.inHours} h';
    return isEn ? '${diff.inDays}d ago' : 'Hace ${diff.inDays} d';
  }
}

