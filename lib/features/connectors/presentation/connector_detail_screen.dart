import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../domain/connector.dart';
import 'connector_widgets.dart';

class ConnectorDetailScreen extends StatefulWidget {
  const ConnectorDetailScreen({required this.id, super.key});
  final String id;
  @override
  State<ConnectorDetailScreen> createState() => _ConnectorDetailScreenState();
}

class _ConnectorDetailScreenState extends State<ConnectorDetailScreen> {
  bool _opening = false;
  String? _error;

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() => _error = 'Could not open the link. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open the link. Please try again.');
      }
    }
  }

  Future<void> _connect(Connector connector) async {
    const base = String.fromEnvironment('CONNECTOR_AUTH_BASE_URL');
    if (base.isEmpty || Uri.tryParse(base)?.scheme != 'https') {
      setState(
        () => _error =
            'Account connection is not configured for this build. You can still browse connector details.',
      );
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    await _open(
      '${base.replaceAll(RegExp(r'/+$'), '')}/authorize/${connector.id}',
    );
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    final connector = Connector.find(widget.id);
    return FeatureScaffold(
      title: '',
      back: true,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE4E4E4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ConnectorIcon(connector: connector, size: 42),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        connector.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (connector.beta) ...[
                      const SizedBox(width: 8),
                      const BetaBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  connector.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8B8B87),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF666661),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Additional configuration required.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666661),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8B8B87),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Connector Type', value: 'App'),
                      _DetailRow(label: 'Author', value: 'Manus'),
                      if (connector.website.isNotEmpty)
                        _DetailRow(
                          label: 'Website',
                          onTap: () => _open(connector.website),
                        ),
                      if (connector.documentation.isNotEmpty)
                        _DetailRow(
                          label: 'Documentation',
                          onTap: () => _open(connector.documentation),
                        ),
                      _DetailRow(
                        label: 'Privacy Policy',
                        onTap: () => _open('https://manus.im/privacy'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFF9A3535), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FilledButton(
              onPressed: _opening ? null : () => _connect(connector),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _opening
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Connect',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.onTap});
  final String label;
  final String? value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 56),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F3F3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Color(0xFF8B8B87)),
            ),
          ),
          if (value != null)
            Text(value!, style: const TextStyle(fontSize: 16))
          else
            const Icon(
              Icons.north_east_rounded,
              color: Color(0xFF8B8B87),
              size: 22,
            ),
        ],
      ),
    ),
  );
}
