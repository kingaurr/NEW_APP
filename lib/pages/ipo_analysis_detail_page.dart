// lib/pages/ipo_analysis_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

class IpoAnalysisDetailPage extends StatefulWidget {
  final String stockCode;
  const IpoAnalysisDetailPage({super.key, required this.stockCode});

  @override
  State<IpoAnalysisDetailPage> createState() => _IpoAnalysisDetailPageState();
}

class _IpoAnalysisDetailPageState extends State<IpoAnalysisDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic> _analysis = {};
  String _error = '';
  bool _isParticipating = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await ApiService.getIpoAnalysis(widget.stockCode);
      if (mounted) {
        setState(() {
          _analysis = data ?? {};
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

  Future<void> _participate() async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken(
      reason: '验证指纹以参与申购',
    );
    if (!authenticated) {
      _showMessage('指纹验证失败，操作取消', isError: true);
      return;
    }
    if (mounted) setState(() => _isParticipating = true);
    try {
      final result = await ApiService.participateIpo(widget.stockCode);
      if (mounted) {
        if (result['success'] == true) {
          _showMessage('已记录申购意向');
          setState(() {
            _analysis['decision'] = 'participated';
          });
        } else {
          _showMessage('操作失败: ${result['error'] ?? '未知错误'}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showMessage('异常: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isParticipating = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_analysis['stock_name'] ?? widget.stockCode),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _loadDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildMlPredictionCard(),
                      const SizedBox(height: 16),
                      _buildSellStrategyCard(),
                      const SizedBox(height: 24),
                      if (_analysis['decision'] == 'strong_buy' && _analysis['decision'] != 'participated')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isParticipating ? null : _participate,
                            icon: _isParticipating
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.attach_money),
                            label: Text(_isParticipating ? '处理中...' : '参与申购'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('基本信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 12),
            _buildInfoRow('股票代码', _analysis['stock_code']),
            _buildInfoRow('所属行业', _analysis['industry']),
            _buildInfoRow('行业景气度', _analysis['industry_score'] != null ? '${_analysis['industry_score']}分' : null),
            _buildInfoRow('竞争格局', _analysis['competition_score'] != null ? '${_analysis['competition_score']}分' : null),
            _buildInfoRow('财务健康', _analysis['financial_score'] != null ? '${_analysis['financial_score']}分' : null),
            _buildInfoRow('估值水平', _analysis['valuation_score'] != null ? '${_analysis['valuation_score']}分' : null),
            _buildInfoRow('市场情绪', _analysis['sentiment_score'] != null ? '${_analysis['sentiment_score']}分' : null),
            _buildInfoRow('机构参与度', _analysis['institution_score'] != null ? '${_analysis['institution_score']}分' : null),
            const Divider(height: 24),
            _buildInfoRow('综合评分', _analysis['overall_score'] != null ? '${_analysis['overall_score']}分' : null, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isBold = false}) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildMlPredictionCard() {
    final ml = _analysis['ml_prediction'] ?? {};
    if (ml.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('机器学习预测', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 12),
            _buildInfoRow('首日涨幅预测', ml['first_day_return']),
            _buildInfoRow('置信度', ml['confidence'] != null ? '${(ml['confidence'] * 100).toInt()}%' : null),
            _buildInfoRow('风险等级', ml['risk_level']),
          ],
        ),
      ),
    );
  }

  Widget _buildSellStrategyCard() {
    final strategy = _analysis['sell_strategy'];
    if (strategy == null) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('卖出策略建议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 12),
            Text(strategy, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}