// lib/widgets/upgrade_status_card.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../pages/system_upgrade_page.dart';

/// 首页/我的页面 - 系统升级状态卡片
/// 显示当前版本、是否有待升级，点击跳转到系统升级页面
class UpgradeStatusCard extends StatefulWidget {
  const UpgradeStatusCard({super.key});

  @override
  State<UpgradeStatusCard> createState() => _UpgradeStatusCardState();
}

class _UpgradeStatusCardState extends State<UpgradeStatusCard> {
  Map<String, dynamic> _status = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.getSystemUpgradeStatus();
      if (mounted) {
        setState(() {
          _status = data ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
    }
    final currentVersion = _status['current_version'] ?? 'v1.0.0';
    final hasUpgrade = _status['has_upgrade'] == true;
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemUpgradePage()));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasUpgrade ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  hasUpgrade ? Icons.system_update : Icons.check_circle,
                  color: hasUpgrade ? Colors.orange : Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '系统版本 $currentVersion',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasUpgrade ? '有新版本可用，点击升级' : '已是最新版本',
                      style: TextStyle(fontSize: 12, color: hasUpgrade ? Colors.orange : Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}