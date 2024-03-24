import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../better_player.dart';

class BetterPlayerTVProgressBar extends StatefulWidget {
  final VideoPlayerController? controller;
  final BetterPlayerController? betterPlayerController;
  final BetterPlayerProgressColors colors;

  const BetterPlayerTVProgressBar({
    Key? key,
    required this.controller,
    required this.betterPlayerController,
    required this.colors,
  }) : super(key: key);

  @override
  _BetterPlayerTVProgressBarState createState() =>
      _BetterPlayerTVProgressBarState();
}

class _BetterPlayerTVProgressBarState
    extends State<BetterPlayerTVProgressBar> {
  double _currentSliderValue = 0.0;
  bool _hasFocus = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentSliderValue = _getInitialSliderValue();
    widget.controller!.addListener(_updateSliderValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller!.removeListener(_updateSliderValue);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  double _getInitialSliderValue() {
    if (widget.controller != null &&
        widget.controller!.value.duration != null &&
        widget.controller!.value.duration!.inMilliseconds > 0) {
      return widget.controller!.value.position.inMilliseconds /
          widget.controller!.value.duration!.inMilliseconds *
          100.0;
    }
    return 0.0;
  }

  void _updateSliderValue() {
    if(widget.controller!= null) {
      final position = widget.controller!.value.position.inMilliseconds;
      final duration = widget.controller!.value.duration!.inMilliseconds;
      setState(() {
        if(_currentSliderValue <= 100)
        _currentSliderValue = (position / duration) * 100.0;
      });
    }
  }

  void _seekToRelativePosition(double value) async {
    final duration = widget.controller!.value.duration;
    if (duration != null) {
      final position = duration * (value / 100.0);
      await widget.betterPlayerController!.seekTo(position);
    }
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: _hasFocus ? Colors.blue : Colors.transparent,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: KeyboardListener(
        onKeyEvent: (event){
          if(event.logicalKey == LogicalKeyboardKey.arrowUp){
            FocusScope.of(context).previousFocus();
          }
          else if(event.logicalKey == LogicalKeyboardKey.arrowDown){
           //do nothing
          }
        },
        focusNode: _focusNode,
        child: Slider(
          thumbColor: widget.colors.handlePaint.color,
          value: _currentSliderValue,
          max: 100,
          label: _currentSliderValue.round().toString(),
          onChanged: (double value) {
            setState(() {
              _currentSliderValue = value;
            });
            _seekToRelativePosition(value);
          },
        ),
      ),
    );
  }
}
