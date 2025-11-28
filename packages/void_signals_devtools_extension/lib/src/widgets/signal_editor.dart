import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/signal_info.dart';

/// A widget for editing signal values from DevTools.
class SignalEditor extends StatefulWidget {
  final SignalInfo signal;
  final Future<bool> Function(String newValue) onValueChanged;

  const SignalEditor({
    super.key,
    required this.signal,
    required this.onValueChanged,
  });

  @override
  State<SignalEditor> createState() => _SignalEditorState();
}

class _SignalEditorState extends State<SignalEditor> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.signal.value);
  }

  @override
  void didUpdateWidget(SignalEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.signal.value != oldWidget.signal.value) {
      _controller.text = widget.signal.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.signal.isEditable) {
      return _buildReadOnlyValue();
    }

    return _isEditing ? _buildEditor() : _buildValueDisplay();
  }

  Widget _buildReadOnlyValue() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              widget.signal.value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          Tooltip(
            message: 'This value type cannot be edited',
            child: Icon(
              Icons.lock_outline,
              size: 16,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              widget.signal.value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy value',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.signal.value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Value copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Edit value',
            onPressed: () => setState(() => _isEditing = true),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _error != null ? Colors.red : Colors.blue,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Enter new value',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                enabled: !_isLoading,
                onSubmitted: (_) => _applyChange(),
                autofocus: true,
              ),
              // Type hint
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Text(
                  'Type: ${widget.signal.type}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isEditing = false;
                        _error = null;
                        _controller.text = widget.signal.value;
                      });
                    },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isLoading ? null : _applyChange,
              child: const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _applyChange() async {
    final newValue = _controller.text;

    if (newValue == widget.signal.value) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await widget.onValueChanged(newValue);

      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Failed to update value. Check the value format.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
        });
      }
    }
  }
}

/// Quick value buttons for common types.
class QuickValueButtons extends StatelessWidget {
  final SignalInfo signal;
  final Future<bool> Function(String newValue) onValueChanged;

  const QuickValueButtons({
    super.key,
    required this.signal,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final type = signal.type.toLowerCase();

    if (type == 'bool') {
      return _buildBoolButtons();
    } else if (type == 'int' || type == 'double' || type == 'num') {
      return _buildNumberButtons();
    }

    return const SizedBox.shrink();
  }

  Widget _buildBoolButtons() {
    final currentValue = signal.value.toLowerCase() == 'true';

    return Row(
      children: [
        const Text(
          'Quick toggle:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Switch(
          value: currentValue,
          onChanged: (value) => onValueChanged(value.toString()),
        ),
      ],
    );
  }

  Widget _buildNumberButtons() {
    return Row(
      children: [
        const Text(
          'Quick actions:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.remove),
          tooltip: 'Decrement',
          onPressed: () => _incrementValue(-1),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Increment',
          onPressed: () => _incrementValue(1),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset to 0',
          onPressed: () => onValueChanged('0'),
        ),
      ],
    );
  }

  Future<void> _incrementValue(int delta) async {
    try {
      if (signal.type.toLowerCase() == 'int') {
        final current = int.parse(signal.value);
        await onValueChanged((current + delta).toString());
      } else {
        final current = double.parse(signal.value);
        await onValueChanged((current + delta).toString());
      }
    } catch (e) {
      // Ignore parse errors
    }
  }
}
