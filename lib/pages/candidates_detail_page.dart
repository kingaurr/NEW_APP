// lib/pages/candidates_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 候选股票详情页面
/// 显示股票的技术指标、基本面信息、AI评分详情
class CandidatesDetailPage extends StatefulWidget {
  final Map<String, dynamic> stock;

  const CandidatesDetailPage({super.key, required this.stock});

  @override
  State<CandidatesDetailPage> createState() => _CandidatesDetailPageState();
}

class _CandidatesDetailPageState extends State<CandidatesDetailPage> {
  bool _isLoading = true;
  bool _isBuying = false;
  Map<String, dynamic> _detail = {};
  final TextEditingController _sharesController = TextEditingController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _sharesController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getStockDetail(widget.stock['code']);
      if (result != null) {
        setState(() {
          _detail = result;
        });
      } else {
        setState(() {
          _errorMessage = '获取股票详情失败';
        });
      }
    } catch (e) {
      debugPrint('加载股票详情失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightBlue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Future<void> _buyStock() async {
    final sharesText = _sharesController.text.trim();
    if (sharesText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入买入数量'), backgroundColor: Colors.red),
      );
      return;
    }

    final shares = int.tryParse(sharesText);
    if (shares == null || shares <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的数量'), backgroundColor: Colors.red),
      );
      return;
    }

    final currentPrice = _detail['current_price'] ?? widget.stock['current_price'] ?? 0.0;
    final totalAmount = currentPrice * shares;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认买入', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要买入 ${widget.stock['name']} (${widget.stock['code']}) 吗？\n'
          '当前价: ¥${currentPrice.toStringAsFixed(2)}\n'
          '数量: ${shares}股\n'
          '预估金额: ¥${_formatNumber(totalAmount)}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('买入'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isBuying = true;
    });

    try {
      // 修复：ApiService.buyStock 需要三个位置参数，返回 bool
      final success = await ApiService.buyStock(
        widget.stock['code'],
        shares,
        currentPrice,
      );

      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('买入成功'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('买入失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('买入失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.stock['code'] ?? '';
    final name = widget.stock['name'] ?? '';
    final currentPrice = _detail['current_price'] ?? widget.stock['current_price'] ?? 0.0;
    final changePercent = _detail['change_percent'] ?? widget.stock['change_percent'] ?? 0.0;
    final score = _detail['score'] ?? widget.stock['score'] ?? 0.5;
    final reason = _detail['reason'] ?? widget.stock['reason'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('$name ($code)'),
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
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.grey),
                      ),
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
                      // 价格卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '当前价格',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '¥${currentPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
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
                                      '涨跌幅',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: changePercent >= 0 ? Colors.green : Colors.red,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // AI评分卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI综合评分',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CircularProgressIndicator(
                                          value: score,
                                          backgroundColor: Colors.grey[800],
                                          color: _getScoreColor(score),
                                          strokeWidth: 8,
                                        ),
                                        Center(
                                          child: Text(
                                            '${(score * 100).toInt()}',
                                            style: TextStyle(
                                              color: _getScoreColor(score),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 六大凭证评分
                      if (_detail['factors'] != null)
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '六大凭证评分',
                                  style: TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._detail['factors'].entries.map((entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _getFactorName(entry.key),
                                                style: const TextStyle(color: Colors.white70),
                                              ),
                                              Text(
                                                '${(entry.value * 100).toInt()}分',
                                                style: TextStyle(
                                                  color: _getScoreColor(entry.value),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: entry.value,
                                            backgroundColor: Colors.grey[800],
                                            color: _getScoreColor(entry.value),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 技术指标
                      if (_detail['technical'] != null)
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '技术指标',
                                  style: TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildTechRow('PE', _detail['technical']['pe']?.toString() ?? '--'),
                                _buildTechRow('PB', _detail['technical']['pb']?.toString() ?? '--'),
                                _buildTechRow('ROE', _detail['technical']['roe'] != null ? '${(_detail['technical']['roe'] * 100).toInt()}%' : '--'),
                                _buildTechRow('换手率', _detail['technical']['turnover'] != null ? '${(_detail['technical']['turnover'] * 100).toInt()}%' : '--'),
                                _buildTechRow('量比', _detail['technical']['volume_ratio']?.toStringAsFixed(2) ?? '--'),
                                _buildTechRow('振幅', _detail['technical']['amplitude'] != null ? '${(_detail['technical']['amplitude'] * 100).toInt()}%' : '--'),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // 买入按钮
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            TextField(
                              controller: _sharesController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '买入数量（股）',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFD4AF37)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _isBuying ? null : _buyStock,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: _isBuying
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('买入'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _getFactorName(String key) {
    const names = {
      'logic': '逻辑因子',
      'capital': '资金因子',
      'profit': '盈亏比',
      'sentiment': '情绪因子',
      'history': '历史因子',
      'event': '事件因子',
    };
    return names[key] ?? key;
  }

  Widget _buildTechRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}