import 'package:flutter_test/flutter_test.dart';
import 'package:bd_epaper_hub/main.dart';

void main() {
  testWidgets('BD E-Paper Hub loads newspaper shelf', (WidgetTester tester) async {
    await tester.pumpWidget(const BdEpaperHubApp());
    expect(find.text('বাংলাদেশ ই-পেপার স্ট্যান্ড'), findsOneWidget);
    expect(find.text('যুগান্তর'), findsOneWidget);
  });
}
