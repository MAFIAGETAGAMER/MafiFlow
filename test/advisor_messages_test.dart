import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/advisor_messages.dart';

void main() {
  test('first input reaches provider history', () {
    expect(recentAdvisorMessages([{'role': 'user', 'content': 'first'}]),
        [{'role': 'user', 'content': 'first'}]);
  });
  test('new question is retained after more than twenty messages', () {
    final history = List.generate(25, (i) => <String, dynamic>{
      'role': i.isEven ? 'user' : 'assistant', 'content': 'message $i',
    });
    final messages = recentAdvisorMessages(history);
    expect(messages.length, 20);
    expect(messages.first['content'], 'message 5');
    expect(messages.last['content'], 'message 24');
    expect(history.length, 25);
  });
}
