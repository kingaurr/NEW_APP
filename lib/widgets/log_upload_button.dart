// lib/widgets/log_upload_button.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 日志上传按钮组件
/// 点击后选择本地日志文件，经指纹验证后上传到服务器
class LogUploadButton extends StatefulWidget {
  const LogUploadButton({super.key, this.onUploadComplete});

  final VoidCallback? onUploadComplete;

  @override
  State<LogUploadButton> createState() => _LogUploadButtonState();
}

class _LogUploadButtonState extends State<LogUploadButton> {
  bool _isUploading = false;

  Future<void> _uploadLogs() async {
    // 指纹验证
    final authenticated = await BiometricsHelper.authenticateAndGetToken();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证失败，操作取消')),
        );
      }
      return;
    }

    // 选择文件
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['log', 'txt'],
    );
    if (result == null) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    setState(() => _isUploading = true);

    try {
      final uploadResult = await ApiService.uploadLogs(filePath);
      if (uploadResult['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('日志上传成功，开发者将收到通知'), backgroundColor: Colors.green),
          );
          widget.onUploadComplete?.call();
        }
      } else {
        throw Exception(uploadResult['error'] ?? '上传失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isUploading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadLogs,
            tooltip: '上传日志',
          );
  }
}