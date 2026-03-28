// lib/widgets/voice_floating_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'voice_drawer.dart';

/// 语音悬浮球组件
/// 支持点击/长按弹出菜单，选择语音对话或文字对话
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

    String command = text.replaceAll(_wakeWord, '').trim();
    if (command.isEmpty) {
      _showMessage('请说出指令');
      return;
    }

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
          _showMessage(result['message'] ?? '指令已处理');
        },
      ),
    );
  }

  /// 显示文字对话对话框
  void _showTextDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('与千寻对话', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '输入你的问题...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
              autofocus: true,
              onSubmitted: (_) => _sendTextMessage(_controller.text, context),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _sendTextMessage(_controller.text, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
                child: const Text('发送'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 发送文字消息
  Future<void> _sendTextMessage(String text, BuildContext dialogContext) async {
    if (text.trim().isEmpty) {
      _showMessage('请输入问题');
      return;
    }

    // 关闭对话框
    Navigator.pop(dialogContext);

    // 显示加载中
    _showMessage('思考中...');

    try {
      final result = await ApiService.voiceAsk(text);
      if (result != null && result['answer'] != null) {
        // 显示回答
        _showMessage(result['answer']);
        // 同时通知监听器
        for (var listener in _listeners) {
          listener(result['answer']);
        }
      } else {
        _showMessage('抱歉，我暂时无法回答这个问题');
      }
    } catch (e) {
      _showMessage('请求失败: $e');
    }
  }

  /// 显示提示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.black87,
      ),
    );
  }

  /// 显示悬浮球菜单
  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mic, color: Color(0xFFD4AF37)),
              title: const Text('语音对话', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _startListening();
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Color(0xFFD4AF37)),
              title: const Text('文字对话', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showTextDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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
            _dx = _dx.clamp(-MediaQuery.of(context).size.width + 60, MediaQuery.of(context).size.width - 60);
            _dy = _dy.clamp(0, MediaQuery.of(context).size.height - 100);
          });
        },
        onPanEnd: (details) {
          _isDragging = false;
        },
        onTap: () {
          if (!_isDragging) {
            _showMenu();
          }
        },
        onLongPress: () {
          if (!_isDragging) {
            _showMenu();
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
                _isListening ? Icons.mic : Icons.message,
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