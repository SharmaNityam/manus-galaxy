import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    required this.title,
    required this.child,
    this.action,
    this.back = false,
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? action;
  final bool back;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 40),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: ColoredBox(
          color: const Color(0xFFF0F0F0),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: IconButton(
                            tooltip: back ? 'Back' : 'Close',
                            onPressed: () => context.pop(),
                            icon: Icon(
                              back
                                  ? Icons.chevron_left_rounded
                                  : Icons.close_rounded,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      if (action != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: action!,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class FeatureSearchField extends StatelessWidget {
  const FeatureSearchField({
    required this.hint,
    required this.onChanged,
    super.key,
  });
  final String hint;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB7B7B7), fontSize: 16),
      prefixIcon: const Icon(Icons.search_rounded, size: 28),
      filled: true,
      fillColor: const Color(0xFFE5E5E5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
