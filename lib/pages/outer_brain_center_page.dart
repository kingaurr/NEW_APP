// lib/pages/outer_brain_center_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';
import 'alert_list_page.dart';
import 'log_analysis_page.dart';

class OuterBrainCenterPage extends StatefulWidget {
  const OuterBrainCenterPage({super.key});

  @override
  State<OuterBrainCenterPage> createState() => _OuterBrainCenterPageState();
}

class _OuterBrainCenterPageState extends State<OuterBrainCenterPage> {
  bool _isLoading = true;
  Map<String, dynamic> _status = {};
  List<dynamic> _pendingRules = [];
  List<dynamic> _upcomingIpo = [];
  Map<String, dynamic> _warGameLight = {};
  Map<String, dynamic> _warGameDeep = {};
  Map<String, dynamic> _strategyStatus = {};
  Map<String, dynamic> _evolutionReport = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _error = '';
    try {
      final status = await ApiService.getOuterBrainStatus();
      final pending = await ApiService.getPendingRulesV2(limit: 5);
      final ipo = await ApiService.getUpcomingIpo();
      final light = await ApiService.getLatestLightWarGame();
      final deep = await ApiService.getLatestDeepWarGame();
      final strategy = await ApiService.getStrategyAlchemyStatus();
      final evolution = await ApiService.getEvolutionReport();

      if (mounted) {
        setState(() {
          _status = status ?? {};
          _pendingRules = pending ?? [];
          final upcoming = ipo is Map ? (ipo['upcoming'] is List ? ipo['upcoming'] as List : const []) : const [];
          _upcomingIpo = upcoming;
          _warGameLight = light ?? {};
          _warGameDeep = deep ?? {};
          _strategyStatus = strategy ?? {};
          _evolutionReport = evolution ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadAllData();
  }

  Future<void> _runWarGame(String type) async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken();
    if (!authenticated) {
      _showMessage('指纹验证失败，操作取消', isError: true);
      return;
    }
    try {
      Map<String, dynamic> result;
      if (type == 'light') {
        result = await ApiService.runLightWarGame();
      } else {
        result = await ApiService.runDeepWarGame();
      }
      if (result['success'] == true) {
        _showMessage('${type == 'light' ? '轻量' : '深度'}对抗已触发，请稍后查看报告');
        await _loadAllData();
      } else {
        _showMessage('执行失败: ${result['error'] ?? '未知错误'}', isError: true);
      }
    } catch (e) {
      _showMessage('执行异常: $e', isError: true);
    }
  }

  Future<void> _runOneClickFix() async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken();
    if (!authenticated) {
      _showMessage('指纹验证失败，操作取消', isError: true);
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const FixProgressDialog(),
    );
    try {
      final result = await ApiService.oneClickFix();
      if (mounted) Navigator.of(context).pop();
      if (result['success'] == true) {
        _showMessage('一键修复已完成，请查看修复日志');
        await _loadAllData();
      } else {
        _showMessage('修复失败: ${result['error'] ?? '未知错误'}', isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showMessage('修复异常: $e', isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'running': return '进化中';
      case 'completed': return '已完成';
      case 'failed': return '失败';
      default: return '待执行';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'running': return Colors.orange;
      case 'completed': return Colors.green;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('外脑中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildEvolutionReportCard(),
                        const SizedBox(height: 16),
                        _buildCollectionStatusCard(),
                        const SizedBox(height: 16),
                        _buildPendingRulesCard(),
                        const SizedBox(height: 16),
                        _buildIpoReminderCard(),
                        const SizedBox(height: 16),
                        _buildWarGameCard(),
                        const SizedBox(height: 16),
                        _buildStrategyAlchemyCard(),
                        const SizedBox(height: 16),
                        _buildLogAnalysisButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEvolutionReportCard() {
    final status = _evolutionReport['status'] ?? 'idle';
    final summary = _evolutionReport['summary'] ?? '';
    final newRules = _evolutionReport['new_rules'] ?? 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: Card(
        color: const Color(0xFF2A2A2A),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 24),
                  const SizedBox(width: 8),
                  const Text('外脑进化报告', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(color: _getStatusColor(status), fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (summary.isNotEmpty)
                Text(
                  summary,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (newRules > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '新规则数: $newRules',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionStatusCard() {
    final successRate = _status['collection_success_rate'] ?? 0.0;
    final todayCollected = _status['today_collected'] ?? 0;
    final pendingReview = _status['pending_review'] ?? 0;
    return Card(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload, size: 28, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                const Text('采集状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                Text('成功率 ${(successRate * 100).toInt()}%', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: successRate, backgroundColor: Colors.grey[800]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('今日采集', todayCollected),
                _buildStatItem('待审核', pendingReview),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPendingRulesCard() {
    if (_pendingRules.isEmpty) {
      return Card(
        color: const Color(0xFF2A2A2A),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text('暂无待审核策略', style: const TextStyle(color: Colors.grey))),
        ),
      );
    }
    return Card(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rule, size: 28, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                const Text('待审核策略', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/community_strategies');
                  },
                  child: const Text('查看全部', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: _pendingRules.take(5).map((rule) {
                return ListTile(
                  title: Text(rule['name'] ?? rule['id'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text('来源: ${rule['source'] ?? '未知'} | LLM评分: ${rule['llm_score'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/community_strategy_detail',
                      arguments: {'id': rule['id']},
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIpoReminderCard() {
    if (_upcomingIpo.isEmpty) {
      return Card(
        color: const Color(0xFF2A2A2A),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text('暂无新股提醒', style: const TextStyle(color: Colors.grey))),
        ),
      );
    }
    return Card(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, size: 28, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                const Text('IPO提醒', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ipo_analysis');
                  },
                  child: const Text('查看全部', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: _upcomingIpo.take(3).map((ipo) {
                return ListTile(
                  title: Text(ipo['stock_name'] ?? '未知', style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${ipo['status'] ?? ''} 日期: ${ipo['date'] ?? ''} 评分: ${ipo['overall_score'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/ipo_analysis_detail',
                      arguments: {'stock_code': ipo['stock_code']},
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarGameCard() {
    final lightWinRate = _warGameLight['win_rate'] ?? 0.0;
    final lightDrawdown = _warGameLight['max_drawdown'] ?? 0.0;
    final deepPassRate = _warGameDeep['pass_rate'] ?? 0.0;
    return Card(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_score, size: 28, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                const Text('红蓝军对抗', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('轻量级', style: TextStyle(color: Colors.grey)),
                      Text('胜率 ${(lightWinRate * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('回撤 ${(lightDrawdown * 100).toInt()}%', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('深度', style: TextStyle(color: Colors.grey)),
                      Text('通过率 ${(deepPassRate * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _runWarGame('light'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('运行轻量'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                ),
                ElevatedButton.icon(
                  onPressed: () => _runWarGame('deep'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('运行深度'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyAlchemyCard() {
    final internshipCount = _strategyStatus['internship_count'] ?? 0;
    final grayCount = _strategyStatus['gray_count'] ?? 0;
    return Card(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.factory, size: 28, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                const Text('策略炼金炉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/strategy_library');
                  },
                  child: const Text('查看详情', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('实习中', internshipCount),
                _buildStatItem('灰度中', grayCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogAnalysisButton() {
    return Card(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.analytics, size: 32, color: Color(0xFFD4AF37)),
        title: const Text('日志分析', style: TextStyle(color: Colors.white)),
        subtitle: const Text('搜索、导出、上传日志，支持千寻诊断', style: TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LogAnalysisPage()));
        },
      ),
    );
  }
}

class FixProgressDialog extends StatelessWidget {
  const FixProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: const Text('一键修复', style: TextStyle(color: Colors.white)),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在执行修复，请稍候...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}