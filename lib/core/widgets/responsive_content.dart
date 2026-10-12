import 'package:flutter/material.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.maxWidth = 760,
    this.horizontalPadding,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sidePadding =
            horizontalPadding ??
            (width < 360
                ? 12.0
                : width < 600
                ? 20.0
                : 28.0);

        return Center(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: child,
          ),
        );
      },
    );
  }
}
