// lib/pages/risk_settings_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 风控参数设置页面
/// 支持设置止损比例、止盈比例、最大仓位、风控基准资金、预警级别等
class RiskSettingsPage extends StatefulWidget {
  const RiskSettingsPage({super.key});

  @override
  State<RiskSettingsPage> createState() => _RiskSettingsPageState();
}

class _RiskSettingsPageState extends State<RiskSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  double _stopLossRatio = 0.03;
  double _takeProfitRatio = 0.05;
  double _maxPositionRatio = 0.2;
  double _riskBaseFund = 200000.0;
  double _currentFund = 0.0;
  String _alertLevel = 'none';
  String _fuseStatus = 'normal';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getRiskParams(),
        ApiService.getRiskBaseFund(),
        ApiService.getFund(),
        ApiService.getFuseStatus(),
      ]);

      if (results[0] != null) {
        setState(() {
          _stopLossRatio = results[0]['stop_loss_ratio'] ?? 0.03;
          _takeProfitRatio = results[0]['take_profit_ratio'] ?? 0.05;
          _maxPositionRatio = results[0]['max_position_ratio'] ?? 0.2;
        });
      }
      
      if (results[1] != null) {
        setState(() {
          _riskBaseFund = results[1]['base_fund'] ?? 200000.0;
        });
      }
      
      if (results[2] != null) {
        setState(() {
          _currentFund = results[2]['total'] ?? 0.0;
        });
      }
      
      if (results[3] != null) {
        setState(() {
          _alertLevel = results[3]['level'] ?? 'none';
          _fuseStatus = results[3]['status'] ?? 'normal';
        });
      }
    } catch (e) {
      debugPrint('加载风控设置失败: $e');
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

  Future<void> _saveSettings() async {
    // 指纹验证
    final authenticated = await BiometricsHelper.authenticateForOperation(
      operation: 'modify_risk_params',
      operationDesc: '修改风控参数',
    );
    
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证失败，无法保存'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ApiService.updateRiskParams({
        'stop_loss_ratio': _stopLossRatio,
        'take_profit_ratio': _takeProfitRatio,
        'max_position_ratio': _maxPositionRatio,
      });

      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('风控参数已保存'), backgroundColor: Colors.green),
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

  Future<void> _saveBaseFund() async {
    final authenticated = await BiometricsHelper.authenticateForOperation(
      operation: 'modify_risk_params',
      operationDesc: '修改风控基准资金',
    );
    
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证失败，无法保存'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ApiService.updateRiskBaseFund(_riskBaseFund);

      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('风控基准资金已保存'), backgroundColor: Colors.green),
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

  String _formatNumber(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(2)}亿';
    } else if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  String _getAlertLevelText(String level) {
    switch (level) {
      case 'yellow':
        return '黄色预警';
      case 'orange':
        return '橙色预警';
      case 'red':
        return '红色预警';
      default:
        return '无预警';
    }
  }

  Color _getAlertLevelColor(String level) {
    switch (level) {
      case 'yellow':
        return Colors.orange;
      case 'orange':
        return Colors.deepOrange;
      case 'red':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _getFuseStatusText(String status) {
    switch (status) {
      case 'fuse':
        return '已熔断';
      case 'warning':
        return '预警';
      default:
        return '正常';
    }
  }

  Color _getFuseStatusColor(String status) {
    switch (status) {
      case 'fuse':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _showBaseFundDialog() {
    final controller = TextEditingController(text: _riskBaseFund.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('设置风控基准资金', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '基准资金（元）',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '当前资金: ¥${_formatNumber(_currentFund)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() {
                  _riskBaseFund = value;
                });
                Navigator.pop(context);
                _saveBaseFund();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效金额'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('风控设置'),
        backgroundColor: const Color(0xFF1E1E1E),
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
                        onPressed: _loadData,
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
                      // 预警状态卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getAlertLevelColor(_alertLevel).withOpacity(0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: _getAlertLevelColor(_alertLevel),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '当前预警状态',
                                          style: TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                        Text(
                                          _getAlertLevelText(_alertLevel),
                                          style: TextStyle(
                                            color: _getAlertLevelColor(_alertLevel),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getFuseStatusColor(_fuseStatus).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getFuseStatusText(_fuseStatus),
                                      style: TextStyle(
                                        color: _getFuseStatusColor(_fuseStatus),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 风控参数卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '风控参数',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSliderRow(
                                label: '止损比例',
                                value: _stopLossRatio,
                                min: 0.01,
                                max: 0.1,
                                formatter: (v) => '${(v * 100).toInt()}%',
                                onChanged: (v) {
                                  setState(() {
                                    _stopLossRatio = v;
                                  });
                                },
                              ),
                              _buildSliderRow(
                                label: '止盈比例',
                                value: _takeProfitRatio,
                                min: 0.01,
                                max: 0.2,
                                formatter: (v) => '${(v * 100).toInt()}%',
                                onChanged: (v) {
                                  setState(() {
                                    _takeProfitRatio = v;
                                  });
                                },
                              ),
                              _buildSliderRow(
                                label: '最大仓位',
                                value: _maxPositionRatio,
                                min: 0.05,
                                max: 0.5,
                                formatter: (v) => '${(v * 100).toInt()}%',
                                onChanged: (v) {
                                  setState(() {
                                    _maxPositionRatio = v;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveSettings,
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
                                      : const Text('保存参数'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 风控基准资金卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '风控基准资金',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '基准资金',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '¥${_formatNumber(_riskBaseFund)}',
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '当前资金',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '¥${_formatNumber(_currentFund)}',
                                    style: TextStyle(
                                      color: _currentFund >= _riskBaseFund ? Colors.green : Colors.orange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (_currentFund < _riskBaseFund) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '当前资金低于基准资金，请注意风险控制',
                                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isSaving ? null : _showBaseFundDialog,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFD4AF37),
                                    side: const BorderSide(color: Color(0xFFD4AF37)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('修改基准资金'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String Function(double) formatter,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              Text(
                formatter(value),
                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: const Color(0xFFD4AF37),
            inactiveColor: Colors.grey[700],
            divisions: 100,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}