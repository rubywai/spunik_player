import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/material.dart';

class BasicPlayerPage extends StatefulWidget {
  @override
  _BasicPlayerPageState createState() => _BasicPlayerPageState();
}

class _BasicPlayerPageState extends State<BasicPlayerPage> {
  late BetterPlayerController _controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Basic player"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Basic player created with the simplest factory method. Shows video from URL.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer.network(
              Constants.forBiggerBlazesUrl,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Next player shows video from file.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: Utils.getFileUrl(Constants.fileTestVideoUrl),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.data != null) {
                return FutureBuilder<BetterPlayerController>(
                  future: _getController(),
                  builder: (context,snapshot){
                    if(snapshot.hasData){
                      return AspectRatio(
                        aspectRatio: 16 / 9,
                        child: BetterPlayer(controller: snapshot.data!),
                      );
                    }
                    return  Center(
                      child: Text('${snapshot.data}'),
                    );
                  },
                );
              } else {
                return const SizedBox();
              }
            },
          )
        ],
      ),
    );
  }
  Future<BetterPlayerController> _getController() async{
    var file = File(await Utils.getFileUrl(Constants.fileTestVideoUrl));
    BetterPlayerDataSource betterPlayerDataSource =
    BetterPlayerDataSource(BetterPlayerDataSourceType.file, file.path,);
    BetterPlayerConfiguration betterPlayerConfiguration =   BetterPlayerConfiguration(
        fit: BoxFit.contain,
        fullScreenByDefault: false,
        autoPlay: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.material,
            overflowMenuCustomItems: [],
            enableOverflowMenu: false,
            enableQualities: false,
            enablePlaybackSpeed: false,
            enableAudioTracks: false,
            enableSubtitles: false,
            muteIcon: Icons.volume_up_sharp,
            unMuteIcon: Icons.volume_off
        )
    );
    _controller = BetterPlayerController(betterPlayerConfiguration);
    _controller.setupDataSource(betterPlayerDataSource);
    return _controller;
  }
}
