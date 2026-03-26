// lib/widgets/risk_base_fund_setting.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 风控基准资金设置组件
/// 用于设置和显示风控基准资金，当真实资金低于基准时显示警告
class RiskBaseFundSetting extends StatefulWidget {
  final VoidCallback? onChanged;

  const RiskBaseFundSetting({super.key, this.onChanged});

  @override
  State<RiskBaseFundSetting> createState() => _RiskBaseFundSettingState();
}

class _RiskBaseFundSettingState extends State<RiskBaseFundSetting> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  double _baseFund = 0.0;
  double _currentFund = 0.0;
  String _warningMessage = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取风控基准资金
      final config = await ApiService.getRiskBaseFund();
      if (config != null) {
        setState(() {
          _baseFund = config['base_fund'] ?? 0.0;
          _controller.text = _formatNumber(_baseFund);
        });
      }

      // 获取当前真实资金
      final fund = await ApiService.getFund();
      if (fund != null) {
        setState(() {
          _currentFund = fund['total'] ?? 0.0;
        });
      }

      _checkWarning();
    } catch (e) {
      debugPrint('加载风控基准资金失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red),
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

  void _checkWarning() {
    if (_baseFund > 0 && _currentFund < _baseFund) {
      final gap = _baseFund - _currentFund;
      setState(() {
        _warningMessage = '⚠️ 当前资金低于风控基准 ${_formatNumber(gap)} 元，请注意风险';
      });
    } else {
      setState(() {
        _warningMessage = '';
      });
    }
  }

  String _formatNumber(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(2)}亿';
    } else if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Future<void> _saveBaseFund() async {
    final inputValue = _controller.text.trim();
    if (inputValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入基准资金'), backgroundColor: Colors.red),
      );
      return;
    }

    double newValue;
    try {
      // 支持万、亿单位输入
      if (inputValue.endsWith('万')) {
        newValue = double.parse(inputValue.replaceAll('万', '')) * 10000;
      } else if (inputValue.endsWith('亿')) {
        newValue = double.parse(inputValue.replaceAll('亿', '')) * 100000000;
      } else {
        newValue = double.parse(inputValue);
      }

      if (newValue < 0) {
        throw Exception('资金不能为负数');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的金额'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ApiService.updateRiskBaseFund(newValue);
      if (result?['success'] == true) {
        setState(() {
          _baseFund = newValue;
          _controller.text = _formatNumber(newValue);
          _isEditing = false;
        });
        _checkWarning();
        widget.onChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('风控基准资金已更新'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception(result?['message'] ?? '保存失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _controller.text = _formatNumber(_baseFund);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        color: Color(0xFF2A2A2A),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _warningMessage.isNotEmpty
            ? BorderSide(color: Colors.orange.withOpacity(0.5))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Color(0xFFD4AF37), size: 20),
                SizedBox(width: 8),
                Text(
                  '风控基准资金',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_warningMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _warningMessage,
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '当前资金',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatNumber(_currentFund),
                        style: TextStyle(
                          color: _currentFund >= _baseFund ? Colors.green : Colors.orange,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '基准资金',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      if (_isEditing)
                        TextField(
                          controller: _controller,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFD4AF37)),
                            ),
                          ),
                        )
                      else
                        Text(
                          _formatNumber(_baseFund),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancelEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveBaseFund,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _controller.text = _formatNumber(_baseFund);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4AF37),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                  child: const Text('修改基准'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}