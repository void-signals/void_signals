import 'package:flutter/material.dart';
import 'package:void_signals/void_signals.dart' as signals;
import 'package:void_signals/void_signals.dart' show Signal, Computed, Effect;

// =============================================================================
// Flutter Controller Signals
//
// Reactive wrappers for common Flutter controllers that automatically
// sync controller state with signals for reactive UI updates.
// =============================================================================

/// A reactive wrapper around [TextEditingController].
///
/// Provides a signal-based interface for text input that automatically
/// syncs with the underlying controller.
///
/// Example:
/// ```dart
/// final nameInput = SignalTextController();
///
/// // In your widget
/// TextField(controller: nameInput.controller);
///
/// // React to changes
/// Watch(builder: (context, _) {
///   return Text('Hello, ${nameInput.text.value}!');
/// });
///
/// // Programmatically update
/// nameInput.text.value = 'John';
///
/// // Don't forget to dispose
/// nameInput.dispose();
/// ```
class SignalTextController {
  final TextEditingController _controller;
  final Signal<String> _text;
  final Signal<TextSelection> _selection;
  late final Computed<bool> _isEmpty;
  late final Computed<bool> _isNotEmpty;
  late final Computed<int> _length;
  late final Effect _syncEffect;
  bool _isDisposed = false;
  bool _isSyncing = false;

  /// Creates a [SignalTextController] with optional initial text.
  SignalTextController({String? text})
      : _controller = TextEditingController(text: text),
        _text = signals.signal(text ?? ''),
        _selection = signals.signal(const TextSelection.collapsed(offset: 0)) {
    _initComputeds();
    _setupSync();
  }

  /// Creates a [SignalTextController] from an existing [TextEditingController].
  SignalTextController.fromController(TextEditingController controller)
      : _controller = controller,
        _text = signals.signal(controller.text),
        _selection = signals.signal(controller.selection) {
    _initComputeds();
    _setupSync();
  }

  void _initComputeds() {
    _isEmpty = signals.computed((_) => _text.value.isEmpty);
    _isNotEmpty = signals.computed((_) => _text.value.isNotEmpty);
    _length = signals.computed((_) => _text.value.length);
  }

  void _setupSync() {
    // Listen to controller changes and sync to signal
    _controller.addListener(_onControllerChange);

    // Listen to signal changes and sync to controller
    _syncEffect = signals.effect(() {
      final newText = _text.value;
      if (!_isSyncing && _controller.text != newText) {
        _isSyncing = true;
        _controller.text = newText;
        _isSyncing = false;
      }
    });
  }

  void _onControllerChange() {
    if (_isDisposed || _isSyncing) return;
    _isSyncing = true;
    _text.value = _controller.text;
    _selection.value = _controller.selection;
    _isSyncing = false;
  }

  /// The underlying [TextEditingController].
  TextEditingController get controller => _controller;

  /// The text value as a signal.
  Signal<String> get text => _text;

  /// The selection as a signal.
  Signal<TextSelection> get selection => _selection;

  /// A computed that returns whether the text is empty.
  Computed<bool> get isEmpty => _isEmpty;

  /// A computed that returns whether the text is not empty.
  Computed<bool> get isNotEmpty => _isNotEmpty;

  /// A computed that returns the text length.
  Computed<int> get length => _length;

  /// Clears the text.
  void clear() {
    _text.value = '';
  }

  /// Disposes the controller and stops syncing.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller.removeListener(_onControllerChange);
    _syncEffect.stop();
    _controller.dispose();
  }
}

/// A reactive wrapper around [ScrollController].
///
/// Provides signals for scroll position, direction, and common scroll states.
///
/// Example:
/// ```dart
/// final scrollSignal = SignalScrollController();
///
/// // In your widget
/// ListView.builder(
///   controller: scrollSignal.controller,
///   itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
/// );
///
/// // Show/hide FAB based on scroll position
/// Watch(builder: (context, _) {
///   if (scrollSignal.showBackToTop.value) {
///     return FloatingActionButton(
///       onPressed: scrollSignal.animateToTop,
///       child: Icon(Icons.arrow_upward),
///     );
///   }
///   return SizedBox.shrink();
/// });
///
/// // Don't forget to dispose
/// scrollSignal.dispose();
/// ```
class SignalScrollController {
  final ScrollController _controller;
  final Signal<double> _offset;
  final Signal<ScrollDirection> _direction;
  final Signal<bool> _isScrolling;
  final double _showBackToTopThreshold;
  late final Computed<bool> _showBackToTop;
  late final Computed<bool> _isAtTop;
  late final Computed<bool> _isAtBottom;
  late final Computed<double> _scrollProgress;
  double _lastOffset = 0;
  bool _isDisposed = false;

  /// Creates a [SignalScrollController] with optional initial offset.
  ///
  /// [showBackToTopThreshold] sets the scroll offset threshold for showing
  /// the "back to top" button (default: 200).
  SignalScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    double showBackToTopThreshold = 200.0,
  })  : _controller = ScrollController(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
        ),
        _offset = signals.signal(initialScrollOffset),
        _direction = signals.signal(ScrollDirection.idle),
        _isScrolling = signals.signal(false),
        _showBackToTopThreshold = showBackToTopThreshold,
        _lastOffset = initialScrollOffset {
    _initComputeds();
    _setupListeners();
  }

  /// Creates a [SignalScrollController] from an existing [ScrollController].
  SignalScrollController.fromController(
    ScrollController controller, {
    double showBackToTopThreshold = 200.0,
  })  : _controller = controller,
        _offset = signals.signal(controller.hasClients ? controller.offset : 0),
        _direction = signals.signal(ScrollDirection.idle),
        _isScrolling = signals.signal(false),
        _showBackToTopThreshold = showBackToTopThreshold,
        _lastOffset = controller.hasClients ? controller.offset : 0 {
    _initComputeds();
    _setupListeners();
  }

  void _initComputeds() {
    _showBackToTop =
        signals.computed((_) => _offset.value > _showBackToTopThreshold);
    _isAtTop = signals.computed((_) => _offset.value <= 0);
    _isAtBottom = signals.computed((_) {
      if (!_controller.hasClients) return false;
      final maxScroll = _controller.position.maxScrollExtent;
      return _offset.value >= maxScroll;
    });
    _scrollProgress = signals.computed((_) {
      if (!_controller.hasClients) return 0.0;
      final maxScroll = _controller.position.maxScrollExtent;
      if (maxScroll == 0) return 0.0;
      return (_offset.value / maxScroll).clamp(0.0, 1.0);
    });
  }

  void _setupListeners() {
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isDisposed || !_controller.hasClients) return;

    final currentOffset = _controller.offset;
    _offset.value = currentOffset;

    // Determine scroll direction
    if (currentOffset > _lastOffset) {
      _direction.value = ScrollDirection.forward; // scrolling down
    } else if (currentOffset < _lastOffset) {
      _direction.value = ScrollDirection.reverse; // scrolling up
    }
    _lastOffset = currentOffset;
  }

  /// The underlying [ScrollController].
  ScrollController get controller => _controller;

  /// The current scroll offset as a signal.
  Signal<double> get offset => _offset;

  /// The current scroll direction as a signal.
  Signal<ScrollDirection> get direction => _direction;

  /// Whether the user is currently scrolling.
  Signal<bool> get isScrolling => _isScrolling;

  /// A computed that returns whether to show the "back to top" button.
  Computed<bool> get showBackToTop => _showBackToTop;

  /// A computed that returns whether the scroll is at the top.
  Computed<bool> get isAtTop => _isAtTop;

  /// A computed that returns whether the scroll is at the bottom.
  Computed<bool> get isAtBottom => _isAtBottom;

  /// A computed that returns the scroll progress (0.0 to 1.0).
  Computed<double> get scrollProgress => _scrollProgress;

  /// Animates to the top of the scroll view.
  Future<void> animateToTop({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) async {
    if (_controller.hasClients) {
      await _controller.animateTo(0, duration: duration, curve: curve);
    }
  }

  /// Animates to a specific offset.
  Future<void> animateTo(
    double offset, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) async {
    if (_controller.hasClients) {
      await _controller.animateTo(offset, duration: duration, curve: curve);
    }
  }

  /// Jumps to the top of the scroll view.
  void jumpToTop() {
    if (_controller.hasClients) {
      _controller.jumpTo(0);
    }
  }

  /// Jumps to a specific offset.
  void jumpTo(double offset) {
    if (_controller.hasClients) {
      _controller.jumpTo(offset);
    }
  }

  /// Disposes the controller.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller.removeListener(_onScroll);
    _controller.dispose();
  }
}

/// Scroll direction for [SignalScrollController].
enum ScrollDirection {
  /// Not scrolling.
  idle,

  /// Scrolling down (content moving up).
  forward,

  /// Scrolling up (content moving down).
  reverse,
}

/// A reactive wrapper around [FocusNode].
///
/// Provides a signal for focus state.
///
/// Example:
/// ```dart
/// final focusSignal = SignalFocusNode();
///
/// // In your widget
/// TextField(focusNode: focusSignal.focusNode);
///
/// // React to focus changes
/// Watch(builder: (context, _) {
///   return Container(
///     decoration: BoxDecoration(
///       border: Border.all(
///         color: focusSignal.hasFocus.value ? Colors.blue : Colors.grey,
///       ),
///     ),
///     child: // ...
///   );
/// });
///
/// // Don't forget to dispose
/// focusSignal.dispose();
/// ```
class SignalFocusNode {
  final FocusNode _focusNode;
  final Signal<bool> _hasFocus;
  bool _isDisposed = false;

  /// Creates a [SignalFocusNode] with optional focus node options.
  SignalFocusNode({
    String? debugLabel,
    FocusOnKeyEventCallback? onKeyEvent,
    bool skipTraversal = false,
    bool canRequestFocus = true,
    bool descendantsAreFocusable = true,
    bool descendantsAreTraversable = true,
  })  : _focusNode = FocusNode(
          debugLabel: debugLabel,
          onKeyEvent: onKeyEvent,
          skipTraversal: skipTraversal,
          canRequestFocus: canRequestFocus,
          descendantsAreFocusable: descendantsAreFocusable,
          descendantsAreTraversable: descendantsAreTraversable,
        ),
        _hasFocus = signals.signal(false) {
    _setupListener();
  }

  /// Creates a [SignalFocusNode] from an existing [FocusNode].
  SignalFocusNode.fromNode(FocusNode node)
      : _focusNode = node,
        _hasFocus = signals.signal(node.hasFocus) {
    _setupListener();
  }

  void _setupListener() {
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isDisposed) return;
    _hasFocus.value = _focusNode.hasFocus;
  }

  /// The underlying [FocusNode].
  FocusNode get focusNode => _focusNode;

  /// Whether the node has focus as a signal.
  Signal<bool> get hasFocus => _hasFocus;

  /// Requests focus for this node.
  void requestFocus() {
    _focusNode.requestFocus();
  }

  /// Removes focus from this node.
  void unfocus({UnfocusDisposition disposition = UnfocusDisposition.scope}) {
    _focusNode.unfocus(disposition: disposition);
  }

  /// Disposes the focus node.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
  }
}

/// A reactive wrapper around [TabController].
///
/// Provides signals for the current tab index and animation value.
///
/// Note: This requires a [TickerProvider] (typically from a [State] with
/// [TickerProviderStateMixin] or [SingleTickerProviderStateMixin]).
///
/// Example:
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with SingleTickerProviderStateMixin {
///   late final SignalTabController tabSignal;
///
///   @override
///   void initState() {
///     super.initState();
///     tabSignal = SignalTabController(length: 3, vsync: this);
///   }
///
///   @override
///   void dispose() {
///     tabSignal.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(children: [
///       TabBar(controller: tabSignal.controller, tabs: [...]),
///       // React to tab changes
///       Watch(builder: (context, _) {
///         return Text('Current tab: ${tabSignal.index.value}');
///       }),
///       Expanded(
///         child: TabBarView(controller: tabSignal.controller, children: [...]),
///       ),
///     ]);
///   }
/// }
/// ```
class SignalTabController {
  final TabController _controller;
  final Signal<int> _index;
  final Signal<double> _animation;
  late final Computed<bool> _isAnimating;
  bool _isDisposed = false;

  /// Creates a [SignalTabController].
  SignalTabController({
    required int length,
    required TickerProvider vsync,
    int initialIndex = 0,
    Duration? animationDuration,
  })  : _controller = TabController(
          length: length,
          vsync: vsync,
          initialIndex: initialIndex,
          animationDuration: animationDuration,
        ),
        _index = signals.signal(initialIndex),
        _animation = signals.signal(initialIndex.toDouble()) {
    _initComputeds();
    _setupListeners();
  }

  /// Creates a [SignalTabController] from an existing [TabController].
  SignalTabController.fromController(TabController controller)
      : _controller = controller,
        _index = signals.signal(controller.index),
        _animation = signals.signal(controller.animation?.value ?? 0) {
    _initComputeds();
    _setupListeners();
  }

  void _initComputeds() {
    _isAnimating = signals.computed((_) => _controller.indexIsChanging);
  }

  void _setupListeners() {
    _controller.addListener(_onTabChange);
    _controller.animation?.addListener(_onAnimationChange);
  }

  void _onTabChange() {
    if (_isDisposed) return;
    _index.value = _controller.index;
  }

  void _onAnimationChange() {
    if (_isDisposed) return;
    _animation.value = _controller.animation?.value ?? 0;
  }

  /// The underlying [TabController].
  TabController get controller => _controller;

  /// The current tab index as a signal.
  Signal<int> get index => _index;

  /// The animation value as a signal (useful for custom animations).
  Signal<double> get animation => _animation;

  /// The number of tabs.
  int get length => _controller.length;

  /// A computed that returns whether the controller is animating.
  Computed<bool> get isAnimating => _isAnimating;

  /// Animates to a specific tab index.
  void animateTo(
    int index, {
    Duration? duration,
    Curve curve = Curves.ease,
  }) {
    _controller.animateTo(index, duration: duration, curve: curve);
  }

  /// Disposes the controller.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller.removeListener(_onTabChange);
    _controller.animation?.removeListener(_onAnimationChange);
    _controller.dispose();
  }
}

/// A reactive wrapper around [PageController].
///
/// Provides signals for the current page and viewport fraction.
///
/// Example:
/// ```dart
/// final pageSignal = SignalPageController();
///
/// // In your widget
/// PageView(
///   controller: pageSignal.controller,
///   children: [Page1(), Page2(), Page3()],
/// );
///
/// // React to page changes
/// Watch(builder: (context, _) {
///   return Text('Page ${pageSignal.page.value.round() + 1}');
/// });
///
/// // Dots indicator
/// Watch(builder: (context, _) {
///   return DotsIndicator(
///     currentPage: pageSignal.page.value,
///     totalPages: 3,
///   );
/// });
///
/// // Don't forget to dispose
/// pageSignal.dispose();
/// ```
class SignalPageController {
  final PageController _controller;
  final Signal<double> _page;
  late final Computed<int> _currentPage;
  bool _isDisposed = false;

  /// Creates a [SignalPageController].
  SignalPageController({
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
  })  : _controller = PageController(
          initialPage: initialPage,
          keepPage: keepPage,
          viewportFraction: viewportFraction,
        ),
        _page = signals.signal(initialPage.toDouble()) {
    _initComputeds();
    _setupListener();
  }

  /// Creates a [SignalPageController] from an existing [PageController].
  SignalPageController.fromController(PageController controller)
      : _controller = controller,
        _page =
            signals.signal(controller.hasClients ? controller.page ?? 0 : 0) {
    _initComputeds();
    _setupListener();
  }

  void _initComputeds() {
    _currentPage = signals.computed((_) => _page.value.round());
  }

  void _setupListener() {
    _controller.addListener(_onPageChange);
  }

  void _onPageChange() {
    if (_isDisposed || !_controller.hasClients) return;
    _page.value = _controller.page ?? 0;
  }

  /// The underlying [PageController].
  PageController get controller => _controller;

  /// The current page as a signal (can be fractional during animation).
  Signal<double> get page => _page;

  /// A computed that returns the current page index (rounded).
  Computed<int> get currentPage => _currentPage;

  /// Animates to a specific page.
  Future<void> animateToPage(
    int page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) async {
    if (_controller.hasClients) {
      await _controller.animateToPage(page, duration: duration, curve: curve);
    }
  }

  /// Jumps to a specific page.
  void jumpToPage(int page) {
    if (_controller.hasClients) {
      _controller.jumpToPage(page);
    }
  }

  /// Animates to the next page.
  Future<void> nextPage({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) async {
    if (_controller.hasClients) {
      await _controller.nextPage(duration: duration, curve: curve);
    }
  }

  /// Animates to the previous page.
  Future<void> previousPage({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) async {
    if (_controller.hasClients) {
      await _controller.previousPage(duration: duration, curve: curve);
    }
  }

  /// Disposes the controller.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller.removeListener(_onPageChange);
    _controller.dispose();
  }
}
