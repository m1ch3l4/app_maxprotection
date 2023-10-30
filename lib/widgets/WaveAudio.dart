import 'dart:async';
import 'dart:io';

import 'package:app_maxprotection/utils/HexColor.dart';
import 'package:app_maxprotection/widgets/constants.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WaveAudio extends StatefulWidget {
  final bool? isSender;
  final int? index;
  final String? path;
  final double? width;
  final Directory? appDirectory;

  static _WaveBubbleState? state;

  const WaveAudio({
    this.appDirectory,
    this.width,
    this.index,
    this.isSender = false,
    this.path,
  });

  @override
  State<WaveAudio> createState(){
    state = _WaveBubbleState();
    return state!;
  }
}

class _WaveBubbleState extends State<WaveAudio> {
  File? file;

  PlayerController? controller;
  StreamSubscription<PlayerState>? playerStateSubscription;

  final playerWaveStyle = PlayerWaveStyle(
    fixedWaveColor: HexColor(Constants.darkGrey),
    liveWaveColor: HexColor(Constants.greyContainer),
    spacing: 6,
  );

  @override
  void initState() {
    super.initState();
    controller = PlayerController();
    _preparePlayer();
    playerStateSubscription = controller!.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  void _preparePlayer() async {
    // Opening file from assets folder
    if (widget.index != null) {
      file = File('${widget.appDirectory!.path}/audio${widget.index}.mp3');
      await file!.writeAsBytes(
          (await rootBundle.load('assets/audios/audio${widget.index}.mp3'))
              .buffer
              .asUint8List());
    }
    if (widget.index == null && widget.path == null && file?.path == null) {
      return;
    }
    // Prepare player with extracting waveform if index is even.
    controller!.preparePlayer(
      path: widget.path ?? file!.path,
      shouldExtractWaveform: widget.index?.isEven ?? true,
    );
    // Extracting waveform separately if index is odd.
    if (widget.index?.isOdd ?? false) {
      controller!
          .extractWaveformData(
        path: widget.path ?? file!.path,
        noOfSamples:
        playerWaveStyle.getSamplesForWidth(widget.width ?? 200),
      )
          .then((waveformData) => debugPrint(waveformData.toString()));
    }
  }

  @override
  void dispose() {
    playerStateSubscription!.cancel();
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.path != null || file?.path != null
        ? Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.only(
          bottom: 6,
          right: widget.isSender! ? 0 : 10,
          top: 6,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        /**decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: widget.isSender
              ? const Color(0xFF276bfd)
              : const Color(0xFF343145),
        ),**/
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /**if (!controller.playerState.isStopped)
              IconButton(
                onPressed: () async {
                  controller.playerState.isPlaying
                      ? await controller.pausePlayer()
                      : await controller.startPlayer(
                    finishMode: FinishMode.loop,
                  );
                },
                icon: Icon(
                  controller.playerState.isPlaying
                      ? Icons.stop
                      : Icons.play_arrow,
                ),
                color: Colors.white,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),**/
            AudioFileWaveforms(
              size: Size(MediaQuery.of(context).size.width / 2, 70),
              playerController: controller!,
              waveformType: widget.index?.isOdd ?? false
                  ? WaveformType.fitWidth
                  : WaveformType.long,
              playerWaveStyle: playerWaveStyle,
            ),
            if (widget.isSender!) const SizedBox(width: 10),
          ],
        ),
      ),
    )
        : const SizedBox.shrink();
  }
}