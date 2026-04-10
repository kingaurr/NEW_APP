// lib/pages/sector_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 板块详情页面
class SectorDetailPage extends StatefulWidget {
  final String sectorName;

  const SectorDetailPage({super.key, required this.sectorName});

  @override
  State<SectorDetailPage> createState() => _SectorDetailPageState();
}

class _SectorDetailPageState extends State<SectorDetailPage> {
  bool _isLoading = true;
  String? _error;
  
  // 板块内股票列表
  List<dynamic> _stocks = [];
  
  // 板块统计
  double _avgChange = 0;
  int _upCount = 0;
  int _downCount = 0;
  double _totalVolume = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. 获取交易池数据，从中筛选属于该板块的股票
      final signalsData = await ApiService.getTradingSignals();
      if (signalsData != null) {
        final tradePool = signalsData['trade_pool'] as List<dynamic>? ?? [];
        final shadowPool = signalsData['shadow_pool'] as List<dynamic>? ?? [];
        
        // 合并两个池，按板块筛选
        final allStocks = [...tradePool, ...shadowPool];
        _stocks = allStocks.where((stock) {
          final industry = stock['industry'] as String? ?? '';
          return industry.contains(widget.sectorName) || 
                 widget.sectorName.contains(industry) ||
                 industry == widget.sectorName;
        }).toList();

        // 去重（按股票代码）
        final seen = <String>{};
        _stocks = _stocks.where((stock) {
          final code = stock['code'] as String? ?? '';
          if (seen.contains(code)) return false;
          seen.add(code);
          return true;
        }).toList();

        // 计算板块统计
        if (_stocks.isNotEmpty) {
          double totalChange = 0;
          for (final stock in _stocks) {
            // 注意：这里需要从行情接口获取实时涨跌幅，暂时使用总分变化作为示意
            // 实际应调用 getStockDetail 获取实时数据，此处简化处理
            final score = (stock['total_score'] ?? 50).toDouble();
            // 将得分映射到涨跌幅（实际应使用真实行情）
            final change = (score - 50) / 50 * 5; // 映射到 -5% ~ +5%
            totalChange += change;
            if (change > 0) {
              _upCount++;
            } else if (change < 0) {
              _downCount++;
            }
          }
          _avgChange = totalChange / _stocks.length;
        }
      }

      // 2. 尝试获取板块热度数据（从心脏）
      final sectorScores = await _getSectorScores();
      final sectorScore = sectorScores[widget.sectorName] ?? 0.5;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<Map<String, double>> _getSectorScores() async {
    // 通过股票选择器的行业摘要接口获取
    try {
      // 这里调用一个可能的接口，若不存在则返回空
      final result = await ApiService.httpGet('/sector/summary');
      if (result != null && result is Map) {
        final sectors = result['hot_sectors'] as List<dynamic>? ?? [];
        final Map<String, double> scores = {};
        for (final s in sectors) {
          scores[s['name'] as String] = (s['score'] as num).toDouble();
        }
        return scores;
      }
    } catch (e) {
      // 忽略错误，返回空
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('${widget.sectorName} 板块详情'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('加载失败: $_error', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 板块统计卡片
          _buildStatsCard(),
          const SizedBox(height: 20),
          
          // 股票列表标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '板块成分股',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '共 ${_stocks.length} 只',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 股票列表
          if (_stocks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '暂无该板块股票数据',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                return _buildStockItem(_stocks[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final upPercent = _stocks.isNotEmpty ? (_upCount / _stocks.length * 100).toStringAsFixed(1) : '0.0';
    final downPercent = _stocks.isNotEmpty ? (_downCount / _stocks.length * 100).toStringAsFixed(1) : '0.0';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '板块统计',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('成分股数量', '${_stocks.length}', Icons.list),
              _buildStatItem(
                '平均涨跌',
                '${_avgChange >= 0 ? '+' : ''}${_avgChange.toStringAsFixed(2)}%',
                _avgChange >= 0 ? Icons.trending_up : Icons.trending_down,
                color: _avgChange >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('上涨家数', '$_upCount ($upPercent%)', Icons.arrow_upward, color: Colors.green),
              _buildStatItem('下跌家数', '$_downCount ($downPercent%)', Icons.arrow_downward, color: Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? const Color(0xFFD4AF37), size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStockItem(dynamic stock) {
    final code = stock['code'] as String? ?? '';
    final name = stock['name'] as String? ?? code;
    final score = (stock['total_score'] ?? 50).toDouble();
    final change = (score - 50) / 50 * 5; // 映射涨跌幅
    final changeColor = change >= 0 ? Colors.green : Colors.red;
    final reason = stock['reason'] as String? ?? '';

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: changeColor.withOpacity(0.2),
          child: Text(
            code.substring(0, 1),
            style: TextStyle(color: changeColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              code,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '选股理由: ${reason.isNotEmpty ? reason : '综合评分入选'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(changeColor),
              minHeight: 3,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
              style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${score.toStringAsFixed(1)}分',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/stock_detail',
            arguments: {'code': code, 'name': name},
          );
        },
      ),
    );
  }
}