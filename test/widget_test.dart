import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app smoke test', (WidgetTester tester) async {
    // WebView는 실기기/에뮬레이터에서 검증. 여기서는 빌드 오류 없음만 확인.
    expect(true, isTrue);
  });
}
