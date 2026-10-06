import 'command.dart';

class CommandPage {
  final List<Command> items;
  final String? nextCursor;
  final bool hasMore;

  const CommandPage({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });
}
