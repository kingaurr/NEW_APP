// lib/pages/cost_detail_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';

/// API成本详情页面
class CostDetailPage extends StatefulWidget {
  const CostDetailPage({super.key});

  @override
  State<CostDetailPage> createState() => _CostDetailPageState();
}

class _CostDetailPageState extends State<CostDetailPage> {
  bool _isLoading = true;
  String? _error;
  
  // 成本统计数据
  double _todayCost = 0;
  double _monthCost = 0;
  double _totalCost = 0;
  double _dailyBudget = 0;
  double _monthlyBudget = 0;
  
  // 成本趋势数据（近7天）
  List<FlSpot> _costSpots = [];
  double _maxCost = 0;
  List<String> _dateLabels = [];

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
      // 获取当前成本统计
      final costData = await ApiService.getCosts();
      if (costData != null) {
        _todayCost = (costData['today'] ?? 0).toDouble();
        _monthCost = (costData['month'] ?? 0).toDouble();
        _totalCost = (costData['total'] ?? 0).toDouble();
      }

      // 获取预算配置
      final budgetData = await ApiService.getBudgetConfig();
      if (budgetData != null) {
        _dailyBudget = (budgetData['daily_budget'] ?? 0).toDouble();
        _monthlyBudget = (budgetData['monthly_budget'] ?? 0).toDouble();
      }

      // 尝试从日报历史构建成本趋势（近7天）
      await _loadCostTrend();

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

  Future<void> _loadCostTrend() async {
    // 通过获取近7天的日报数据来构建成本趋势
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _dateLabels.add('${date.month}/${date.day}');
      
      try {
        final report = await ApiService.getDailyReportByDate(dateStr);
        if (report != null) {
          final cost = (report['cost_today'] ?? 0).toDouble();
          _costSpots.add(FlSpot((6 - i).toDouble(), cost));
          if (cost > _maxCost) _maxCost = cost;
        } else {
          _costSpots.add(FlSpot((6 - i).toDouble(), 0));
        }
      } catch (e) {
        _costSpots.add(FlSpot((6 - i).toDouble(), 0));
      }
    }
    if (_maxCost == 0) _maxCost = 10; // 默认最大值
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('API成本详情'),
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
          // 成本概览卡片
          _buildOverviewCard(),
          const SizedBox(height: 20),
          
          // 预算使用进度
          _buildBudgetProgress(),
          const SizedBox(height: 20),
          
          // 成本趋势图表
          _buildTrendChart(),
          const SizedBox(height: 20),
          
          // 模型调用明细（预留，后续对接）
          _buildModelUsageCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
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
            '成本概览',
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
              _buildCostItem('今日成本', _todayCost, Icons.today),
              _buildCostItem('本月成本', _monthCost, Icons.calendar_month),
              _buildCostItem('累计成本', _totalCost, Icons.summarize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem(String label, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '¥${value.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetProgress() {
    final dailyPercent = _dailyBudget > 0 ? (_todayCost / _dailyBudget).clamp(0.0, 1.0) : 0.0;
    final monthlyPercent = _monthlyBudget > 0 ? (_monthCost / _monthlyBudget).clamp(0.0, 1.0) : 0.0;
    
    Color dailyColor;
    if (dailyPercent < 0.7) {
      dailyColor = Colors.green;
    } else if (dailyPercent < 0.9) {
      dailyColor = Colors.orange;
    } else {
      dailyColor = Colors.red;
    }
    
    Color monthlyColor;
    if (monthlyPercent < 0.7) {
      monthlyColor = Colors.green;
    } else if (monthlyPercent < 0.9) {
      monthlyColor = Colors.orange;
    } else {
      monthlyColor = Colors.red;
    }

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
            '预算使用进度',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 日预算
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text('今日', style: TextStyle(color: Colors.white70)),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: dailyPercent,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(dailyColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '¥${_todayCost.toStringAsFixed(2)} / ¥${_dailyBudget.toStringAsFixed(2)}',
                  style: TextStyle(color: dailyColor, fontSize: 12),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 月预算
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text('本月', style: TextStyle(color: Colors.white70)),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: monthlyPercent,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(monthlyColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '¥${_monthCost.toStringAsFixed(2)} / ¥${_monthlyBudget.toStringAsFixed(2)}',
                  style: TextStyle(color: monthlyColor, fontSize: 12),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
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
            '近7日成本趋势',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _costSpots.isEmpty
                ? const Center(
                    child: Text(
                      '暂无趋势数据',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
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
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < _dateLabels.length) {
                                return Text(
                                  _dateLabels[index],
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
                            reservedSize: 50,
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
                      maxX: 6,
                      minY: 0,
                      maxY: _maxCost * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _costSpots,
                          isCurved: true,
                          color: const Color(0xFFD4AF37),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
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
                          getTooltipColor: (touchedSpot) => const Color(0xFF1E1E1E),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '¥${spot.y.toStringAsFixed(2)}',
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

  Widget _buildModelUsageCard() {
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
            '模型调用明细',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '详细调用记录开发中，敬请期待',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}