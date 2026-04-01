// lib/pages/real_trade_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../api_service.dart';

class RealTradePage extends StatefulWidget {
  const RealTradePage({super.key});

  @override
  RealTradePageState createState() => RealTradePageState();
}

class RealTradePageState extends State<RealTradePage> {
  String _error = '';

  @override
  void initState() {
    super.initState();
    _test();
  }

  Future<void> _test() async {
    try {
      final result = await ApiService.getFund();
      if (result != null && result is Map<String, dynamic>) {
        final fund = (result['available_fund'] ?? result['current_fund'] ?? 0.0).toDouble();
        setState(() {
          _error = '成功: 资金 = ¥$fund';
        });
      } else {
        setState(() {
          _error = '失败: 返回数据格式错误';
        });
      }
    } catch (e) {
      setState(() {
        _error = '异常: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('实盘账户(调试)')),
      body: Center(
        child: Text(
          _error.isEmpty ? '加载中...' : _error,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}