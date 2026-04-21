// lib/pages/voice_settings_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt; // 【铁律修改】临时禁用语音
// import 'package:record/record.dart'; // 录音功能禁用
import '../api_service.dart';

/// 声纹设置页面
/// 支持声纹注册、验证、删除、列表查看
class VoiceSettingsPage extends StatefulWidget {
  const VoiceSettingsPage({super.key});

  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  // final stt.SpeechToText _speech = stt.SpeechToText(); // 【铁律修改】临时禁用语音
  // final Record _recorder = Record(); // 录音功能禁用

  bool _isLoading = true;
  bool _voiceEnabled = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusMessage = '';
  List<Map<String, dynamic>> _voiceUsers = [];
  String _currentUserId = 'admin';
  String _currentUserName = '管理员';

  String? _recordedFilePath;
  List<double> _extractedFeatures = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVoiceUsers();
    // _initSpeech(); // 【铁律修改】临时禁用语音
  }

  @override
  void dispose() {
    // _recorder.dispose(); // 录音功能禁用
    super.dispose();
  }

  // 【铁律修改】临时禁用语音，整个方法注释
  // Future<void> _initSpeech() async {
  // await _speech.initialize(
  // onStatus: (status) {
  // debugPrint('语音状态: $status');
  // },
  // onError: (error) {
  // debugPrint('语音错误: $error');
  // },
  // );
  // }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceEnabled = prefs.getBool('voice_enabled') ?? true;
    });
  }

  Future<void> _loadVoiceUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.voiceGetUsers();
      if (result != null && result['users'] != null) {
        setState(() {
          _voiceUsers = List<Map<String, dynamic>>.from(result['users']);
        });
      }
    } catch (e) {
      debugPrint('加载声纹用户失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载声纹用户失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startRecording() async {
    // 录音功能暂时禁用，提示用户
    _showError('录音功能暂时不可用，请等待后续版本恢复');
    return;

    /* 原录音逻辑已注释
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showError('请授予录音权限');
      return;
    }

    setState(() {
      _isRecording = true;
      _statusMessage = '录音中... 请清晰说出验证语句';
    });

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 16000,
        ),
        path: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      await Future.delayed(const Duration(seconds: 5));

      final path = await _recorder.stop();
      if (path != null) {
        _recordedFilePath = path;
        _statusMessage = '录音完成，正在提取声纹特征...';
        await _extractFeatures(path);
      } else {
        _showError('录音失败');
      }
    } catch (e) {
      _showError('录音异常: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
    }
    */
  }

  Future<void> _extractFeatures(String filePath) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final file = File(filePath);
      final audioBytes = await file.readAsBytes();

      final result = await ApiService.voiceExtractFeatures(audioBytes);
      if (result != null && result['features'] != null) {
        setState(() {
          _extractedFeatures = List<double>.from(result['features']);
          _statusMessage = '特征提取成功，可以注册或验证';
        });
        _showSuccess('特征提取成功');
      } else {
        _showError('特征提取失败');
      }
    } catch (e) {
      _showError('特征提取异常: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _registerVoice() async {
    if (_extractedFeatures.isEmpty) {
      _showError('请先录音并提取特征');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = '正在注册声纹...';
    });

    try {
      final result = await ApiService.voiceRegister(
        _currentUserId,
        _currentUserName,
        _extractedFeatures,
      );

      if (result != null && result['success'] == true) {
        _showSuccess('声纹注册成功');
        _extractedFeatures = [];
        _loadVoiceUsers();
        _statusMessage = '';
      } else {
        _showError(result?['message'] ?? '注册失败');
      }
    } catch (e) {
      _showError('注册异常: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _verifyVoice() async {
    if (_extractedFeatures.isEmpty) {
      _showError('请先录音并提取特征');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = '正在验证声纹...';
    });

    try {
      final result = await ApiService.voiceIdentify(_extractedFeatures);

      if (result != null && result['verified'] == true) {
        final userId = result['user_id'] ?? '未知';
        _showSuccess('声纹验证通过，匹配用户: $userId');
      } else {
        _showError('声纹验证失败，未匹配到用户');
      }
    } catch (e) {
      _showError('验证异常: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deleteVoice(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text('确定要删除用户 $userId 的声纹吗？', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.voiceDelete(userId);
      if (result != null && result['success'] == true) {
        _showSuccess('声纹已删除');
        _loadVoiceUsers();
      } else {
        _showError(result?['message'] ?? '删除失败');
      }
    } catch (e) {
      _showError('删除异常: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('声纹设置'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          Switch(
            value: _voiceEnabled,
            activeColor: const Color(0xFFD4AF37),
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('voice_enabled', value);
              setState(() {
                _voiceEnabled = value;
              });
              _showSuccess(value ? '声纹功能已启用' : '声纹功能已禁用');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecordingCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildVoiceUsersList(),
                ],
              ),
            ),
    );
  }

  Widget _buildRecordingCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? Colors.red : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording ? Colors.red : const Color(0xFFD4AF37),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording ? '录音中... 请说话' : '点击下方按钮开始录音',
              style: TextStyle(
                color: _isRecording ? Colors.red : Colors.grey,
                fontSize: 14,
              ),
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_isRecording || _isProcessing) ? null : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isRecording || _isProcessing) ? Colors.grey : const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isRecording ? '录音中...' : '开始录音'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: (_extractedFeatures.isEmpty || _isProcessing) ? null : _registerVoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('注册声纹'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: (_extractedFeatures.isEmpty || _isProcessing) ? null : _verifyVoice,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD4AF37),
              side: const BorderSide(color: Color(0xFFD4AF37)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('验证声纹'),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceUsersList() {
    if (_voiceUsers.isEmpty) {
      return const Card(
        color: Color(0xFF2A2A2A),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              '暂无已注册声纹用户\n请先录音并注册',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '已注册声纹',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ..._voiceUsers.map((user) => Card(
              color: const Color(0xFF2A2A2A),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                title: Text(
                  user['user_name'] ?? user['user_id'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '注册时间: ${user['registered_at']?.substring(0, 19) ?? '未知'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteVoice(user['user_id']),
                ),
              ),
            )),
      ],
    );
  }
}