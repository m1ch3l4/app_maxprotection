// @dart=2.10
import 'dart:io';

import 'package:app_maxprotection/widgets/constants.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/HexColor.dart';
import '../utils/chart_bubble.dart';

void main() => runApp(const TstWave());

class TstWave extends StatelessWidget {
  const TstWave({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Audio Waveforms',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  RecorderController recorderController;

  String path;
  String musicFile;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  Directory appDirectory;

  @override
  void initState() {
    super.initState();
    _getDir();
    _initialiseControllers();
  }

  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    //path = "${appDirectory.path}/recording.mp3";
    getFilePath().then((value) => path = value);
    isLoading = false;
    setState(() {});
  }
  int i=0;
  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = storageDirectory.path + "/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/test_${i++}.mp3";
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEGLayer3
      ..sampleRate = 44100;
  }

  void _pickFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      musicFile = result.files.single.path;
      print("*******musicFile? "+musicFile.toString());
      setState(() {});
    } else {
      debugPrint("File not picked");
    }
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252331),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252331),
        elevation: 1,
        centerTitle: true,
        shadowColor: Colors.grey,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Simform'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            /**Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (_, index) {
                  return WaveBubble(
                    index: index + 1,
                    isSender: index.isOdd,
                    width: MediaQuery.of(context).size.width / 2,
                    appDirectory: appDirectory,
                  );
                },
              ),
            ),**/
            if (isRecordingCompleted)
              WaveBubble(
                path: path,
                isSender: true,
                appDirectory: appDirectory,
              ),
            /**if (musicFile != null)
              WaveBubble(
                path: musicFile,
                isSender: true,
                appDirectory: appDirectory,
              ),**/
            SafeArea(
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isRecording
                        ? AudioWaveforms(
                      enableGesture: true,
                      size: Size(
                          MediaQuery.of(context).size.width / 2,
                          50),
                      recorderController: recorderController,
                      waveStyle: WaveStyle(
                        waveColor: Colors.white,
                        backgroundColor: HexColor(Constants.greyContainer),
                        extendWaveform: true,
                        showMiddleLine: false,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: const Color(0xFF1E1B26),
                      ),
                      padding: const EdgeInsets.only(left: 18),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15),
                    )
                        : Container(
                      width:
                      MediaQuery.of(context).size.width / 1.7,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B26),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.only(left: 18),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15),
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: "Type Something...",
                          hintStyle: const TextStyle(
                              color: Colors.white54),
                          contentPadding:
                          const EdgeInsets.only(top: 16),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            onPressed: _pickFile,
                            icon: Icon(Icons.adaptive.share),
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshWave,
                    icon: Icon(
                      isRecording ? Icons.refresh : Icons.send,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _startOrStopRecording,
                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    color: Colors.white,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startOrStopRecording() async {
    try {
      if (isRecording) {
        recorderController.reset();

        await recorderController.stop(false).then((value) => path=value);

        if (path != null) {
          isRecordingCompleted = true;
          debugPrint(path);
          debugPrint("Recorded file size: ${File(path).lengthSync()}");
        }
      } else {
        _getDir();
        await recorderController.record(path: path);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  void _refreshWave() {
    if (isRecording) recorderController.refresh();
  }
}