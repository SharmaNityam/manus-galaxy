import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/connector.dart';
import 'connector_widgets.dart';

Future<void> showConnectorsSheet(BuildContext context) async {
  final target = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              'Connectors',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666661),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _Group(
                  child: Column(
                    children: [
                      _NavigationRow(
                        icon: Icons.add_rounded,
                        label: 'Add connectors',
                        onTap: () => Navigator.of(context).pop('/connectors'),
                      ),
                      _NavigationRow(
                        icon: Icons.tune_rounded,
                        label: 'Manage connectors',
                        onTap: () =>
                            Navigator.of(context).pop('/connectors/manage'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Group(
                  child: Column(
                    children: Connector.all
                        .skip(3)
                        .take(8)
                        .map(
                          (connector) => InkWell(
                            onTap: () => Navigator.of(
                              context,
                            ).pop('/connectors/${connector.id}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  ConnectorIcon(connector: connector, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            connector.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (connector.beta) ...[
                                          const SizedBox(width: 6),
                                          const BetaBadge(),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Connect',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF8B8B87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  if (target != null && context.mounted) await context.push(target);
}

class _Group extends StatelessWidget {
  const _Group({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: ColoredBox(color: const Color(0xFFF7F7F7), child: child),
  );
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 48,
    minLeadingWidth: 24,
    horizontalTitleGap: 4,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: Icon(icon, size: 24, color: const Color(0xFF666661)),
    title: Text(label, style: const TextStyle(fontSize: 16)),
    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B8B87)),
    onTap: onTap,
  );
}
