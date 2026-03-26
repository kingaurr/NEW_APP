// lib/widgets/budget_setting.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 预算设置组件
/// 用于设置和显示AI调用预算（日预算/月预算）
class BudgetSetting extends StatefulWidget {
  final VoidCallback? onChanged;

  const BudgetSetting({super.key, this.onChanged});

  @override
  State<BudgetSetting> createState() => _BudgetSettingState();
}

class _BudgetSettingState extends State<BudgetSetting> {
  bool _isLoading = true;
  bool _isEditingDaily = false;
  bool _isEditingMonthly = false;
  bool _isSaving = false;
  double _dailyBudget = 5.0;
  double _monthlyBudget = 200.0;
  double _dailyUsed = 0.0;
  double _monthlyUsed = 0.0;
  final TextEditingController _dailyController = TextEditingController();
  final TextEditingController _monthlyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取预算配置
      final config = await ApiService.getBudgetConfig();
      if (config != null) {
        setState(() {
          _dailyBudget = config['daily_budget'] ?? 5.0;
          _monthlyBudget = config['monthly_budget'] ?? 200.0;
          _dailyController.text = _dailyBudget.toStringAsFixed(2);
          _monthlyController.text = _monthlyBudget.toStringAsFixed(2);
        });
      }

      // 获取成本使用情况
      final costStatus = await ApiService.getCostStatus();
      if (costStatus != null) {
        setState(() {
          _dailyUsed = costStatus['daily_used'] ?? 0.0;
          _monthlyUsed = costStatus['monthly_used'] ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('加载预算配置失败: $e');
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

  Future<void> _saveDailyBudget() async {
    final inputValue = _dailyController.text.trim();
    if (inputValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日预算金额'), backgroundColor: Colors.red),
      );
      return;
    }

    double newValue;
    try {
      newValue = double.parse(inputValue);
      if (newValue < 0) {
        throw Exception('预算不能为负数');
      }
      if (newValue > 1000) {
        final confirm = await _showConfirmDialog(
          title: '确认日预算',
          content: '日预算设置为 ${newValue.toStringAsFixed(2)} 元，确认吗？',
        );
        if (confirm != true) return;
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
      final result = await ApiService.updateBudgetConfig(
        dailyBudget: newValue,
        monthlyBudget: _monthlyBudget,
      );
      if (result?['success'] == true) {
        setState(() {
          _dailyBudget = newValue;
          _dailyController.text = newValue.toStringAsFixed(2);
          _isEditingDaily = false;
        });
        widget.onChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('日预算已更新'), backgroundColor: Colors.green),
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

  Future<void> _saveMonthlyBudget() async {
    final inputValue = _monthlyController.text.trim();
    if (inputValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入月预算金额'), backgroundColor: Colors.red),
      );
      return;
    }

    double newValue;
    try {
      newValue = double.parse(inputValue);
      if (newValue < 0) {
        throw Exception('预算不能为负数');
      }
      if (newValue > 5000) {
        final confirm = await _showConfirmDialog(
          title: '确认月预算',
          content: '月预算设置为 ${newValue.toStringAsFixed(2)} 元，确认吗？',
        );
        if (confirm != true) return;
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
      final result = await ApiService.updateBudgetConfig(
        dailyBudget: _dailyBudget,
        monthlyBudget: newValue,
      );
      if (result?['success'] == true) {
        setState(() {
          _monthlyBudget = newValue;
          _monthlyController.text = newValue.toStringAsFixed(2);
          _isEditingMonthly = false;
        });
        widget.onChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('月预算已更新'), backgroundColor: Colors.green),
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

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  double _getDailyUsagePercent() {
    if (_dailyBudget <= 0) return 0;
    return (_dailyUsed / _dailyBudget).clamp(0.0, 1.0);
  }

  double _getMonthlyUsagePercent() {
    if (_monthlyBudget <= 0) return 0;
    return (_monthlyUsed / _monthlyBudget).clamp(0.0, 1.0);
  }

  Color _getUsageColor(double percent) {
    if (percent >= 0.9) return Colors.red;
    if (percent >= 0.7) return Colors.orange;
    return Colors.green;
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

    final dailyPercent = _getDailyUsagePercent();
    final monthlyPercent = _getMonthlyUsagePercent();

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Color(0xFFD4AF37), size: 20),
                SizedBox(width: 8),
                Text(
                  '成本预算',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 日预算
            _buildBudgetItem(
              title: '日预算',
              budget: _dailyBudget,
              used: _dailyUsed,
              percent: dailyPercent,
              isEditing: _isEditingDaily,
              controller: _dailyController,
              onEdit: () {
                setState(() {
                  _isEditingDaily = true;
                  _dailyController.text = _dailyBudget.toStringAsFixed(2);
                });
              },
              onSave: _saveDailyBudget,
              onCancel: () {
                setState(() {
                  _isEditingDaily = false;
                  _dailyController.text = _dailyBudget.toStringAsFixed(2);
                });
              },
            ),

            const SizedBox(height: 16),

            // 月预算
            _buildBudgetItem(
              title: '月预算',
              budget: _monthlyBudget,
              used: _monthlyUsed,
              percent: monthlyPercent,
              isEditing: _isEditingMonthly,
              controller: _monthlyController,
              onEdit: () {
                setState(() {
                  _isEditingMonthly = true;
                  _monthlyController.text = _monthlyBudget.toStringAsFixed(2);
                });
              },
              onSave: _saveMonthlyBudget,
              onCancel: () {
                setState(() {
                  _isEditingMonthly = false;
                  _monthlyController.text = _monthlyBudget.toStringAsFixed(2);
                });
              },
            ),

            const SizedBox(height: 12),
            const Text(
              '当预算使用超过70%时，系统将自动降级AI模型以控制成本',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem({
    required String title,
    required double budget,
    required double used,
    required double percent,
    required bool isEditing,
    required TextEditingController controller,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (!isEditing)
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 32),
                ),
                child: const Text(
                  '修改',
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isEditing)
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    suffixText: '元',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4AF37)),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Text(
                  '¥${budget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Text(
              '已用 ¥${used.toStringAsFixed(2)}',
              style: TextStyle(
                color: percent >= 0.7 ? Colors.orange : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: Colors.grey[800],
          color: _getUsageColor(percent),
          borderRadius: BorderRadius.circular(4),
        ),
        if (isEditing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}