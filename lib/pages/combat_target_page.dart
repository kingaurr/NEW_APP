// lib/pages/combat_target_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class CombatTargetPage extends StatefulWidget {
  const CombatTargetPage({super.key});

  @override
  State<CombatTargetPage> createState() => _CombatTargetPageState();
}

class _CombatTargetPageState extends State<CombatTargetPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _target = {};
  Map<String, dynamic> _progress = {};
  Map<String, dynamic> _prediction = {};
  List<dynamic> _strategyContributions = [];

  final TextEditingController _winRateController = TextEditingController();
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _drawdownController = TextEditingController();

  String _priority = 'balanced';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _winRateController.dispose();
    _profitController.dispose();
    _drawdownController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await ApiService.getPublicConfig();
      if (config != null && config is Map<String, dynamic>) {
        Map<String, dynamic> targetData = {};
        if (config.containsKey('combat_target') && config['combat_target'] is Map) {
          targetData = config['combat_target'] as Map<String, dynamic>;
          _target = targetData['target'] ?? {};
          _priority = targetData['priority'] ?? 'balanced';
        } else if (config.containsKey('target') && config['target'] is Map) {
          _target = config['target'] ?? {};
          _priority = config['priority'] ?? 'balanced';
        }

        _winRateController.text = ((_target['win_rate'] ?? 0.55) * 100).toStringAsFixed(0);
        _profitController.text = ((_target['profit'] ?? 0.05) * 100).toStringAsFixed(1);
        _drawdownController.text = ((_target['max_drawdown'] ?? 0.10) * 100).toStringAsFixed(0);
      }

      final heartSummary = await ApiService.getHeartSummary();
      if (heartSummary != null && heartSummary is Map<String, dynamic>) {
        if (heartSummary.containsKey('combat_progress') && heartSummary['combat_progress'] is Map) {
          _progress = heartSummary['combat_progress'] as Map<String, dynamic>;
        }
      }

      final learningProgress = await ApiService.getLearningProgress();
      if (learningProgress != null && learningProgress is Map<String, dynamic>) {
        if (learningProgress.containsKey('target_prediction') && learningProgress['target_prediction'] is Map) {
          _prediction = learningProgress['target_prediction'] as Map<String, dynamic>;
        }
      }

      // 获取策略列表，兼容 Map 和 List 返回值
      final strategiesResult = await ApiService.getStrategies();
      if (strategiesResult != null) {
        List<dynamic> strategiesList = [];
        if (strategiesResult is List) {
          strategiesList = strategiesResult;
        } else if (strategiesResult is Map) {
          // 安全地提取 strategies 键
          final strategiesData = (strategiesResult as Map)['strategies'];
          if (strategiesData is List) {
            strategiesList = strategiesData;
          }
        }
        _strategyContributions = strategiesList.where((s) =>
          s is Map && (s['negative_contribution_score'] != null && s['negative_contribution_score'] > 0)
        ).toList();
      }
    } catch (e) {
      debugPrint('加载目标数据失败: $e');
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

  Future<void> _saveTarget() async {
    final winRate = double.tryParse(_winRateController.text) ?? 55;
    final profit = double.tryParse(_profitController.text) ?? 5;
    final drawdown = double.tryParse(_drawdownController.text) ?? 10;

    if (winRate < 0 || winRate > 100) {
      _showError('胜率必须在0-100之间');
      return;
    }
    if (profit < -50 || profit > 200) {
      _showError('收益目标不合理');
      return;
    }
    if (drawdown < 0 || drawdown > 100) {
      _showError('最大回撤必须在0-100之间');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final newTarget = {
        'win_rate': winRate / 100,
        'profit': profit / 100,
        'max_drawdown': drawdown / 100,
      };

      final success = await ApiService.updateCombatTarget(newTarget);
      if (success == true) {
        setState(() {
          _target = newTarget;
        });
        _showSuccess('目标已更新');
        _loadData();
      } else {
        _showError('保存失败');
      }
    } catch (e) {
      _showError('保存失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updatePriority(String priority) async {
    setState(() {
      _priority = priority;
      _isSaving = true;
    });

    try {
      final success = await ApiService.updateCombatPriority(priority);
      if (success == true) {
        _showSuccess('优先级已切换为${_getPriorityName(priority)}');
      } else {
        _showError('切换失败');
        setState(() {
          _priority = _priority;
        });
      }
    } catch (e) {
      _showError('切换失败: $e');
      setState(() {
        _priority = _priority;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getPriorityName(String priority) {
    switch (priority) {
      case 'profit_focused':
        return '收益优先';
      case 'risk_focused':
        return '风控优先';
      default:
        return '均衡';
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

  double _getProgressValue(String metric) {
    final progress = _progress[metric]?['progress'] ?? 0.0;
    return progress;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实战目标'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildTargetCard(),
                  const SizedBox(height: 16),
                  _buildPriorityCard(),
                  const SizedBox(height: 16),
                  _buildPredictionCard(),
                  const SizedBox(height: 16),
                  _buildStrategyContributions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCard() {
    final winRateProgress = _getProgressValue('win_rate');
    final profitProgress = _getProgressValue('profit');
    final drawdownProgress = _getProgressValue('max_drawdown');
    final overallProgress = _progress['overall_progress'] ?? 0.0;
    final daysRemaining = _progress['days_remaining'] ?? 0;
    final status = _progress['status'] ?? 'caution';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'excellent':
        statusColor = Colors.green;
        statusText = '优秀';
        break;
      case 'on_track':
        statusColor = Colors.lightBlue;
        statusText = '正常推进';
        break;
      case 'caution':
        statusColor = Colors.orange;
        statusText = '需关注';
        break;
      case 'behind':
        statusColor = Colors.red;
        statusText = '严重滞后';
        break;
      default:
        statusColor = Colors.grey;
        statusText = '未知';
    }

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 8),
                const Text(
                  '当前进度',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressItem('胜率', winRateProgress, _target['win_rate'] ?? 0.55),
            const SizedBox(height: 12),
            _buildProgressItem('收益', profitProgress, _target['profit'] ?? 0.05),
            const SizedBox(height: 12),
            _buildProgressItem('最大回撤', drawdownProgress, _target['max_drawdown'] ?? 0.10, isReverse: true),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: Colors.grey[800],
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '综合进度 ${(overallProgress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '剩余 $daysRemaining 天',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, double progress, double target, {bool isReverse = false}) {
    final displayProgress = (progress * 100).toInt();
    final targetPercent = (target * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(
              '$displayProgress% / $targetPercent%',
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          color: progress >= 1.0 ? Colors.green : Colors.orange,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildTargetCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '目标设置',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _winRateController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '目标胜率 (%)',
                labelStyle: TextStyle(color: Colors.grey),
                suffixText: '%',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _profitController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '目标收益 (%)',
                labelStyle: TextStyle(color: Colors.grey),
                suffixText: '%',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _drawdownController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '最大回撤 (%)',
                labelStyle: TextStyle(color: Colors.grey),
                suffixText: '%',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTarget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存目标'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '优先级策略',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPriorityButton('均衡', 'balanced'),
                const SizedBox(width: 8),
                _buildPriorityButton('收益优先', 'profit_focused'),
                const SizedBox(width: 8),
                _buildPriorityButton('风控优先', 'risk_focused'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, String value) {
    final isSelected = _priority == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _updatePriority(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFFD4AF37) : Colors.grey[800],
          foregroundColor: isSelected ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildPredictionCard() {
    final willSucceed = _prediction['will_succeed'] ?? false;
    final projectedProgress = _prediction['projected_final_progress'] ?? 0.0;
    final suggestion = _prediction['suggestion'] ?? '';

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
                Icon(Icons.trending_up, color: Color(0xFFD4AF37), size: 20),
                SizedBox(width: 8),
                Text(
                  '目标预测',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: willSucceed ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    willSucceed ? '有望达成' : '可能无法达成',
                    style: TextStyle(
                      color: willSucceed ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '预计进度 ${(projectedProgress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (suggestion.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                suggestion,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyContributions() {
    if (_strategyContributions.isEmpty) {
      return const SizedBox.shrink();
    }

    final topContributors = _strategyContributions.take(3).toList();

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '主要拖累策略',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...topContributors.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name'] ?? s['id'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s['reason'] ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      LinearProgressIndicator(
                        value: (s['negative_contribution_score'] ?? 0) / 10,
                        backgroundColor: Colors.grey[800],
                        color: Colors.red,
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}