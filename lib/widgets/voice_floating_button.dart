// lib/widgets/voice_floating_button.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'voice_drawer.dart';
import '../pages/chat_page.dart';  // 导入聊天页面

/// 语音悬浮球组件
/// 支持全屏拖动，点击弹出菜单
class VoiceFloatingButton extends StatefulWidget {
  const VoiceFloatingButton({super.key});

  @override
  State<VoiceFloatingButton> createState() => _VoiceFloatingButtonState();
}

class _VoiceFloatingButtonState extends State<VoiceFloatingButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 悬浮球位置（屏幕百分比）
  double _positionX = 0.9;
  double _positionY = 0.85;
  
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  bool _isListening = false;
  bool _enabled = true;
  String _wakeWord = '千寻';

  // 新增：保存上一条指令，用于重新尝试
  String? _lastCommand;

  final List<Function(String)> _listeners = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _initSpeech();
    _loadPosition();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('voice_enabled') ?? true;
      _wakeWord = prefs.getString('wake_word') ?? '千寻';
    });
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _positionX = prefs.getDouble('voice_x') ?? 0.9;
      _positionY = prefs.getDouble('voice_y') ?? 0.85;
    });
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voice_x', _positionX);
    await prefs.setDouble('voice_y', _positionY);
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {}
  }

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
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _onSpeechResult(result.recognizedWords);
        }
      },
      localeId: 'zh_CN',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _onSpeechResult(String text) async {
    _stopListening();
    if (text.isEmpty) return;
    if (!text.contains(_wakeWord)) {
      _showMessage('请说"$_wakeWord"唤醒我');
      return;
    }
    String command = text.replaceAll(_wakeWord, '').trim();
    if (command.isEmpty) {
      _showMessage('请说出指令');
      return;
    }
    // 保存指令用于重新尝试
    _lastCommand = command;
    _showVoiceDialog(command);
  }

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

  // 文字对话：跳转到完整的聊天页面
  void _showTextDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  // 新增：反馈问题
  Future<void> _feedback() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('反馈问题', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请描述您遇到的问题...',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('提交'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        final response = await ApiService.voiceFeedback('user_feedback', feedback: result);
        if (response['success'] == true) {
          _showMessage('感谢您的反馈！');
        } else {
          _showMessage('提交失败，请稍后重试');
        }
      } catch (e) {
        _showMessage('提交异常: $e');
      }
    }
  }

  // 新增：重新尝试上一条指令
  Future<void> _retryLastCommand() async {
    if (_lastCommand == null || _lastCommand!.isEmpty) {
      _showMessage('没有可重试的指令');
      return;
    }
    _showVoiceDialog(_lastCommand!);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _showMenu() {
    debugPrint('悬浮球菜单被调用');
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
            // 新增：反馈问题
            ListTile(
              leading: const Icon(Icons.feedback, color: Color(0xFFD4AF37)),
              title: const Text('反馈问题', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _feedback();
              },
            ),
            // 新增：重新尝试
            ListTile(
              leading: const Icon(Icons.replay, color: Color(0xFFD4AF37)),
              title: const Text('重新尝试', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _retryLastCommand();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void addListener(Function(String) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonSize = 56.0;
    final left = screenWidth * _positionX - buttonSize / 2;
    final top = screenHeight * _positionY - buttonSize / 2;

    return Positioned(
      left: left.clamp(0, screenWidth - buttonSize),
      top: top.clamp(0, screenHeight - buttonSize - 100),
      child: GestureDetector(
        onPanStart: (details) {
          _dragStart = details.localPosition;
          _isDragging = false;
        },
        onPanUpdate: (details) {
          final delta = details.localPosition - _dragStart;
          if (delta.distance > 5) {
            _isDragging = true;
          }
          if (_isDragging) {
            setState(() {
              _positionX += details.delta.dx / screenWidth;
              _positionY += details.delta.dy / screenHeight;
              _positionX = _positionX.clamp(0.05, 0.95);
              _positionY = _positionY.clamp(0.05, 0.85);
            });
            _dragStart = details.localPosition;
          }
        },
        onPanEnd: (details) {
          if (!_isDragging) {
            _showMenu();
          } else {
            _savePosition();
          }
          _isDragging = false;
        },
        child: Container(
          width: buttonSize,
          height: buttonSize,
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
                      width: buttonSize + value * 20,
                      height: buttonSize + value * 20,
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