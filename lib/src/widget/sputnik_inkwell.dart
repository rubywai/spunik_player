import 'package:flutter/material.dart';

class SputnikInkWell extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool autoFocus;

  const SputnikInkWell({Key? key, required this.child, required this.onTap,this.autoFocus = false,}) : super(key: key);

  @override
  _SputnikInkWellState createState() => _SputnikInkWellState();
}

class _SputnikInkWellState extends State<SputnikInkWell> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      autofocus: widget.autoFocus,
      focusNode: _focusNode,
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isFocused ? Colors.blue : Colors.transparent,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: widget.child,
      ),
    );
  }
}
