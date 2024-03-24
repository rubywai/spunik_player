import 'dart:async';
import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/widget/sputnik_inkwell.dart';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'better_player_tv_progress_bar.dart';

class BetterPlayerMaterialTVControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;


  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerMaterialTVControls({
    Key? key,
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerMaterialTVControlsState();
  }
}

class _BetterPlayerMaterialTVControlsState
    extends BetterPlayerControlsState<BetterPlayerMaterialTVControls> {
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _displayTapped = false;
  bool _wasLoading = false;
  VideoPlayerController? _controller;
  BetterPlayerController? _betterPlayerController;
  StreamSubscription? _controlsVisibilityStreamSubscription;
  bool _controlVisible = true;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return buildLTRDirectionality(_buildMainWidget());
  }

  ///Builds main widget of the controls.
  Widget _buildMainWidget() {
    _wasLoading = isLoading(_latestValue);
    if (_latestValue?.hasError == true) {
      return Container(
        color: Colors.black,
        child: _buildErrorWidget(),
      );
    }
    return GestureDetector(
      onTap: (){
        if(_controlVisible){
          _onPlayerHide();
        }
        else{
          _onPlayerShowWithTimer();
        }
      },
      child: AbsorbPointer(
        absorbing: !_controlVisible,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_wasLoading) Center(child: _buildLoadingWidget()),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _onPlayerShowWithTimer();
  }

  void _dispose() {
    _controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;
    _latestValue = _controller!.value;

    if (_oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildErrorWidget() {
    final errorBuilder =
        _betterPlayerController!.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
          context,
          _betterPlayerController!
              .videoPlayerController!.value.errorDescription);
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: _controlsConfiguration.iconsColor,
              size: 42,
            ),
            Text(
              _betterPlayerController!.translations.generalDefaultError,
              style: textStyle,
            ),
            if (_controlsConfiguration.enableRetry)
              TextButton(
                onPressed: () {
                  _betterPlayerController!.retryDataSource();
                },
                child: Text(
                  _betterPlayerController!.translations.generalRetry,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
      );
    }
  }

  Widget _buildMoreButton() {
    return SputnikInkWell(
      onTap: () {
        showQualitiesSelectionWidget();
      },
      child: Icon(
        _controlsConfiguration.qualitiesIcon,
        color: _controlsConfiguration.iconsColor,
      ),
    );
  }

  Widget _buildBottomBar() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    return _controlVisible ? Container(
      color: Colors.grey,
      height: _controlsConfiguration.controlBarHeight + 20.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            flex: 75,
            child: Row(
              children: [
                SputnikInkWell(
                  onTap: () {
                    _onPlayerHide();
                  },
                  child: Icon(Icons.close,color: Colors.white,),
                ),
                _buildPlayPause(_controller!),
                _controlsConfiguration.enableProgressText
                    ? _buildPosition()
                    : const SizedBox(),
                _buildMoreButton(),
                if (_controlsConfiguration.enableMute)
                  _buildMuteButton(_controller)
                else
                  const SizedBox(),
              ],
            ),
          ),
          if (_betterPlayerController!.isLiveStream())
            const SizedBox()
          else
            _controlsConfiguration.enableProgressBar
                ? _buildProgressBar()
                : const SizedBox(),
        ],
      ),
    ) : KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (key){
          if(!_controlVisible){
            _onPlayerShow();
          }
        },
        child: SizedBox.shrink());
  }

  Widget _buildMuteButton(
    VideoPlayerController? controller,
  ) {
    return SputnikInkWell(
      onTap: () {
        cancelAndRestartTimer();
        if (_latestValue!.volume == 0) {
          _betterPlayerController!.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller!.value.volume;
          _betterPlayerController!.setVolume(0.0);
        }
      },
      child: Icon(
        (_latestValue != null && _latestValue!.volume > 0)
            ? _controlsConfiguration.muteIcon
            : _controlsConfiguration.unMuteIcon,
        color: _controlsConfiguration.iconsColor,
      ),
    );
  }

  Widget _buildPlayPause(VideoPlayerController controller) {
    return SputnikInkWell(
      onTap: _onPlayPause,
      child: Container(
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          controller.value.isPlaying
              ? _controlsConfiguration.pauseIcon
              : _controlsConfiguration.playIcon,
          color: _controlsConfiguration.iconsColor,
        ),
      ),
    );
  }

  Widget _buildPosition() {
    final position =
        _latestValue != null ? _latestValue!.position : Duration.zero;
    final duration = _latestValue != null && _latestValue!.duration != null
        ? _latestValue!.duration!
        : Duration.zero;
    return Padding(
      padding: _controlsConfiguration.enablePlayPause
          ? const EdgeInsets.only(right: 24)
          : const EdgeInsets.symmetric(horizontal: 22),
      child: RichText(
        text: TextSpan(
            text: BetterPlayerUtils.formatDuration(position),
            style: TextStyle(
              fontSize: 10.0,
              color: _controlsConfiguration.textColor,
              decoration: TextDecoration.none,
            ),
            children: <TextSpan>[
              TextSpan(
                text: ' / ${BetterPlayerUtils.formatDuration(duration)}',
                style: TextStyle(
                  fontSize: 10.0,
                  color: _controlsConfiguration.textColor,
                  decoration: TextDecoration.none,
                ),
              )
            ]),
      ),
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    // changePlayerControlsNotVisible(false);
    _displayTapped = true;
  }

  Future<void> _initialize() async {
    _controller!.addListener(_updateState);

    _updateState();

    if ((_controller!.value.isPlaying) ||
        _betterPlayerController!.betterPlayerConfiguration.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        // changePlayerControlsNotVisible(false);
      });
    }

    _controlsVisibilityStreamSubscription =
        _betterPlayerController!.controlsVisibilityStream.listen((state) {
      // changePlayerControlsNotVisible(!state);
      if (!controlsNotVisible) {
        cancelAndRestartTimer();
      }
    });
  }

  void _onPlayPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue!.position >= _latestValue!.duration!;
    }

    if (_controller!.value.isPlaying) {
      // changePlayerControlsNotVisible(false);
      _hideTimer?.cancel();
      _betterPlayerController!.pause();
    } else {
      cancelAndRestartTimer();

      if (!_controller!.value.initialized) {
      } else {
        if (isFinished) {
          _betterPlayerController!.seekTo(const Duration());
        }
        _betterPlayerController!.play();
        _betterPlayerController!.cancelNextVideoTimer();
      }
    }
  }

  void _startHideTimer() {
    if (_betterPlayerController!.controlsAlwaysVisible) {
      return;
    }
    // _hideTimer = Timer(const Duration(milliseconds: 3000), () {
    //   changePlayerControlsNotVisible(true);
    // });
  }

  void _updateState() {
    if (mounted) {
      if (!controlsNotVisible ||
          isVideoFinished(_controller!.value) ||
          _wasLoading ||
          isLoading(_controller!.value)) {
        setState(() {
          _latestValue = _controller!.value;
          if (isVideoFinished(_latestValue) &&
              _betterPlayerController?.isLiveStream() == false) {
            // changePlayerControlsNotVisible(false);
          }
        });
      }
    }
  }

  Widget _buildProgressBar() {
    return Expanded(
      flex: 40,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: BetterPlayerTVProgressBar(
          controller: _controller,
          betterPlayerController: _betterPlayerController,
          colors: BetterPlayerProgressColors(
              playedColor: _controlsConfiguration.progressBarPlayedColor,
              handleColor: _controlsConfiguration.progressBarHandleColor,
              bufferedColor: _controlsConfiguration.progressBarBufferedColor,
              backgroundColor:
                  _controlsConfiguration.progressBarBackgroundColor),
        ),
      ),
    );
  }

  Widget? _buildLoadingWidget() {
    if (_controlsConfiguration.loadingWidget != null) {
      return Container(
        color: _controlsConfiguration.controlBarColor,
        child: _controlsConfiguration.loadingWidget,
      );
    }

    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.loadingColor),
    );
  }

  void _onPlayerHide() {
    setState(() {
      _controlVisible = false;
    });
  }

  void _onPlayerShow() async {
    setState(() {
      _controlVisible = true;
    });
  }
  //hide after 3 second
  void _onPlayerShowWithTimer() async {
    setState(() {
      _controlVisible = true;
    });
    await Future.delayed(Duration(seconds: 3));
    _onPlayerHide();
  }
}
