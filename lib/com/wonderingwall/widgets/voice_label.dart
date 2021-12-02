import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

///
/// 这是一个用于名词解释的标题，包含了一个声音的模块播放
///
/// 一般用户名称标题解释。或者用于词语查看之类。
///
///  ```
///  +----------+
///  | Label 🔊 |
///  +----------+
///  ```
///
/// ### Example:
///
///  ```
///   VoiceLabel(
///     "名词解释",
///     assetPath: "assets/audios/mcjs.mp3",
///   )
///  ```
///
class VoiceLabel extends StatefulWidget {
  const VoiceLabel(
    this.label, {
    Key? key,
    required this.assetPath,
    // this.icon,
    this.iconColor = Colors.amberAccent,
    this.style = const TextStyle(
        color: Colors.black87, fontSize: 20.0, fontWeight: FontWeight.bold),
  }) : super(key: key);

  /// 名词
  final String label;

  /// 声音文件路径
  final String assetPath;

  /// 名词样式
  final TextStyle style;

  /// 图标颜色
  final Color iconColor;

  // final Widget icon;

  @override
  State<StatefulWidget> createState() => _VoiceLabelState();
}

class _VoiceLabelState extends State<VoiceLabel> {
  /// 是否显示音频喇叭按钮图标，当有音频文件时为true且显示。否则相反。
  bool _visible = false;

  /// 声音播放插件
  late AudioPlayer _audioPlayer;

  /// 声音图标动态刷新，播放时。
  final ValueNotifier<int> _valueNotifier = ValueNotifier(0);

  int _index = 0;
  final _volume = [Icons.volume_up, Icons.volume_down, Icons.volume_mute];
  late bool isDispose;

  @override
  void initState() {
    super.initState();
    _initAudio();
    isDispose = false;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _valueNotifier.dispose();
    isDispose = true;
    super.dispose();
  }

  /// 初始化音频
  void _initAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      var duration = await _audioPlayer.setAsset(widget.assetPath);
      setState(() {
        _visible = true;
      });
    } catch (e) {
      setState(() {
        _visible = false;
      });
    }

    _audioPlayer.processingStateStream.listen((event) {
      if (event == ProcessingState.completed) {
        setState(() {
          _valueNotifier.value = _index = 0;
        });
      }
    });
  }

  void _playAudio() async {
    try {
      var duration = await _audioPlayer.load();
      // 播放音频
      _audioPlayer.play();
      // 根据播放的音频播放icon喇叭动画。
      int milliseconds = 0;
      for (; milliseconds < duration!.inMilliseconds;) {
        if (isDispose) {
          return;
        }
        setState(() {
          _valueNotifier.value = _index = (_index + 1) % _volume.length;
        });
        await Future.delayed(const Duration(milliseconds: 200));
        milliseconds += 200;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            widget.label,
            style: widget.style,
            softWrap: true,
          ),
        ),
        Opacity(
          opacity: _visible ? 1.0 : 0.0,
          child: ValueListenableBuilder<int>(
            valueListenable: _valueNotifier,
            builder: (_, int value, child) {
              return IconButton(
                icon: Icon(
                  _volume[value],
                  color: widget.iconColor,
                ),
                onPressed: _playAudio,
              );
            },
          ),
        )
      ],
    );
  }
}
