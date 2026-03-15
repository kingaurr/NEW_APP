// lib/pages/position_detail_page.dart
import 'package:flutter/material.dart';

class PositionDetailPage extends StatefulWidget {
  final Map<String, dynamic> position;
  const PositionDetailPage({Key? key, required this.position}) : super(key: key);

  @override
  State<PositionDetailPage> createState() => _PositionDetailPageState();
}

class _PositionDetailPageState extends State<PositionDetailPage> {
  late TextEditingController _stopLossController;
  late TextEditingController _takeProfitController;

  @override
  void initState() {
    super.initState();
    _stopLossController = TextEditingController(
      text: widget.position['stop_loss']?.toStringAsFixed(2) ?? '',
    );
    _takeProfitController = TextEditingController(
      text: widget.position['take_profit']?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _stopLossController.dispose();
    _takeProfitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.position['code'] ?? '持仓详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _confirmSellAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('基本信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildInfoRow('股票名称', widget.position['name'] ?? '--'),
                  _buildInfoRow('持仓数量', '${widget.position['shares'] ?? 0} 股'),
                  _buildInfoRow('成本价', '¥${(widget.position['cost'] ?? 0.0).toStringAsFixed(2)}'),
                  _buildInfoRow('现价', '¥${(widget.position['current_price'] ?? 0.0).toStringAsFixed(2)}'),
                  _buildInfoRow(
                    '浮动盈亏',
                    '${(widget.position['profit'] ?? 0) >= 0 ? '+' : ''}¥${(widget.position['profit'] ?? 0.0).toStringAsFixed(2)}',
                    valueColor: (widget.position['profit'] ?? 0) >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('止损止盈设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  TextField(
                    controller: _stopLossController,
                    decoration: const InputDecoration(
                      labelText: '止损价',
                      prefixText: '¥',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _takeProfitController,
                    decoration: const InputDecoration(
                      labelText: '止盈价',
                      prefixText: '¥',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveStopLoss,
                          child: const Text('保存修改'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('分时走势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Center(child: Text('图表占位', style: TextStyle(color: Colors.white54))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }

  void _saveStopLoss() {
    // 这里应调用后端API保存修改
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('止损止盈已更新（模拟）')),
    );
  }

  void _confirmSellAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认平仓'),
        content: const Text('确定要清仓该股票吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 执行平仓操作
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('平仓指令已发送（模拟）')),
              );
              Navigator.pop(context); // 返回上一页
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}