// lib/pages/fund_curve_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';

/// 资金曲线全屏页面
class FundCurvePage extends StatefulWidget {
  const FundCurvePage({super.key});

  @override
  State<FundCurvePage> createState() => _FundCurvePageState();
}

class _FundCurvePageState extends State<FundCurvePage> {
  bool _isLoading = true;
  String? _error;
  
  // 资金曲线数据
  List<FlSpot> _spots = [];
  double _maxFund = 0;
  double _minFund = double.infinity;
  
  // 统计摘要
  double _totalAsset = 0;
  double _totalReturn = 0;
  double _returnRate = 0;
  double _maxDrawdown = 0;
  String _dateRange = '';

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
      // 1. 获取当前资产
      final fundData = await ApiService.getFund();
      if (fundData != null) {
        _totalAsset = (fundData['current_fund'] ?? 0).toDouble();
      }

      // 2. 获取日报数据（包含资金曲线）
      final reportData = await ApiService.getDailyReport();
      if (reportData != null) {
        final fundCurve = reportData['fund_curve'] as List<dynamic>? ?? [];
        
        if (fundCurve.isNotEmpty) {
          // 解析资金曲线
          for (int i = 0; i < fundCurve.length; i++) {
            final item = fundCurve[i] as Map<String, dynamic>;
            final fund = (item['fund'] ?? 0).toDouble();
            _spots.add(FlSpot(i.toDouble(), fund));
            if (fund > _maxFund) _maxFund = fund;
            if (fund < _minFund) _minFund = fund;
          }

          // 计算收益率和最大回撤
          if (_spots.isNotEmpty) {
            final startFund = _spots.first.y;
            final endFund = _spots.last.y;
            _totalReturn = endFund - startFund;
            _returnRate = startFund > 0 ? (endFund - startFund) / startFund * 100 : 0;

            // 简单最大回撤计算
            double peak = _spots.first.y;
            double maxDrawdown = 0;
            for (final spot in _spots) {
              if (spot.y > peak) peak = spot.y;
              final drawdown = (peak - spot.y) / peak;
              if (drawdown > maxDrawdown) maxDrawdown = drawdown;
            }
            _maxDrawdown = maxDrawdown * 100;
          }

          // 日期范围
          final startDate = reportData['start_date'] ?? '';
          final endDate = reportData['end_date'] ?? '';
          _dateRange = '$startDate ~ $endDate';
        }

        // 如果曲线数据为空，尝试用当前资产作为唯一点
        if (_spots.isEmpty && _totalAsset > 0) {
          _spots = [FlSpot(0, _totalAsset)];
          _maxFund = _totalAsset;
          _minFund = _totalAsset;
        }
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('资金曲线'),
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
          // 统计卡片
          _buildStatsCard(),
          const SizedBox(height: 20),
          // 资金曲线图表
          _buildChartCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '资产概览',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _dateRange,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '总资产',
                '¥${_totalAsset.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
              ),
              _buildStatItem(
                '累计盈亏',
                '${_totalReturn >= 0 ? '+' : ''}¥${_totalReturn.toStringAsFixed(2)}',
                _totalReturn >= 0 ? Icons.trending_up : Icons.trending_down,
                color: _totalReturn >= 0 ? Colors.green : Colors.red,
              ),
              _buildStatItem(
                '收益率',
                '${_returnRate >= 0 ? '+' : ''}${_returnRate.toStringAsFixed(2)}%',
                _returnRate >= 0 ? Icons.trending_up : Icons.trending_down,
                color: _returnRate >= 0 ? Colors.green : Colors.red,
              ),
              _buildStatItem(
                '最大回撤',
                '${_maxDrawdown.toStringAsFixed(2)}%',
                Icons.trending_down,
                color: Colors.red,
              ),
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

  Widget _buildChartCard() {
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
            '净值走势',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _spots.isEmpty
                ? const Center(
                    child: Text(
                      '暂无资金曲线数据',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: _maxFund > _minFund ? (_maxFund - _minFund) / 5 : 1000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white10,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.white10,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _spots.length > 10 ? (_spots.length / 5).floorToDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < _spots.length) {
                                return Text(
                                  '${value.toInt() + 1}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            interval: _maxFund > _minFund ? (_maxFund - _minFund) / 5 : 1000,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '¥${value.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_spots.length - 1).toDouble(),
                      minY: _minFund * 0.99,
                      maxY: _maxFund * 1.01,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: const Color(0xFFD4AF37),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: _spots.length <= 30,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: const Color(0xFFD4AF37),
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
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
                                '¥${spot.y.toStringAsFixed(2)}\n第${spot.x.toInt() + 1}日',
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
}