import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('SignalTextController', () {
    test('should create with initial text', () {
      final controller = SignalTextController(text: 'Hello');
      expect(controller.text.value, equals('Hello'));
      expect(controller.controller.text, equals('Hello'));
      controller.dispose();
    });

    test('should create with empty text by default', () {
      final controller = SignalTextController();
      expect(controller.text.value, equals(''));
      expect(controller.isEmpty.value, isTrue);
      expect(controller.isNotEmpty.value, isFalse);
      controller.dispose();
    });

    test('should sync text signal to controller', () {
      final controller = SignalTextController();
      controller.text.value = 'Test';
      expect(controller.controller.text, equals('Test'));
      controller.dispose();
    });

    test('should sync controller to text signal', () {
      final controller = SignalTextController();
      controller.controller.text = 'Test';
      expect(controller.text.value, equals('Test'));
      controller.dispose();
    });

    test('should update isEmpty and isNotEmpty correctly', () {
      final controller = SignalTextController();
      expect(controller.isEmpty.value, isTrue);
      expect(controller.isNotEmpty.value, isFalse);

      controller.text.value = 'Hello';
      expect(controller.isEmpty.value, isFalse);
      expect(controller.isNotEmpty.value, isTrue);

      controller.clear();
      expect(controller.isEmpty.value, isTrue);
      expect(controller.isNotEmpty.value, isFalse);
      controller.dispose();
    });

    test('should track text length', () {
      final controller = SignalTextController(text: 'Hello');
      expect(controller.length.value, equals(5));

      controller.text.value = 'Hi';
      expect(controller.length.value, equals(2));
      controller.dispose();
    });

    test('should clear text', () {
      final controller = SignalTextController(text: 'Hello');
      controller.clear();
      expect(controller.text.value, equals(''));
      expect(controller.controller.text, equals(''));
      controller.dispose();
    });

    test('should create from existing controller', () {
      final existingController = TextEditingController(text: 'Existing');
      final signalController =
          SignalTextController.fromController(existingController);
      expect(signalController.text.value, equals('Existing'));
      signalController.dispose();
    });

    test('should trigger effect on text change', () {
      final controller = SignalTextController();
      var effectCount = 0;
      final eff = effect(() {
        controller.text.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      controller.text.value = 'Hello';
      expect(effectCount, equals(2));

      controller.text.value = 'World';
      expect(effectCount, equals(3));

      eff.stop();
      controller.dispose();
    });

    test('should not trigger after dispose', () {
      final controller = SignalTextController();
      controller.dispose();
      // Should not throw
      controller.text.value = 'Test';
    });

    test('should track selection', () {
      final controller = SignalTextController(text: 'Hello');
      controller.controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);
      expect(controller.selection.value.baseOffset, equals(0));
      expect(controller.selection.value.extentOffset, equals(5));
      controller.dispose();
    });
  });

  group('SignalScrollController', () {
    test('should create with initial offset', () {
      final controller = SignalScrollController(initialScrollOffset: 100.0);
      expect(controller.offset.value, equals(100.0));
      controller.dispose();
    });

    test('should create with default offset', () {
      final controller = SignalScrollController();
      expect(controller.offset.value, equals(0.0));
      controller.dispose();
    });

    test('should track scroll direction', () {
      final controller = SignalScrollController();
      expect(controller.direction.value, equals(ScrollDirection.idle));
      controller.dispose();
    });

    test('should compute showBackToTop based on threshold', () {
      final controller =
          SignalScrollController(showBackToTopThreshold: 100.0);
      expect(controller.showBackToTop.value, isFalse);
      controller.dispose();
    });

    test('should compute isAtTop', () {
      final controller = SignalScrollController();
      expect(controller.isAtTop.value, isTrue);
      controller.dispose();
    });

    test('should create from existing controller', () {
      final existingController = ScrollController(initialScrollOffset: 50.0);
      final signalController =
          SignalScrollController.fromController(existingController);
      expect(signalController.offset.value, equals(0)); // No clients attached
      signalController.dispose();
    });

    test('should dispose properly', () {
      final controller = SignalScrollController();
      controller.dispose();
      // Should not throw on double dispose
      controller.dispose();
    });
  });

  group('SignalFocusNode', () {
    test('should create with default values', () {
      final focusNode = SignalFocusNode();
      expect(focusNode.hasFocus.value, isFalse);
      focusNode.dispose();
    });

    test('should create with debug label', () {
      final focusNode = SignalFocusNode(debugLabel: 'TestFocus');
      expect(focusNode.focusNode.debugLabel, equals('TestFocus'));
      focusNode.dispose();
    });

    test('should create from existing focus node', () {
      final existingNode = FocusNode();
      final signalFocusNode = SignalFocusNode.fromNode(existingNode);
      expect(signalFocusNode.focusNode, equals(existingNode));
      signalFocusNode.dispose();
    });

    test('should request and unfocus', () {
      final focusNode = SignalFocusNode();
      // Can't actually test focus without widget tree, but methods should not throw
      focusNode.requestFocus();
      focusNode.unfocus();
      focusNode.dispose();
    });

    test('should dispose properly', () {
      final focusNode = SignalFocusNode();
      focusNode.dispose();
      // Should not throw on double dispose
      focusNode.dispose();
    });
  });

  group('SignalPageController', () {
    test('should create with initial page', () {
      final controller = SignalPageController(initialPage: 2);
      expect(controller.page.value, equals(2.0));
      controller.dispose();
    });

    test('should create with default page', () {
      final controller = SignalPageController();
      expect(controller.page.value, equals(0.0));
      controller.dispose();
    });

    test('should compute currentPage', () {
      final controller = SignalPageController(initialPage: 3);
      expect(controller.currentPage.value, equals(3));
      controller.dispose();
    });

    test('should create from existing controller', () {
      final existingController = PageController(initialPage: 1);
      final signalController =
          SignalPageController.fromController(existingController);
      expect(signalController.page.value, equals(0)); // No clients attached
      signalController.dispose();
    });

    test('should handle viewport fraction', () {
      final controller =
          SignalPageController(viewportFraction: 0.8);
      expect(controller.controller.viewportFraction, equals(0.8));
      controller.dispose();
    });

    test('should dispose properly', () {
      final controller = SignalPageController();
      controller.dispose();
      // Should not throw on double dispose
      controller.dispose();
    });
  });

  group('SignalTabController', () {
    testWidgets('should create with length and vsync', (tester) async {
      late SignalTabController tabController;

      await tester.pumpWidget(
        MaterialApp(
          home: _TestTabControllerWidget(
            onCreate: (controller) => tabController = controller,
          ),
        ),
      );

      expect(tabController.index.value, equals(0));
      expect(tabController.length, equals(3));

      tabController.dispose();
    });

    testWidgets('should track tab index changes', (tester) async {
      late SignalTabController tabController;

      await tester.pumpWidget(
        MaterialApp(
          home: _TestTabControllerWidget(
            onCreate: (controller) => tabController = controller,
          ),
        ),
      );

      tabController.animateTo(1);
      await tester.pumpAndSettle();

      expect(tabController.index.value, equals(1));

      tabController.dispose();
    });

    testWidgets('should create with initial index', (tester) async {
      late SignalTabController tabController;

      await tester.pumpWidget(
        MaterialApp(
          home: _TestTabControllerWidget(
            initialIndex: 2,
            onCreate: (controller) => tabController = controller,
          ),
        ),
      );

      expect(tabController.index.value, equals(2));

      tabController.dispose();
    });

    testWidgets('should dispose properly', (tester) async {
      late SignalTabController tabController;

      await tester.pumpWidget(
        MaterialApp(
          home: _TestTabControllerWidget(
            onCreate: (controller) => tabController = controller,
          ),
        ),
      );

      tabController.dispose();
      // Dispose again should not throw
      tabController.dispose();
    });
  });

  group('ScrollDirection enum', () {
    test('should have correct values', () {
      expect(ScrollDirection.values.length, equals(3));
      expect(ScrollDirection.idle, isNotNull);
      expect(ScrollDirection.forward, isNotNull);
      expect(ScrollDirection.reverse, isNotNull);
    });
  });

  group('Edge cases', () {
    test('SignalTextController should handle unicode', () {
      final controller = SignalTextController(text: '你好世界 🌍');
      expect(controller.text.value, equals('你好世界 🌍'));
      expect(controller.length.value, equals(7)); // Emoji counts as 2
      controller.dispose();
    });

    test('SignalTextController should handle multiline text', () {
      final controller = SignalTextController(text: 'Line 1\nLine 2\nLine 3');
      expect(controller.text.value.contains('\n'), isTrue);
      controller.dispose();
    });

    test('SignalScrollController should handle negative thresholds', () {
      final controller =
          SignalScrollController(showBackToTopThreshold: -100.0);
      // Should always show back to top with negative threshold
      expect(controller.showBackToTop.value, isTrue);
      controller.dispose();
    });

    test('SignalPageController should handle fractional pages', () {
      final controller = SignalPageController();
      // Without clients, page stays at initial value
      expect(controller.currentPage.value, equals(0));
      controller.dispose();
    });
  });

  group('Memory and disposal', () {
    test('SignalTextController should clean up listeners', () {
      final controller = SignalTextController();
      var effectCount = 0;
      final eff = effect(() {
        controller.text.value;
        effectCount++;
      });

      controller.text.value = 'Test';
      expect(effectCount, equals(2));

      eff.stop();
      controller.dispose();

      // Effect should not run anymore
      final previousCount = effectCount;
      // This won't trigger effect because it's stopped
      controller.text.value = 'After dispose';
      expect(effectCount, equals(previousCount));
    });

    test('Multiple controllers should work independently', () {
      final controller1 = SignalTextController(text: 'One');
      final controller2 = SignalTextController(text: 'Two');

      expect(controller1.text.value, equals('One'));
      expect(controller2.text.value, equals('Two'));

      controller1.text.value = 'Modified';
      expect(controller1.text.value, equals('Modified'));
      expect(controller2.text.value, equals('Two'));

      controller1.dispose();
      controller2.dispose();
    });
  });
}

/// Helper widget for testing SignalTabController
class _TestTabControllerWidget extends StatefulWidget {
  final void Function(SignalTabController) onCreate;
  final int initialIndex;

  const _TestTabControllerWidget({
    required this.onCreate,
    this.initialIndex = 0,
  });

  @override
  State<_TestTabControllerWidget> createState() =>
      _TestTabControllerWidgetState();
}

class _TestTabControllerWidgetState extends State<_TestTabControllerWidget>
    with SingleTickerProviderStateMixin {
  late SignalTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignalTabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    widget.onCreate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _controller.controller,
          tabs: const [
            Tab(text: 'Tab 1'),
            Tab(text: 'Tab 2'),
            Tab(text: 'Tab 3'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller.controller,
        children: const [
          Center(child: Text('Tab 1')),
          Center(child: Text('Tab 2')),
          Center(child: Text('Tab 3')),
        ],
      ),
    );
  }
}
