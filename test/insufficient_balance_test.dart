import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymz_user/features/gym_detail/presentation/widgets/booking_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  testWidgets('InsufficientBalanceDialog displays correct amounts and triggers onAddMoney', (WidgetTester tester) async {
    bool addMoneyTapped = false;
    bool cancelTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsufficientBalanceDialog(
            requiredAmount: 500,
            currentBalance: 150,
            onAddMoney: () {
              addMoneyTapped = true;
            },
            onCancel: () {
              cancelTapped = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Insufficient Balance'), findsOneWidget);
    expect(
      find.text('You do not have enough funds in your wallet to book this session. Please add money to your wallet to continue.'),
      findsOneWidget,
    );

    // Verify Breakdown details
    expect(find.text('Current Balance'), findsOneWidget);
    expect(find.text('₹150'), findsOneWidget);
    expect(find.text('Session Fee'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget);
    expect(find.text('Amount Needed'), findsOneWidget);
    expect(find.text('₹350'), findsOneWidget);

    // Verify "Add Money in Wallet" button exists and invokes callback
    final addMoneyFinder = find.text('Add Money in Wallet');
    expect(addMoneyFinder, findsOneWidget);
    await tester.tap(addMoneyFinder);
    await tester.pumpAndSettle();
    expect(addMoneyTapped, isTrue);

    // Verify Cancel button exists and invokes callback
    final cancelFinder = find.text('Cancel');
    expect(cancelFinder, findsOneWidget);
    await tester.tap(cancelFinder);
    await tester.pumpAndSettle();
    expect(cancelTapped, isTrue);
  });
}
