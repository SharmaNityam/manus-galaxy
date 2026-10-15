import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../domain/connector.dart';

class ConnectorIcon extends StatelessWidget {
  const ConnectorIcon({required this.connector, this.size = 22, super.key});
  final Connector connector;
  final double size;
  @override
  Widget build(BuildContext context) {
    final icon = switch (connector.id) {
      'computer' => Icons.ads_click_rounded,
      'video' => Icons.movie_edit,
      'skill' => Icons.radio_button_checked_rounded,
      _ => null,
    };
    if (icon != null) return Icon(icon, size: size);
    return SvgPicture.asset(
      connector.asset,
      width: size,
      height: size,
      colorFilter:
          [
            'instagram',
            'googleworkspace',
            'outlookcalendar',
            'outlookmail',
          ].contains(connector.id)
          ? null
          : ColorFilter.mode(Color(connector.color), BlendMode.srcIn),
    );
  }
}

class BetaBadge extends StatelessWidget {
  const BetaBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD9D9D9)),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
    ),
    child: const Text(
      'Beta',
      style: TextStyle(fontSize: 12, color: Color(0xFF8B8B87)),
    ),
  );
}
