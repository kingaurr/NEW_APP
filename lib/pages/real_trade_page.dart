// lib/pages/real_trade_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class RealTradePage extends StatefulWidget {
  const RealTradePage({super.key});

  @override
  RealTradePageState createState() => RealTradePageState();
}

class RealTradePageState extends State<RealTradePage> {
  bool _isLoading = true;
  double _fund = 0.0;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await ApiService.getFund();
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _fund = (result['available_fund'] ?? result['current_fund'] ?? 0.0).toDouble();
        });
      } else {
        throw Exception('返回数据格式错误');
      }
    } catch (e, stack) {
      debugPrint('加载资金失败: $e\n$stack');
      setState(() {
        _error = e.toString();
      });
      // 弹窗显示错误
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('加载失败'),
            content: Text('错误: $e\n\n请将截图发给开发者'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实盘账户（极简版）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error.isNotEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('错误: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '当前总资产',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${_fund.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}