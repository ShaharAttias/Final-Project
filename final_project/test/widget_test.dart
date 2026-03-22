import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_project/main.dart';

void main() {
  testWidgets('VisionApp loading smoke test', (WidgetTester tester) async {
    // בניית האפליקציה והזרקת פריים ראשון
    // הערה: בגלל שהמצלמה והמודל דורשים חומרה, הבדיקה תעצור במסך הטעינה
    await tester.pumpWidget(const MaterialApp(home: VisionApp()));

    // בדיקה אם מופיע הטקסט של הטעינה שהגדרנו ב-main
    // שזה מוודא שהווידג'ט VisionApp נוצר בהצלחה
    expect(find.textContaining('מכין'), findsOneWidget);

    // בדיקה שמעגל הטעינה (CircularProgressIndicator) קיים על המסך
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}