import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manus_trial_app/core/theme/app_theme.dart';
import 'package:manus_trial_app/features/chat/presentation/widgets/markdown_response.dart';

void main() {
  testWidgets(
    'renders GFM content and a copyable code block without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: MarkdownResponse(
                  data: '''## Plan

**One** step, then `done`.

| Name | Result |
| --- | --- |
| A | Ready |

```dart
final message = 'hello';
```''',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text("final message = 'hello';"), findsOneWidget);
      expect(find.byTooltip('Copy code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
