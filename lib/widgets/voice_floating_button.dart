// lib/widgets/voice_floating_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'voice_drawer.dart';

/// 语音悬浮球组件
/// 支持点击/长按唤醒语音助手
class VoiceFloatingButton extends StatefulWidget {
  const VoiceFloatingButton({super.key});

  @override
  State<VoiceFloatingButton> createState() => _VoiceFloatingButtonState();
}

class _VoiceFloatingButtonState extends State<VoiceFloatingButton> {
  // 语音识别
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastRecognizedText = '';

  // 音频播放
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 悬浮球位置
  double _dx = 0;
  double _dy = 0;
  bool _isDragging = false;

  // 配置
  bool _enabled = true;
  String _wakeWord = '千寻';

  // 回调
  final List<Function(String)> _listeners = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _initSpeech();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('voice_enabled') ?? true;
      _wakeWord = prefs.getString('wake_word') ?? '千寻';
    });
  }

  /// 初始化语音识别
  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('语音状态: $status');
      },
      onError: (error) {
        debugPrint('语音错误: $error');
        setState(() {
          _isListening = false;
        });
      },
    );
    if (!available) {
      debugPrint('语音识别不可用');
    }
  }

  /// 播放提示音
  Future<void> _playBeep() async {
    try {
      // 使用系统声音或自定义音效
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint('播放提示音失败: $e');
    }
  }

  /// 开始语音识别
  Future<void> _startListening() async {
    if (!_enabled) {
      _showMessage('语音助手已禁用');
      return;
    }

    if (!_speech.isAvailable) {
      _showMessage('语音识别不可用');
      return;
    }

    // 播放提示音
    await _playBeep();

    setState(() {
      _isListening = true;
    });

    _speech.listen(
      onResult: (result) {
        setState(() {
          _lastRecognizedText = result.recognizedWords;
        });
        if (result.finalResult) {
          _onSpeechResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      localeId: 'zh_CN',
    );
  }

  /// 停止语音识别
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// 语音识别结果处理
  Future<void> _onSpeechResult(String text) async {
    _stopListening();

    if (text.isEmpty) return;

    // 检查是否包含唤醒词
    if (!text.contains(_wakeWord)) {
      _showMessage('请说"$_wakeWord"唤醒我');
      return;
    }

    // 移除唤醒词，提取指令
    String command = text.replaceAll(_wakeWord, '').trim();
    if (command.isEmpty) {
      _showMessage('请说出指令');
      return;
    }

    // 显示语音对话框
    _showVoiceDialog(command);
  }

  /// 显示语音对话框
  void _showVoiceDialog(String command) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VoiceDrawer(
        command: command,
        onResult: (result) {
          // 指令处理结果回调
          _showMessage(result['message'] ?? '指令已处理');
        },
      ),
    );
  }

  /// 显示提示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
  }

  /// 注册监听器
  void addListener(Function(String) listener) {
    _listeners.add(listener);
  }

  /// 移除监听器
  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SizedBox.shrink();

    return Positioned(
      right: _dx == 0 ? 16 : null,
      left: _dx < 0 ? _dx.abs() : null,
      bottom: _dy == 0 ? 80 : _dy,
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
        },
        onPanUpdate: (details) {
          setState(() {
            _dx += details.delta.dx;
            _dy += details.delta.dy;
            // 边界限制
            _dx = _dx.clamp(-MediaQuery.of(context).size.width + 60, MediaQuery.of(context).size.width - 60);
            _dy = _dy.clamp(0, MediaQuery.of(context).size.height - 100);
          });
        },
        onPanEnd: (details) {
          _isDragging = false;
        },
        onTap: () {
          if (!_isDragging) {
            _startListening();
          }
        },
        onLongPress: () {
          if (!_isDragging) {
            _startListening();
          }
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _isListening ? Colors.red : const Color(0xFFD4AF37),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.black,
                size: 28,
              ),
              if (_isListening)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Container(
                      width: 56 + value * 20,
                      height: 56 + value * 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.3 - value * 0.2),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}