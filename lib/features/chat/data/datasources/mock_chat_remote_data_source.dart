import 'chat_remote_data_source.dart';

class MockChatRemoteDataSource implements ChatRemoteDataSource {
  @override
  Stream<String> streamReply(String prompt) async* {
    final response = '''I can help with that. You asked: **$prompt**

Here is a quick example:

| Step | Result |
| --- | --- |
| 1 | Plan the change |
| 2 | Check the result |

```dart
void main() => print('Ready');
```''';
    for (var index = 0; index < response.length; index += 5) {
      await Future<void>.delayed(const Duration(milliseconds: 35));
      yield response.substring(index, (index + 5).clamp(0, response.length));
    }
  }
}
