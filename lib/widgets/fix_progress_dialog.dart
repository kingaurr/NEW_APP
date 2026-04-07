// lib/widgets/fix_progress_dialog.dart
import 'package:flutter/material.dart';

/// 一键修复进度对话框
/// 在执行一键修复时显示，提示用户等待
class FixProgressDialog extends StatelessWidget {
  const FixProgressDialog({super.key, this.message = '正在执行修复，请稍候...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}