// lib/widgets/voice_drawer.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语音对话框组件
/// 显示语音识别结果和处理状态
class VoiceDrawer extends StatefulWidget {
  final String command;
  final Function(Map<String, dynamic>) onResult;

  const VoiceDrawer({
    super.key,
    required this.command,
    required this.onResult,
  });

  @override
  State<VoiceDrawer> createState() => _VoiceDrawerState();
}

class _VoiceDrawerState extends State<VoiceDrawer> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = true;
  bool _isSuccess = false;
  String _responseText = '';
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _processCommand();
  }

  /// 处理语音指令
  Future<void> _processCommand() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 调用后端语音接口
      final result = await _apiService.voiceAsk(widget.command);

      setState(() {
        _isProcessing = false;
        _isSuccess = result['success'] ?? false;
        _result = result;
        _responseText = _formatResponse(result);
      });

      // 回调给父组件
      widget.onResult(result);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _responseText = '处理失败: $e';
      });
      widget.onResult({
        'success': false,
        'message': '处理失败: $e',
      });
    }
  }

  /// 格式化响应文本
  String _formatResponse(Map<String, dynamic> result) {
    if (result['success'] == true) {
      return result['message'] ?? '指令已执行';
    }
    return result['message'] ?? '指令处理失败';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖动条
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // 标题
            const Text(
              '千寻助手',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // 用户指令区域
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.command,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 处理状态/响应区域
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                      ),
                    )
                  else
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _isSuccess ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isProcessing ? '正在处理...' : _responseText,
                      style: TextStyle(
                        color: _isProcessing ? Colors.grey : (_isSuccess ? Colors.white : Colors.red[300]),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 操作按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 重新开始录音
                        Navigator.pop(context);
                        // 通知父组件重新录音
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('继续提问'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}