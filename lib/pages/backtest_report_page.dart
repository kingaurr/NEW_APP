// lib/pages/backtest_report_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';

/// 回测报告页面
class BacktestReportPage extends StatefulWidget {
  final String strategyId;

  const BacktestReportPage({super.key, required this.strategyId});

  @override
  State<BacktestReportPage> createState() => _BacktestReportPageState();
}

class _BacktestReportPageState extends State<BacktestReportPage> {
  bool _isLoading = true;
  String? _error;
  
  // 策略详情
  Map<String, dynamic>? _strategyDetail;
  Map<String, dynamic>? _performanceMetrics;
  List<dynamic>? _performanceCurve;
  
  // 曲线数据
  List<FlSpot> _equitySpots = [];
  List<FlSpot> _drawdownSpots = [];
  double _maxEquity = 0;
  double _minEquity = double.infinity;
  double _minDrawdown = 0;

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
      // 获取策略详情（包含回测指标和曲线）
      final detail = await ApiService.getStrategyDetail(widget.strategyId);
      if (detail != null) {
        _strategyDetail = detail['detail'] as Map<String, dynamic>?;
        _performanceMetrics = detail['metrics'] as Map<String, dynamic>?;
        _performanceCurve = detail['performance_curve'] as List<dynamic>?;
        
        // 解析资金曲线
        if (_performanceCurve != null && _performanceCurve!.isNotEmpty) {
          for (int i = 0; i < _performanceCurve!.length; i++) {
            final item = _performanceCurve![i] as Map<String, dynamic>;
            final equity = (item['equity'] ?? item['value'] ?? 0).toDouble();
            _equitySpots.add(FlSpot(i.toDouble(), equity));
            if (equity > _maxEquity) _maxEquity = equity;
            if (equity < _minEquity) _minEquity = equity;
            
            // 计算回撤（如果有回撤字段则直接使用，否则计算）
            var drawdown = (item['drawdown'] ?? 0).toDouble();
            if (drawdown == 0 && i > 0) {
              // 简单计算：当前净值相对于历史最高点的回撤
              double peak = _equitySpots.first.y;
              for (int j = 0; j <= i; j++) {
                if (_equitySpots[j].y > peak) peak = _equitySpots[j].y;
              }
              drawdown = peak > 0 ? (peak - equity) / peak * 100 : 0;
            }
            _drawdownSpots.add(FlSpot(i.toDouble(), -drawdown));
            if (-drawdown < _minDrawdown) _minDrawdown = -drawdown;
          }
        }
        
        // 确保有合理的最小/最大值
        if (_maxEquity == 0) _maxEquity = 100000;
        if (_minEquity == double.infinity) _minEquity = _maxEquity * 0.9;
        if (_minDrawdown == 0) _minDrawdown = -20;
      }
      
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

  @override
  Widget build(BuildContext context) {
    final strategyName = _strategyDetail?['name'] ?? widget.strategyId;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('$strategyName - 回测报告'),
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
          // 核心指标卡片
          _buildMetricsCard(),
          const SizedBox(height: 20),
          
          // 资金曲线
          _buildEquityCurveCard(),
          const SizedBox(height: 20),
          
          // 回撤曲线
          _buildDrawdownCurveCard(),
          const SizedBox(height: 20),
          
          // 其他统计信息
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    final metrics = _performanceMetrics ?? {};
    final winRate = (metrics['win_rate'] ?? 0).toDouble();
    final sharpe = (metrics['sharpe_ratio'] ?? 0).toDouble();
    final maxDrawdown = (metrics['max_drawdown'] ?? 0).toDouble();
    final totalTrades = metrics['total_trades'] ?? 0;
    final profitFactor = (metrics['profit_factor'] ?? 0).toDouble();
    final totalReturn = (metrics['total_return'] ?? 0).toDouble();

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
            '核心指标',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            children: [
              _buildMetricItem('总收益率', '${totalReturn >= 0 ? '+' : ''}${totalReturn.toStringAsFixed(2)}%', 
                  totalReturn >= 0 ? Colors.green : Colors.red),
              _buildMetricItem('胜率', '${(winRate * 100).toStringAsFixed(1)}%', 
                  winRate >= 0.5 ? Colors.green : Colors.orange),
              _buildMetricItem('盈亏比', profitFactor.toStringAsFixed(2), 
                  profitFactor >= 1.5 ? Colors.green : Colors.orange),
              _buildMetricItem('夏普比率', sharpe.toStringAsFixed(2), 
                  sharpe >= 1.0 ? Colors.green : Colors.orange),
              _buildMetricItem('最大回撤', '${maxDrawdown.toStringAsFixed(2)}%', Colors.red),
              _buildMetricItem('交易次数', totalTrades.toString(), Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color valueColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEquityCurveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '资金曲线',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _equitySpots.isEmpty
                ? const Center(
                    child: Text(
                      '暂无回测数据',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(color: Colors.white10, strokeWidth: 1);
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(color: Colors.white10, strokeWidth: 1);
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _equitySpots.length > 10 ? (_equitySpots.length / 5).floorToDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < _equitySpots.length) {
                                return Text('$idx', style: const TextStyle(color: Colors.white54, fontSize: 10));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_equitySpots.length - 1).toDouble(),
                      minY: _minEquity * 0.98,
                      maxY: _maxEquity * 1.02,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _equitySpots,
                          isCurved: true,
                          color: const Color(0xFFD4AF37),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: const Color(0xFF1E1E1E),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(2)}',
                                const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawdownCurveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '回撤曲线',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _drawdownSpots.isEmpty
                ? const Center(
                    child: Text(
                      '暂无回撤数据',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(color: Colors.white10, strokeWidth: 1);
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(color: Colors.white10, strokeWidth: 1);
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _drawdownSpots.length > 10 ? (_drawdownSpots.length / 5).floorToDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < _drawdownSpots.length) {
                                return Text('$idx', style: const TextStyle(color: Colors.white54, fontSize: 10));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(-value).toStringAsFixed(1)}%',
                                style: const TextStyle(color: Colors.red, fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_drawdownSpots.length - 1).toDouble(),
                      minY: _minDrawdown * 1.05,
                      maxY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _drawdownSpots,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withOpacity(0.15),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: const Color(0xFF1E1E1E),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${(-spot.y).toStringAsFixed(2)}%',
                                const TextStyle(color: Colors.red, fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final metrics = _performanceMetrics ?? {};
    final avgWin = (metrics['avg_win'] ?? 0).toDouble();
    final avgLoss = (metrics['avg_loss'] ?? 0).toDouble();
    final maxConsecutiveWins = metrics['max_consecutive_wins'] ?? 0;
    final maxConsecutiveLosses = metrics['max_consecutive_losses'] ?? 0;
    final startDate = _strategyDetail?['created_at'] ?? '未知';
    final endDate = _strategyDetail?['updated_at'] ?? '未知';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '详细统计',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('平均盈利', '¥${avgWin.toStringAsFixed(2)}'),
          _buildStatRow('平均亏损', '¥${avgLoss.toStringAsFixed(2)}'),
          _buildStatRow('最长连续盈利', '$maxConsecutiveWins 次'),
          _buildStatRow('最长连续亏损', '$maxConsecutiveLosses 次'),
          const Divider(color: Colors.white24),
          _buildStatRow('回测开始', startDate),
          _buildStatRow('回测结束', endDate),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}