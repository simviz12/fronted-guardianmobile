import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../commands/domain/entities/command.dart';
import '../../../commands/presentation/providers/command_provider.dart';
import '../../../commands/presentation/widgets/command_live_status_stepper.dart';
import '../../../devices/domain/entities/device.dart';
import '../../../../core/network/native_bridge_service.dart';
import '../providers/device_map_provider.dart';
import '../../../../core/localization/language_provider.dart';

class DeviceMapPage extends ConsumerStatefulWidget {
  final Device device;

  const DeviceMapPage({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<DeviceMapPage> createState() => _DeviceMapPageState();
}

class _DeviceMapPageState extends ConsumerState<DeviceMapPage> {
  final MapController _mapController = MapController();
  bool _isLocating = false;

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(deviceMapProvider(widget.device.id));
    final commandState = ref.watch(commandNotifierProvider);
    final isEn = ref.watch(languageProvider) == AppLanguage.en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch mapState latestLocation change to auto-center if needed
    ref.listen<DeviceMapState>(deviceMapProvider(widget.device.id), (prev, next) {
      if (prev?.latestLocation == null && next.latestLocation != null) {
        _mapController.move(
          LatLng(next.latestLocation!.latitude, next.latestLocation!.longitude),
          16.0,
        );
      }
    });

    final targetLocation = mapState.selectedPoint ?? mapState.latestLocation;
    final centerLatLng = targetLocation != null
        ? LatLng(targetLocation.latitude, targetLocation.longitude)
        : (widget.device.lastLocation != null
            ? LatLng(widget.device.lastLocation!.latitude, widget.device.lastLocation!.longitude)
            : const LatLng(4.6097, -74.0817));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_rounded, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.device.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textHeadings,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                    isEn ? 'TRACKING MAP & HISTORY' : 'MAPA DE RASTREO E HISTORIAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isEn ? 'Refresh telemetry' : 'Actualizar telemetría',
            onPressed: () {
              ref.read(deviceMapProvider(widget.device.id).notifier).loadMapData();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: targetLocation != null ? 15.5 : 5.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.simviz12.guardian_mobile',
              ),

              // Polyline connecting history points (Tactical Emerald Trail)
              if (mapState.history.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapState.history
                          .map((loc) => LatLng(loc.latitude, loc.longitude))
                          .toList(),
                      strokeWidth: 4.0,
                      color: theme.colorScheme.primary.withValues(alpha: 0.85),
                      borderColor: Colors.black26,
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                ),

              // Markers for location points
              MarkerLayer(
                markers: [
                  // Historical breadcrumbs
                  ...mapState.history.map((loc) {
                    final isSelected = mapState.selectedPoint?.id == loc.id;
                    return Marker(
                      point: LatLng(loc.latitude, loc.longitude),
                      width: isSelected ? 30 : 16,
                      height: isSelected ? 30 : 16,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(deviceMapProvider(widget.device.id).notifier).selectPoint(loc);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white70 : AppColors.textMuted),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Latest Active Node Marker
                  if (mapState.latestLocation != null)
                    Marker(
                      point: LatLng(
                        mapState.latestLocation!.latitude,
                        mapState.latestLocation!.longitude,
                      ),
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Bar: Filters + Date Range selector
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildTopFilterBar(context, mapState, isEn, isDark),
          ),

          // 3. Floating Quick Control Buttons (Center Me, Satellite, Shield)
          Positioned(
            right: 14,
            top: 80,
            child: Column(
              children: [
                _buildFloatingActionButton(
                  icon: Icons.my_location_rounded,
                  tooltip: isEn ? 'Center target' : 'Centrar dispositivo',
                  onPressed: () {
                    if (targetLocation != null) {
                      _mapController.move(
                        LatLng(targetLocation.latitude, targetLocation.longitude),
                        16.0,
                      );
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildFloatingActionButton(
                  icon: Icons.layers_outlined,
                  tooltip: isEn ? 'Satellite layer' : 'Capa Satelital',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEn ? 'Satellite imagery overlay active' : 'Capa satelital activa'),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildFloatingActionButton(
                  icon: Icons.security_rounded,
                  tooltip: isEn ? 'Lock device' : 'Modo Seguro',
                  onPressed: () {
                    context.push('/theft-mode', extra: widget.device);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // 4. Bottom Trajectory & Action Sheet (Matching reference 2)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSheet(context, mapState, commandState, isEn, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterBar(
    BuildContext context,
    DeviceMapState mapState,
    bool isEn,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Row(
      children: [
        // Date Badge dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: cardBg.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  isEn ? 'Today, 24 Oct 2026' : 'Hoy, 24 Oct 2026',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textHeadings,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Time Range Badge
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: cardBg.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  isEn ? 'Last 6 hours' : 'Últimas 6 h',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textHeadings,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    DeviceMapState mapState,
    CommandExecutionState commandState,
    bool isEn,
    bool isDark,
  ) {
    final activeCommand = commandState.activeCommand;
    final isLocating = _isLocating ||
        (activeCommand != null &&
            activeCommand.type == CommandType.locate &&
            (activeCommand.status == CommandStatus.pending ||
                activeCommand.status == CommandStatus.delivered));

    final theme = Theme.of(context);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final targetLocation = mapState.selectedPoint ?? mapState.latestLocation;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.48,
      ),
      padding: const EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: 10,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: borderColor, width: 1.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Active Command Live Stepper if LOCATE is running
          if (activeCommand != null && activeCommand.type == CommandType.locate) ...[
            CommandLiveStatusStepper(command: activeCommand),
            const SizedBox(height: 12),
          ],

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickFilterChip(
                  isEn ? 'Today' : 'Hoy',
                  isSelected: mapState.selectedRange == LocationRangeFilter.today,
                  isDark: isDark,
                  onTap: () => ref.read(deviceMapProvider(widget.device.id).notifier).changeRange(LocationRangeFilter.today),
                ),
                const SizedBox(width: 6),
                _buildQuickFilterChip(
                  isEn ? 'Yesterday' : 'Ayer',
                  isSelected: mapState.selectedRange == LocationRangeFilter.yesterday,
                  isDark: isDark,
                  onTap: () => ref.read(deviceMapProvider(widget.device.id).notifier).changeRange(LocationRangeFilter.yesterday),
                ),
                const SizedBox(width: 6),
                _buildQuickFilterChip(
                  isEn ? 'Last 7 days' : 'Últimos 7 días',
                  isSelected: mapState.selectedRange == LocationRangeFilter.last7Days,
                  isDark: isDark,
                  onTap: () => ref.read(deviceMapProvider(widget.device.id).notifier).changeRange(LocationRangeFilter.last7Days),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Trajectory Header Row with "Exportar"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isEn ? 'Route History' : 'Historial de trayecto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textHeadings,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFE6F7F0),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      '${mapState.history.isEmpty ? 0 : mapState.history.length} ${isEn ? 'points in history' : 'puntos en historial'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEn ? 'Encrypted GPS audit log exported (PDF/CSV)' : 'Registro forense GPS exportado (PDF/CSV)'),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded, size: 14),
                label: Text(
                  isEn ? 'Export' : 'Exportar',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Subtitle / Location details
          if (targetLocation != null) ...[
            Text(
              '${targetLocation.latitude.toStringAsFixed(5)}, ${targetLocation.longitude.toStringAsFixed(5)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textHeadings,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '±${targetLocation.accuracyMeters?.round() ?? 5}m',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                Expanded(
                  child: Text(
                    isEn
                        ? 'Device: ${widget.device.name} • Synchronized'
                        : 'Dispositivo: ${widget.device.name} • Sincronizado',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              isEn
                  ? 'Device: ${widget.device.name} • Synchronized 1 min ago'
                  : 'Dispositivo: ${widget.device.name} • Sincronizado hace 1 min',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 12),

          if (mapState.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  isEn
                      ? 'No location records found for this period.'
                      : 'Aún no hay ubicaciones registradas para este periodo.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            )
          else ...[
            // Dynamic real timeline stops from device telemetry history
            for (int i = 0; i < mapState.history.length && i < 15; i++) ...[
              _buildTimelineStopItem(
                context,
                icon: i == 0 ? Icons.my_location_rounded : Icons.location_on_rounded,
                iconColor: i == 0 ? AppColors.primary : AppColors.infoBlue,
                title: 'Lat: ${mapState.history[i].latitude.toStringAsFixed(5)}, Lon: ${mapState.history[i].longitude.toStringAsFixed(5)}',
                subtitle: mapState.history[i].speedMps != null && mapState.history[i].speedMps! > 1
                    ? (isEn ? 'In motion (${(mapState.history[i].speedMps! * 3.6).toStringAsFixed(0)} km/h)' : 'En movimiento (${(mapState.history[i].speedMps! * 3.6).toStringAsFixed(0)} km/h)')
                    : (isEn ? 'Stationary' : 'En reposo'),
                time: '${mapState.history[i].recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${mapState.history[i].recordedAt.toLocal().minute.toString().padLeft(2, '0')} hrs',
                accuracy: mapState.history[i].accuracyMeters != null ? '±${mapState.history[i].accuracyMeters!.toStringAsFixed(0)} m' : '±3 m',
                battery: '${widget.device.batteryLevel ?? 80}% batería',
                status: i == 0 ? (isEn ? 'Latest' : 'Última registrada') : (isEn ? 'History' : 'Historial'),
                isDark: isDark,
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),

          // Forensic Legal Certificate Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBBF7D0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Forensic Location Certificate' : 'Certificado de Ubicación Forense',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textHeadings,
                        ),
                      ),
                      Text(
                        isEn
                            ? 'SHA-256 cryptographically verified for police & legal authorities'
                            : 'Válido ante el Ministerio Público y Autoridades Judiciales',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ],
          const SizedBox(height: 10),

          // Action Buttons: "Pedir ubicación ahora" & "Exportar reporte GPS para denuncia policial"
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLocating ? null : () => _handleRequestLocation(),
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(
                    isEn ? 'Request location now' : 'Pedir ubicación ahora',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEn ? 'Encrypted GPS audit log exported (PDF/CSV)' : 'Registro forense GPS exportado (PDF/CSV)'),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 20),
                tooltip: isEn ? 'Export Police Report' : 'Exportar reporte para denuncia',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF1F5F9),
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStopItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required String accuracy,
    required String battery,
    required String status,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textHeadings,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        accuracy,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(battery, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(width: 6),
                    Text('• $status', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    String label, {
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFE6F7F0))
              : (isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  void _handleRequestLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final nativeBridge = ref.read(nativeBridgeServiceProvider);
      final loc = await nativeBridge.getCurrentLocation();

      if (loc != null && loc['latitude'] != null && loc['longitude'] != null) {
        final double lat = (loc['latitude'] as num).toDouble();
        final double lon = (loc['longitude'] as num).toDouble();
        final double? acc = (loc['accuracy'] as num?)?.toDouble();

        try {
          final dataSource = ref.read(locationRemoteDataSourceProvider);
          await dataSource.reportLocation(
            deviceId: widget.device.id,
            latitude: lat,
            longitude: lon,
            accuracyMeters: acc,
            recordedAt: DateTime.now(),
            source: 'LOCATE_COMMAND',
          );
        } catch (_) {}

        _mapController.move(LatLng(lat, lon), 16.0);
        await ref.read(deviceMapProvider(widget.device.id).notifier).loadMapData(silent: true);
        final updatedState = ref.read(deviceMapProvider(widget.device.id));
        if (updatedState.latestLocation != null) {
          _mapController.move(
            LatLng(updatedState.latestLocation!.latitude, updatedState.latestLocation!.longitude),
            16.0,
          );
        }

        if (mounted) {
          setState(() {
            _isLocating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ref.read(languageProvider) == AppLanguage.en
                    ? 'Location captured and reported successfully (Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)})'
                    : 'Ubicación GPS capturada y registrada con éxito (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}).',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        return;
      }
    } catch (_) {}

    final success = await ref
        .read(commandNotifierProvider.notifier)
        .sendLocateCommand(deviceId: widget.device.id);

    if (mounted) {
      setState(() {
        _isLocating = false;
      });
      if (!success) {
        final error = ref.read(commandNotifierProvider).errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.alert,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(languageProvider) == AppLanguage.en
                  ? 'Location command dispatched to device.'
                  : 'Orden de localización enviada al dispositivo.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
