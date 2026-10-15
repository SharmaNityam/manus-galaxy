import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../domain/connector.dart';
import 'connector_widgets.dart';

class ConnectorsScreen extends StatefulWidget {
  const ConnectorsScreen({this.manage = false, super.key});
  final bool manage;
  @override
  State<ConnectorsScreen> createState() => _ConnectorsScreenState();
}

class _ConnectorsScreenState extends State<ConnectorsScreen> {
  String _query = '';
  String _category = 'All';
  @override
  Widget build(BuildContext context) {
    final filtered = Connector.all
        .where(
          (item) =>
              item.name.toLowerCase().contains(_query.toLowerCase()) &&
              (_category == 'All' || item.category == _category),
        )
        .toList();
    return FeatureScaffold(
      title: 'Connectors',
      action: widget.manage
          ? IconButton(
              tooltip: 'Add connectors',
              onPressed: () => context.push('/connectors'),
              icon: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      child: widget.manage
          ? _EmptyConnections(onAdd: () => context.push('/connectors'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FeatureSearchField(
                    hint: 'Search connectors',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      final category = [
                        'All',
                        'Finance',
                        'Health',
                        'Travel',
                        'Productivity',
                      ][index];
                      return ChoiceChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            color: _category == category
                                ? Colors.white
                                : const Color(0xFF8B8B87),
                          ),
                        ),
                        showCheckmark: false,
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                        selectedColor: const Color(0xFF171717),
                        backgroundColor: Colors.transparent,
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: _category == category
                              ? Colors.transparent
                              : const Color(0xFFD9D9D9),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No connectors found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final connector = filtered[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    context.push('/connectors/${connector.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFE4E4E4),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: ConnectorIcon(
                                          connector: connector,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    connector.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                if (connector.beta) ...[
                                                  const SizedBox(width: 6),
                                                  const BetaBadge(),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              connector.description,
                                              style: const TextStyle(
                                                color: Color(0xFF8B8B87),
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (index < 3 &&
                                          _query.isEmpty &&
                                          _category == 'All')
                                        const Padding(
                                          padding: EdgeInsets.only(left: 12),
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 24,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _EmptyConnections extends StatelessWidget {
  const _EmptyConnections({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cable_rounded, size: 36, color: Color(0xFF8B8B87)),
          const SizedBox(height: 14),
          const Text(
            'Connect Manus with your everyday apps, APIs and MCPs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B8B87),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add connectors'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDCDCDC),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
