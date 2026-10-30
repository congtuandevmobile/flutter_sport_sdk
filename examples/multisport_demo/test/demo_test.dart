import 'package:flutter/material.dart';
import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart';
import 'package:flutter_multisport/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multisport_demo/main.dart';

void main() {
  testWidgets('the user adds a sport with a goal, starts the challenge, and the stage on screen is the one chosen', (tester) async {
    final platform = FakeChallengePlatform();
    await tester.pumpWidget(MultisportDemoApp(challenge: FlutterChallenge(platform: platform), store: MemoryTelemetryStore()));
    expect(find.text('Start challenge'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Start challenge')).onPressed, isNull, reason: 'nothing to start yet');

    await tester.tap(find.text('Add stage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add')); // running, distance, 1 km (the defaults)
    await tester.pumpAndSettle();
    expect(find.text('Running 1 km'), findsOneWidget);

    await tester.tap(find.text('Start challenge'));
    await tester.pumpAndSettle();
    expect(find.text('Stage 1 of 1'), findsOneWidget);
    expect(platform.definition.stages.single.metric, ProgressMetric.runMeters);
    expect(platform.definition.stages.single.target, 1000);
  });

  testWidgets('a sport without a standard source cannot be added until the user ends it by hand', (tester) async {
    await tester.pumpWidget(MultisportDemoApp(challenge: FlutterChallenge(platform: FakeChallengePlatform()), store: MemoryTelemetryStore()));
    await tester.tap(find.text('Add stage'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<SportType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('swimming').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('no default source'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Add')).onPressed, isNull);
    await tester.tap(find.text('I end it by hand'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Add')).onPressed, isNotNull);
  });

  testWidgets('when a stage completes the screen offers the next one, and at the end the results', (tester) async {
    final platform = FakeChallengePlatform();
    await tester.pumpWidget(MultisportDemoApp(challenge: FlutterChallenge(platform: platform), store: MemoryTelemetryStore()));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Add stage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Start challenge'));
    await tester.pumpAndSettle();

    platform.completeStage();
    await tester.pumpAndSettle();
    expect(find.text('Next stage'), findsOneWidget);
    await tester.tap(find.text('Next stage'));
    await tester.pumpAndSettle();
    expect(find.text('Stage 2 of 2'), findsOneWidget);

    platform.completeStage();
    await tester.pumpAndSettle();
    expect(find.text('Challenge completed'), findsOneWidget);
    await tester.tap(find.text('See the results'));
    await tester.pumpAndSettle();
    expect(find.text('1. running'), findsOneWidget);
    expect(find.text('2. running'), findsOneWidget);
    expect(find.textContaining('avg —'), findsWidgets, reason: 'no heart-rate sensor ran: nothing is made up');
  });
}
