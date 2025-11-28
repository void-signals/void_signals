import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/signal_info.dart';

/// Layout algorithm options for dependency graph.
enum GraphLayoutAlgorithm {
  layered,
  forceDirected,
  radial,
}

/// A visual graph showing dependencies between signals, computeds, and effects.
class DependencyGraphView extends StatefulWidget {
  final List<SignalInfo> signals;
  final List<ComputedInfo> computeds;
  final List<EffectInfo> effects;
  final void Function(String signalId)? onSignalSelected;
  final String? selectedSignalId;

  const DependencyGraphView({
    super.key,
    required this.signals,
    required this.computeds,
    required this.effects,
    this.onSignalSelected,
    this.selectedSignalId,
  });

  @override
  State<DependencyGraphView> createState() => _DependencyGraphViewState();
}

class _DependencyGraphViewState extends State<DependencyGraphView>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  String? _hoveredNodeId;
  final Map<String, Offset> _nodePositions = {};
  final Map<String, Offset> _nodeVelocities = {};
  GraphLayoutAlgorithm _layoutAlgorithm = GraphLayoutAlgorithm.layered;
  Timer? _layoutTimer;
  bool _isSimulating = false;
  bool _showDataFlow = false;
  Set<String> _highlightedPath = {};

  // Animation for data flow
  late AnimationController _dataFlowController;

  @override
  void initState() {
    super.initState();
    _dataFlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _computeLayout();
  }

  @override
  void didUpdateWidget(DependencyGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.signals != oldWidget.signals ||
        widget.computeds != oldWidget.computeds ||
        widget.effects != oldWidget.effects) {
      _computeLayout();
    }
  }

  void _computeLayout() {
    switch (_layoutAlgorithm) {
      case GraphLayoutAlgorithm.layered:
        _computeLayeredLayout();
        break;
      case GraphLayoutAlgorithm.forceDirected:
        _startForceDirectedLayout();
        break;
      case GraphLayoutAlgorithm.radial:
        _computeRadialLayout();
        break;
    }
  }

  void _computeLayeredLayout() {
    _nodePositions.clear();
    _isSimulating = false;
    _layoutTimer?.cancel();

    const horizontalSpacing = 200.0;
    const verticalSpacing = 100.0;
    const startX = 150.0;
    const startY = 100.0;

    // Place signals
    for (int i = 0; i < widget.signals.length; i++) {
      _nodePositions[widget.signals[i].id] = Offset(
        startX,
        startY + i * verticalSpacing,
      );
    }

    // Place computeds
    for (int i = 0; i < widget.computeds.length; i++) {
      _nodePositions[widget.computeds[i].id] = Offset(
        startX + horizontalSpacing,
        startY + i * verticalSpacing,
      );
    }

    // Place effects
    for (int i = 0; i < widget.effects.length; i++) {
      _nodePositions[widget.effects[i].id] = Offset(
        startX + 2 * horizontalSpacing,
        startY + i * verticalSpacing,
      );
    }

    if (mounted) setState(() {});
  }

  void _startForceDirectedLayout() {
    _layoutTimer?.cancel();

    // Initialize random positions if empty
    final random = math.Random();
    final allIds = [
      ...widget.signals.map((s) => s.id),
      ...widget.computeds.map((c) => c.id),
      ...widget.effects.map((e) => e.id),
    ];

    for (final id in allIds) {
      if (!_nodePositions.containsKey(id)) {
        _nodePositions[id] = Offset(
          200 + random.nextDouble() * 400,
          100 + random.nextDouble() * 300,
        );
      }
      _nodeVelocities[id] = Offset.zero;
    }

    _isSimulating = true;
    _layoutTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      _applyForces();
      setState(() {});
    });

    // Stop after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _layoutTimer?.cancel();
      _isSimulating = false;
      if (mounted) setState(() {});
    });
  }

  void _applyForces() {
    const repulsionForce = 5000.0;
    const attractionForce = 0.01;
    const damping = 0.9;
    const minDistance = 80.0;

    final allIds = _nodePositions.keys.toList();

    // Apply repulsion between all nodes
    for (int i = 0; i < allIds.length; i++) {
      for (int j = i + 1; j < allIds.length; j++) {
        final id1 = allIds[i];
        final id2 = allIds[j];
        final pos1 = _nodePositions[id1]!;
        final pos2 = _nodePositions[id2]!;

        final delta = pos2 - pos1;
        final distance = math.max(delta.distance, minDistance);
        final force = repulsionForce / (distance * distance);
        final direction = delta / distance;

        _nodeVelocities[id1] = _nodeVelocities[id1]! - direction * force;
        _nodeVelocities[id2] = _nodeVelocities[id2]! + direction * force;
      }
    }

    // Apply attraction along edges
    final edges = _getAllEdges();
    for (final edge in edges) {
      final pos1 = _nodePositions[edge.$1];
      final pos2 = _nodePositions[edge.$2];
      if (pos1 == null || pos2 == null) continue;

      final delta = pos2 - pos1;
      final distance = delta.distance;
      if (distance < 1) continue;

      final force = distance * attractionForce;
      final direction = delta / distance;

      _nodeVelocities[edge.$1] = _nodeVelocities[edge.$1]! + direction * force;
      _nodeVelocities[edge.$2] = _nodeVelocities[edge.$2]! - direction * force;
    }

    // Apply velocity and damping
    for (final id in allIds) {
      _nodeVelocities[id] = _nodeVelocities[id]! * damping;
      _nodePositions[id] = _nodePositions[id]! + _nodeVelocities[id]!;

      // Keep nodes in bounds
      final pos = _nodePositions[id]!;
      _nodePositions[id] = Offset(
        pos.dx.clamp(50, 700),
        pos.dy.clamp(50, 500),
      );
    }
  }

  List<(String, String)> _getAllEdges() {
    final edges = <(String, String)>[];

    for (final computed in widget.computeds) {
      for (final depId in computed.dependencyIds) {
        edges.add((depId, computed.id));
      }
    }

    for (final effect in widget.effects) {
      for (final depId in effect.dependencyIds) {
        edges.add((depId, effect.id));
      }
    }

    return edges;
  }

  void _computeRadialLayout() {
    _nodePositions.clear();
    _isSimulating = false;
    _layoutTimer?.cancel();

    final centerX = 350.0;
    final centerY = 250.0;

    // Center: signals
    // Ring 1: computeds
    // Ring 2: effects

    final signalRadius = 80.0;
    final computedRadius = 180.0;
    final effectRadius = 280.0;

    // Place signals in center
    for (int i = 0; i < widget.signals.length; i++) {
      final angle = (2 * math.pi * i) / math.max(widget.signals.length, 1);
      _nodePositions[widget.signals[i].id] = Offset(
        centerX + signalRadius * math.cos(angle),
        centerY + signalRadius * math.sin(angle),
      );
    }

    // Place computeds in ring 1
    for (int i = 0; i < widget.computeds.length; i++) {
      final angle = (2 * math.pi * i) / math.max(widget.computeds.length, 1);
      _nodePositions[widget.computeds[i].id] = Offset(
        centerX + computedRadius * math.cos(angle),
        centerY + computedRadius * math.sin(angle),
      );
    }

    // Place effects in ring 2
    for (int i = 0; i < widget.effects.length; i++) {
      final angle = (2 * math.pi * i) / math.max(widget.effects.length, 1);
      _nodePositions[widget.effects[i].id] = Offset(
        centerX + effectRadius * math.cos(angle),
        centerY + effectRadius * math.sin(angle),
      );
    }

    if (mounted) setState(() {});
  }

  void _highlightDependencyPath(String nodeId) {
    _highlightedPath.clear();
    _highlightedPath.add(nodeId);

    // Find all upstream dependencies
    void findUpstream(String id) {
      // Check if it's a computed
      for (final computed in widget.computeds) {
        if (computed.id == id) {
          for (final depId in computed.dependencyIds) {
            _highlightedPath.add(depId);
            findUpstream(depId);
          }
        }
      }
      // Check if it's an effect
      for (final effect in widget.effects) {
        if (effect.id == id) {
          for (final depId in effect.dependencyIds) {
            _highlightedPath.add(depId);
            findUpstream(depId);
          }
        }
      }
    }

    // Find all downstream dependents
    void findDownstream(String id) {
      // Find computeds that depend on this
      for (final computed in widget.computeds) {
        if (computed.dependencyIds.contains(id)) {
          _highlightedPath.add(computed.id);
          findDownstream(computed.id);
        }
      }
      // Find effects that depend on this
      for (final effect in widget.effects) {
        if (effect.dependencyIds.contains(id)) {
          _highlightedPath.add(effect.id);
        }
      }
    }

    findUpstream(nodeId);
    findDownstream(nodeId);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.signals.isEmpty &&
        widget.computeds.isEmpty &&
        widget.effects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No dependency data available'),
            SizedBox(height: 8),
            Text(
              'Signals, computeds, and effects will appear here\nonce they are created in your app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1),
        _buildLegend(),
        const Divider(height: 1),
        Expanded(
          child: AnimatedBuilder(
            animation: _dataFlowController,
            builder: (context, child) {
              return InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(500),
                minScale: 0.1,
                maxScale: 3.0,
                child: CustomPaint(
                  painter: _DependencyGraphPainter(
                    signals: widget.signals,
                    computeds: widget.computeds,
                    effects: widget.effects,
                    nodePositions: _nodePositions,
                    hoveredNodeId: _hoveredNodeId,
                    selectedNodeId: widget.selectedSignalId,
                    highlightedPath: _highlightedPath,
                    showDataFlow: _showDataFlow,
                    dataFlowProgress: _dataFlowController.value,
                  ),
                  child: Stack(
                    children: [
                      // Signals
                      ...widget.signals.map((signal) {
                        final position = _nodePositions[signal.id];
                        if (position == null) return const SizedBox.shrink();
                        return _buildNode(
                          id: signal.id,
                          label: signal.label ?? signal.name,
                          value: signal.value,
                          position: position,
                          color: signal.color,
                          icon: signal.icon,
                          hookSource: signal.isFromHook
                              ? signal.source.displayName
                              : null,
                          isSelected: widget.selectedSignalId == signal.id,
                          isInPath: _highlightedPath.contains(signal.id),
                        );
                      }),
                      // Computeds
                      ...widget.computeds.map((computed) {
                        final position = _nodePositions[computed.id];
                        if (position == null) return const SizedBox.shrink();
                        return _buildNode(
                          id: computed.id,
                          label: computed.label ?? computed.name,
                          value: computed.value,
                          position: position,
                          color: Colors.green,
                          icon: Icons.functions,
                          isSelected: widget.selectedSignalId == computed.id,
                          isInPath: _highlightedPath.contains(computed.id),
                          dependencyCount: computed.dependencyIds.length,
                        );
                      }),
                      // Effects
                      ...widget.effects.map((effect) {
                        final position = _nodePositions[effect.id];
                        if (position == null) return const SizedBox.shrink();
                        return _buildNode(
                          id: effect.id,
                          label: effect.label ?? effect.name,
                          value: 'runs: ${effect.runCount}',
                          position: position,
                          color: Colors.orange,
                          icon: Icons.bolt,
                          isSelected: widget.selectedSignalId == effect.id,
                          isInPath: _highlightedPath.contains(effect.id),
                          dependencyCount: effect.dependencyIds.length,
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isSimulating) _buildSimulatingIndicator(),
      ],
    );
  }

  Widget _buildSimulatingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blue.withOpacity(0.1),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Optimizing layout...'),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Text('Layout: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          SegmentedButton<GraphLayoutAlgorithm>(
            segments: const [
              ButtonSegment(
                value: GraphLayoutAlgorithm.layered,
                label: Text('Layered'),
                icon: Icon(Icons.view_week, size: 16),
              ),
              ButtonSegment(
                value: GraphLayoutAlgorithm.forceDirected,
                label: Text('Force'),
                icon: Icon(Icons.scatter_plot, size: 16),
              ),
              ButtonSegment(
                value: GraphLayoutAlgorithm.radial,
                label: Text('Radial'),
                icon: Icon(Icons.radio_button_checked, size: 16),
              ),
            ],
            selected: {_layoutAlgorithm},
            onSelectionChanged: (selected) {
              setState(() => _layoutAlgorithm = selected.first);
              _computeLayout();
            },
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('Data Flow'),
            selected: _showDataFlow,
            onSelected: (selected) {
              setState(() => _showDataFlow = selected);
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh layout',
            onPressed: _computeLayout,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Fit to screen',
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear selection',
            onPressed: () {
              setState(() {
                _highlightedPath.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Signal', Colors.blue, Icons.radio_button_checked),
          const SizedBox(width: 16),
          _buildLegendItem('Hook Signal', Colors.purple, Icons.anchor),
          const SizedBox(width: 16),
          _buildLegendItem('Computed', Colors.green, Icons.functions),
          const SizedBox(width: 16),
          _buildLegendItem('Effect', Colors.orange, Icons.bolt),
          const SizedBox(width: 24),
          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 24),
          _buildLegendItem('Dependency', Colors.grey, Icons.arrow_forward),
          if (_showDataFlow) ...[
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withOpacity(0.3), Colors.blue],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Data Flow', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildNode({
    required String id,
    required String label,
    required String value,
    required Offset position,
    required Color color,
    required IconData icon,
    String? hookSource,
    bool isSelected = false,
    bool isInPath = false,
    int dependencyCount = 0,
  }) {
    const nodeWidth = 160.0;
    final nodeHeight = hookSource != null ? 80.0 : 70.0;

    final isHighlighted = _hoveredNodeId == id || isSelected || isInPath;
    final opacity = _highlightedPath.isNotEmpty && !isInPath ? 0.3 : 1.0;

    return Positioned(
      left: position.dx - nodeWidth / 2,
      top: position.dy - nodeHeight / 2,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: () {
            widget.onSignalSelected?.call(id);
            _highlightDependencyPath(id);
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredNodeId = id),
            onExit: (_) => setState(() => _hoveredNodeId = null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: nodeWidth,
              height: nodeHeight,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? color.withOpacity(0.15)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted ? color : color.withOpacity(0.5),
                  width: isHighlighted ? 2.5 : 1.5,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isHighlighted ? color : null,
                                ),
                              ),
                            ),
                            if (dependencyCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$dependencyCount deps',
                                  style: const TextStyle(fontSize: 8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (hookSource != null)
                          Text(
                            hookSource,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.purple.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _layoutTimer?.cancel();
    _dataFlowController.dispose();
    super.dispose();
  }
}

class _DependencyGraphPainter extends CustomPainter {
  final List<SignalInfo> signals;
  final List<ComputedInfo> computeds;
  final List<EffectInfo> effects;
  final Map<String, Offset> nodePositions;
  final String? hoveredNodeId;
  final String? selectedNodeId;
  final Set<String> highlightedPath;
  final bool showDataFlow;
  final double dataFlowProgress;

  _DependencyGraphPainter({
    required this.signals,
    required this.computeds,
    required this.effects,
    required this.nodePositions,
    this.hoveredNodeId,
    this.selectedNodeId,
    this.highlightedPath = const {},
    this.showDataFlow = false,
    this.dataFlowProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw edges from computeds to their dependencies
    for (final computed in computeds) {
      final targetPos = nodePositions[computed.id];
      if (targetPos == null) continue;

      for (final depId in computed.dependencyIds) {
        final sourcePos = nodePositions[depId];
        if (sourcePos == null) continue;

        final isHighlighted = hoveredNodeId == computed.id ||
            hoveredNodeId == depId ||
            selectedNodeId == computed.id ||
            selectedNodeId == depId ||
            (highlightedPath.contains(computed.id) &&
                highlightedPath.contains(depId));

        final isInPath = highlightedPath.contains(computed.id) &&
            highlightedPath.contains(depId);

        final opacity = highlightedPath.isNotEmpty && !isInPath ? 0.15 : 1.0;

        paint.color =
            Colors.green.withOpacity(isHighlighted ? 0.8 : 0.3 * opacity);
        paint.strokeWidth = isHighlighted ? 3.0 : 1.5;

        _drawArrow(canvas, sourcePos, targetPos, paint);

        if (showDataFlow && isHighlighted) {
          _drawDataFlowAnimation(canvas, sourcePos, targetPos, Colors.green);
        }
      }
    }

    // Draw edges from effects to their dependencies
    for (final effect in effects) {
      final targetPos = nodePositions[effect.id];
      if (targetPos == null) continue;

      for (final depId in effect.dependencyIds) {
        final sourcePos = nodePositions[depId];
        if (sourcePos == null) continue;

        final isHighlighted = hoveredNodeId == effect.id ||
            hoveredNodeId == depId ||
            selectedNodeId == effect.id ||
            selectedNodeId == depId ||
            (highlightedPath.contains(effect.id) &&
                highlightedPath.contains(depId));

        final isInPath = highlightedPath.contains(effect.id) &&
            highlightedPath.contains(depId);

        final opacity = highlightedPath.isNotEmpty && !isInPath ? 0.15 : 1.0;

        paint.color =
            Colors.orange.withOpacity(isHighlighted ? 0.8 : 0.3 * opacity);
        paint.strokeWidth = isHighlighted ? 3.0 : 1.5;

        _drawArrow(canvas, sourcePos, targetPos, paint);

        if (showDataFlow && isHighlighted) {
          _drawDataFlowAnimation(canvas, sourcePos, targetPos, Colors.orange);
        }
      }
    }
  }

  void _drawDataFlowAnimation(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
  ) {
    final direction = to - from;
    final distance = direction.distance;
    if (distance < 1) return;

    // Draw multiple dots flowing along the edge
    const dotCount = 3;
    for (int i = 0; i < dotCount; i++) {
      final progress = (dataFlowProgress + i / dotCount) % 1.0;
      final dotPosition = from + direction * progress;

      canvas.drawCircle(
        dotPosition,
        4.0,
        Paint()
          ..color = color.withOpacity(1.0 - progress * 0.5)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    // Calculate offset to account for node size
    const nodeRadius = 35.0;
    final direction = (to - from);
    final distance = direction.distance;
    if (distance < nodeRadius * 2) return;

    final normalizedDir = direction / distance;
    final adjustedFrom = from + normalizedDir * nodeRadius;
    final adjustedTo = to - normalizedDir * nodeRadius;

    // Draw curved line for better visual
    final controlPoint = Offset(
      (adjustedFrom.dx + adjustedTo.dx) / 2,
      (adjustedFrom.dy + adjustedTo.dy) / 2 - 20,
    );

    final path = Path()
      ..moveTo(adjustedFrom.dx, adjustedFrom.dy)
      ..quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        adjustedTo.dx,
        adjustedTo.dy,
      );

    canvas.drawPath(path, paint);

    // Draw the arrowhead
    const arrowSize = 12.0;
    final endDirection = (adjustedTo - controlPoint);
    final angle = math.atan2(endDirection.dy, endDirection.dx);

    final arrowPoint1 = Offset(
      adjustedTo.dx - arrowSize * math.cos(angle - math.pi / 6),
      adjustedTo.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    final arrowPoint2 = Offset(
      adjustedTo.dx - arrowSize * math.cos(angle + math.pi / 6),
      adjustedTo.dy - arrowSize * math.sin(angle + math.pi / 6),
    );

    final arrowPath = Path()
      ..moveTo(adjustedTo.dx, adjustedTo.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _DependencyGraphPainter oldDelegate) {
    return hoveredNodeId != oldDelegate.hoveredNodeId ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        highlightedPath != oldDelegate.highlightedPath ||
        showDataFlow != oldDelegate.showDataFlow ||
        dataFlowProgress != oldDelegate.dataFlowProgress ||
        signals != oldDelegate.signals ||
        computeds != oldDelegate.computeds ||
        effects != oldDelegate.effects ||
        nodePositions != oldDelegate.nodePositions;
  }
}
