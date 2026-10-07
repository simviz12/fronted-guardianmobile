import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../commands/domain/entities/command.dart';
import '../../../commands/presentation/providers/command_provider.dart';
import '../../../commands/presentation/widgets/command_live_status_stepper.dart';
import '../../../devices/domain/entities/device.dart';
import '../providers/device_map_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(deviceMapProvider(widget.device.id));
    final commandState = ref.watch(commandNotifierProvider);

    // Watch command completion to refresh map
    ref.listen<CommandExecutionState>(commandNotifierProvider, (prev, next) {
      if (prev?.activeCommand?.type == CommandType.locate) {
        if (next.activeCommand?.status == CommandStatus.executed) {
          // Command finished successfully! Refresh map and center
          ref.read(deviceMapProvider(widget.device.id).notifier).loadMapData(silent: true).then((_) {
            final updatedState = ref.read(deviceMapProvider(widget.device.id));
            if (updatedState.latestLocation != null) {
              _mapController.move(
                LatLng(
                  updatedState.latestLocation!.latitude,
                  updatedState.latestLocation!.longitude,
                ),
                16.0,
              );
            }
          });
        }
      }
    });

    final targetLocation = mapState.selectedPoint ?? mapState.latestLocation;
    final centerLatLng = targetLocation != null
        ? LatLng(targetLocation.latitude, targetLocation.longitude)
        : const LatLng(4.60971, -74.08175); // Default Bogota center

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadings,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Text(
              'MAPA DE RASTREO E HISTORIAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar historial',
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
              initialZoom: targetLocation != null ? 15.0 : 5.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.simviz12.guardian_mobile',
              ),

              // Polyline connecting history points
              if (mapState.history.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapState.history
                          .map((loc) => LatLng(loc.latitude, loc.longitude))
                          .toList(),
                      color: AppColors.primary,
                      strokeWidth: 3.5,
                    ),
                  ],
                ),

              // Accuracy Circle
              if (targetLocation?.accuracyMeters != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(targetLocation!.latitude, targetLocation.longitude),
                      radius: (targetLocation.accuracyMeters!).clamp(10.0, 150.0),
                      useRadiusInMeter: false,
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderColor: AppColors.primary.withValues(alpha: 0.6),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // History intermediate dots
                  ...mapState.history.skip(1).map(
                    (loc) => Marker(
                      point: LatLng(loc.latitude, loc.longitude),
                      width: 20,
                      height: 20,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(deviceMapProvider(widget.device.id).notifier).selectPoint(loc);
                          _mapController.move(LatLng(loc.latitude, loc.longitude), 16.0);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.textMuted, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Latest marker (Active Live Node)
                  if (mapState.latestLocation != null)
                    Marker(
                      point: LatLng(
                        mapState.latestLocation!.latitude,
                        mapState.latestLocation!.longitude,
                      ),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(deviceMapProvider(widget.device.id).notifier).selectPoint(mapState.latestLocation);
                          _mapController.move(
                            LatLng(
                              mapState.latestLocation!.latitude,
                              mapState.latestLocation!.longitude,
                            ),
                            16.5,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // OpenStreetMap Attribution
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // 2. Top Controls & Range Selector
          Positioned(
            top: 12,
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
            child: _buildTopFilterBar(mapState),
          ),

          // 3. Quick Map Floating Actions (Center, Open External Maps)
          Positioned(
            right: 16,
            top: 75,
            child: Column(
              children: [
                _buildFloatingActionButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Centrar en dispositivo',
                  onPressed: () {
                    if (mapState.latestLocation != null) {
                      _mapController.move(
                        LatLng(
                          mapState.latestLocation!.latitude,
                          mapState.latestLocation!.longitude,
                        ),
                        16.0,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (targetLocation != null)
                  _buildFloatingActionButton(
                    icon: Icons.open_in_new_rounded,
                    tooltip: 'Abrir en Google Maps / Navegador',
                    onPressed: () => _openInExternalMaps(
                      targetLocation.latitude,
                      targetLocation.longitude,
                    ),
                  ),
              ],
            ),
          ),

          // 4. Loading indicator or Error snack
          if (mapState.isLoading)
            const Positioned(
              top: 75,
              left: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Actualizando...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Bottom Trajectory & Action Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSheet(context, mapState, commandState),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterBar(DeviceMapState mapState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: LocationRangeFilter.values.map((filter) {
          final isSelected = mapState.selectedRange == filter;
          return ChoiceChip(
            label: Text(
              filter.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textBody,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLow,
            onSelected: (selected) {
              if (selected) {
                ref.read(deviceMapProvider(widget.device.id).notifier).changeRange(filter);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    DeviceMapState mapState,
    CommandExecutionState commandState,
  ) {
    final activeCommand = commandState.activeCommand;
    final isLocating = activeCommand != null &&
        activeCommand.type == CommandType.locate &&
        (activeCommand.status == CommandStatus.pending ||
            activeCommand.status == CommandStatus.delivered);

    final targetLocation = mapState.selectedPoint ?? mapState.latestLocation;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.44,
      ),
      padding: const EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: 12,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
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

          // Info Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetLocation != null
                          ? 'Última ubicación: ${_formatRelativeTime(targetLocation.recordedAt)}'
                          : 'Aún no hay ubicaciones',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeadings,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      targetLocation != null
                          ? '${targetLocation.latitude.toStringAsFixed(5)}, ${targetLocation.longitude.toStringAsFixed(5)}'
                          : 'Pide una ubicación para comenzar el rastreo.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              if (targetLocation?.accuracyMeters != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_fixed_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '±${targetLocation!.accuracyMeters!.round()}m',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons Row: "Pedir ubicación ahora"
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: isLocating ? 'Obteniendo GPS...' : 'Pedir ubicación ahora',
                  icon: Icons.my_location_rounded,
                  isLoading: isLocating || commandState.isSubmitting,
                  onPressed: isLocating || commandState.isSubmitting
                      ? null
                      : () => _handleRequestLocation(),
                ),
              ),
              if (targetLocation != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Abrir en mapa externo',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                  ),
                  icon: const Icon(Icons.map_rounded, color: AppColors.primary),
                  onPressed: () => _openInExternalMaps(
                    targetLocation.latitude,
                    targetLocation.longitude,
                  ),
                ),
              ],
            ],
          ),

          // History Summary count / empty state
          const SizedBox(height: 10),
          if (mapState.history.isEmpty && !mapState.isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Text(
                'Aún no hay ubicaciones registradas para este periodo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else if (mapState.history.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${mapState.history.length} puntos en historial',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
                if (mapState.selectedPoint != null)
                  TextButton(
                    onPressed: () {
                      ref.read(deviceMapProvider(widget.device.id).notifier).selectPoint(null);
                    },
                    child: const Text(
                      'Ver más reciente',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _handleRequestLocation() async {
    final success = await ref
        .read(commandNotifierProvider.notifier)
        .sendLocateCommand(deviceId: widget.device.id);

    if (!success && mounted) {
      final error = ref.read(commandNotifierProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    }
  }

  void _openInExternalMaps(double lat, double lon) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}
