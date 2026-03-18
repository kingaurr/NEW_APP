// lib/pages/position_detail_page.dart
import 'package:flutter/material.dart';
import '../utils/biometrics_helper.dart'; // 导入指纹工具类

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.position['code'] ?? '持仓详情'),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.error),
            onPressed: _confirmSellAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '基本信息',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(theme, '股票名称', widget.position['name'] ?? '--'),
                  _buildInfoRow(theme, '持仓数量', '${widget.position['shares'] ?? 0} 股'),
                  _buildInfoRow(theme, '成本价', '¥${(widget.position['cost'] ?? 0.0).toStringAsFixed(2)}'),
                  _buildInfoRow(theme, '现价', '¥${(widget.position['current_price'] ?? 0.0).toStringAsFixed(2)}'),
                  _buildProfitRow(theme, widget.position['profit'] ?? 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '止损止盈设置',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  TextField(
                    controller: _stopLossController,
                    decoration: InputDecoration(
                      labelText: '止损价',
                      prefixText: '¥',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _takeProfitController,
                    decoration: InputDecoration(
                      labelText: '止盈价',
                      prefixText: '¥',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveStopLoss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '分时走势',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    color: theme.colorScheme.surfaceVariant,
                    child: Center(
                      child: Text(
                        '图表占位',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitRow(ThemeData theme, double profit) {
    final color = profit >= 0 ? theme.colorScheme.primary : theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '浮动盈亏',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            '${profit >= 0 ? '+' : ''}¥${profit.abs().toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  // 保存止损止盈设置（需要指纹验证）
  Future<void> _saveStopLoss() async {
    // 指纹验证
    bool fingerprintEnabled = true; // TODO: 从 shared_preferences 读取
    if (fingerprintEnabled) {
      bool authenticated = await BiometricsHelper.authenticate(
        reason: '请验证指纹以修改止损止盈',
      );
      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证失败，操作取消')),
        );
        return;
      }
    }

    // 这里应调用后端API保存修改
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('止损止盈已更新（模拟）'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // 一键平仓（需要指纹验证 + 二次确认）
  Future<void> _confirmSellAll() async {
    // 指纹验证
    bool fingerprintEnabled = true; // TODO: 从 shared_preferences 读取
    if (fingerprintEnabled) {
      bool authenticated = await BiometricsHelper.authenticate(
        reason: '请验证指纹以执行平仓',
      );
      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证失败，操作取消')),
        );
        return;
      }
    }

    // 二次确认对话框
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(
          '确认平仓',
          style: theme.textTheme.titleMedium,
        ),
        content: const Text('确定要清仓该股票吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 执行平仓操作
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('平仓指令已发送（模拟）'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
              Navigator.pop(context); // 返回上一页
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}