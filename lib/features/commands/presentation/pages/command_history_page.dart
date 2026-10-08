import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../devices/domain/entities/device.dart';
import '../../domain/entities/command.dart';
import '../providers/command_history_provider.dart';

class CommandHistoryPage extends ConsumerStatefulWidget {
  final Device device;

  const CommandHistoryPage({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<CommandHistoryPage> createState() => _CommandHistoryPageState();
}

class _CommandHistoryPageState extends ConsumerState<CommandHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  CommandType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commandHistoryNotifierProvider(widget.device.id).notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(commandHistoryNotifierProvider(widget.device.id).notifier).loadMore();
    }
  }

  void _onFilterSelected(CommandType? type) {
    setState(() {
      _selectedTypeFilter = type;
    });
    ref.read(commandHistoryNotifierProvider(widget.device.id).notifier).filterByType(type);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commandHistoryNotifierProvider(widget.device.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial de Órdenes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.spaceSm,
              ),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Todos',
                    isSelected: _selectedTypeFilter == null,
                    onSelected: () => _onFilterSelected(null),
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  _buildFilterChip(
                    label: 'Alarma (RING)',
                    isSelected: _selectedTypeFilter == CommandType.ring,
                    onSelected: () => _onFilterSelected(CommandType.ring),
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  _buildFilterChip(
                    label: 'Vibrar',
                    isSelected: _selectedTypeFilter == CommandType.vibrate,
                    onSelected: () => _onFilterSelected(CommandType.vibrate),
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  _buildFilterChip(
                    label: 'Mensaje',
                    isSelected: _selectedTypeFilter == CommandType.message,
                    onSelected: () => _onFilterSelected(CommandType.message),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content
            Expanded(
              child: _buildBody(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primarySubtle,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textBody,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildBody(CommandHistoryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.alert),
              const SizedBox(height: AppSpacing.spaceMd),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textBody),
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(commandHistoryNotifierProvider(widget.device.id).notifier).loadInitial();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              const Text(
                'Sin órdenes registradas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadings,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aún no has emitido ningún comando para este dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(commandHistoryNotifierProvider(widget.device.id).notifier).loadInitial();
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.spaceSm),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spaceMd),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final command = state.items[index];
          return _buildCommandRow(command);
        },
      ),
    );
  }

  Widget _buildCommandRow(Command command) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(_getCommandIcon(command.type), color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCommandTitle(command.type),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeadings,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRelativeTime(command.issuedAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(command.status),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            _getCommandDescription(command),
            style: const TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
          if (command.failureReason != null) ...[
            const SizedBox(height: AppSpacing.spaceXs),
            Text(
              'Motivo de fallo: ${command.failureReason}',
              style: const TextStyle(fontSize: 12, color: AppColors.alertText),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCommandIcon(CommandType type) {
    switch (type) {
      case CommandType.ring:
        return Icons.volume_up_rounded;
      case CommandType.vibrate:
        return Icons.vibration_rounded;
      case CommandType.message:
        return Icons.message_rounded;
      case CommandType.locate:
        return Icons.my_location_rounded;
      case CommandType.lock:
        return Icons.lock_rounded;
      case CommandType.theftModeOn:
        return Icons.shield_rounded;
      case CommandType.theftModeOff:
        return Icons.shield_outlined;
      case CommandType.wipe:
        return Icons.delete_forever_rounded;
    }
  }

  String _getCommandTitle(CommandType type) {
    switch (type) {
      case CommandType.ring:
        return 'Alarma Sonora';
      case CommandType.vibrate:
        return 'Vibración Remota';
      case CommandType.message:
        return 'Mensaje en Pantalla';
      case CommandType.locate:
        return 'Localización';
      case CommandType.lock:
        return 'Bloqueo';
      case CommandType.theftModeOn:
        return 'Activar Modo Robo';
      case CommandType.theftModeOff:
        return 'Desactivar Modo Robo';
      case CommandType.wipe:
        return 'Borrado Remoto Total';
    }
  }

  String _getCommandDescription(Command command) {
    switch (command.type) {
      case CommandType.ring:
        final duration = command.payload['durationSeconds'] ?? 60;
        return 'Duración programada: $duration s';
      case CommandType.vibrate:
        final duration = command.payload['durationSeconds'] ?? 5;
        return 'Duración de vibración: $duration s';
      case CommandType.message:
        final text = command.payload['text'] ?? 'Sin mensaje';
        final phone = command.payload['contactPhone'];
        return phone != null ? '"$text" • Tel: $phone' : '"$text"';
      default:
        return 'Comando ejecutado';
    }
  }

  Widget _buildStatusChip(CommandStatus status) {
    switch (status) {
      case CommandStatus.executed:
        return const StatusChip(label: 'Ejecutado', type: StatusChipType.safe);
      case CommandStatus.delivered:
        return const StatusChip(label: 'Entregado', type: StatusChipType.neutral);
      case CommandStatus.pending:
        return const StatusChip(label: 'Enviando', type: StatusChipType.warning);
      case CommandStatus.failed:
        return const StatusChip(label: 'Falló', type: StatusChipType.danger);
      case CommandStatus.expired:
        return const StatusChip(label: 'Expiró', type: StatusChipType.danger);
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'hace unos segundos';
    } else if (diff.inMinutes < 60) {
      return 'hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'hace ${diff.inHours} h';
    } else {
      return 'hace ${diff.inDays} días';
    }
  }
}
