// lib/widgets/alert_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

/// 主动提醒设置组件
/// 支持设置提醒开关、提醒时间、提醒类型
class AlertSettings extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const AlertSettings({super.key, this.onSettingsChanged});

  @override
  State<AlertSettings> createState() => _AlertSettingsState();
}

class _AlertSettingsState extends State<AlertSettings> {
  bool _enabled = true;
  bool _preMarketEnabled = true;
  bool _postMarketEnabled = true;
  bool _midDayEnabled = false;
  bool _nightReviewEnabled = true;
  bool _anomalyCheckEnabled = true;

  String _preMarketTime = '09:20';
  String _postMarketTime = '15:10';
  String _midDayTime = '12:00';
  String _nightReviewTime = '20:00';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _enabled = prefs.getBool('alert_enabled') ?? true;
      _preMarketEnabled = prefs.getBool('alert_pre_market') ?? true;
      _postMarketEnabled = prefs.getBool('alert_post_market') ?? true;
      _midDayEnabled = prefs.getBool('alert_mid_day') ?? false;
      _nightReviewEnabled = prefs.getBool('alert_night_review') ?? true;
      _anomalyCheckEnabled = prefs.getBool('alert_anomaly_check') ?? true;

      _preMarketTime = prefs.getString('alert_pre_market_time') ?? '09:20';
      _postMarketTime = prefs.getString('alert_post_market_time') ?? '15:10';
      _midDayTime = prefs.getString('alert_mid_day_time') ?? '12:00';
      _nightReviewTime = prefs.getString('alert_night_review_time') ?? '20:00';

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('alert_enabled', _enabled);
    await prefs.setBool('alert_pre_market', _preMarketEnabled);
    await prefs.setBool('alert_post_market', _postMarketEnabled);
    await prefs.setBool('alert_mid_day', _midDayEnabled);
    await prefs.setBool('alert_night_review', _nightReviewEnabled);
    await prefs.setBool('alert_anomaly_check', _anomalyCheckEnabled);

    await prefs.setString('alert_pre_market_time', _preMarketTime);
    await prefs.setString('alert_post_market_time', _postMarketTime);
    await prefs.setString('alert_mid_day_time', _midDayTime);
    await prefs.setString('alert_night_review_time', _nightReviewTime);

    widget.onSettingsChanged?.call();
  }

  Future<void> _selectTime(BuildContext context, String currentTime, Function(String) onSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(currentTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF2A2A2A),
              hourMinuteTextStyle: const TextStyle(color: Colors.white),
              dialHandColor: const Color(0xFFD4AF37),
              dialBackgroundColor: const Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onSelected(formatted);
      await _saveSettings();
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Widget _buildTimeTile(String title, String time, bool enabled, Function(String) onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        enabled ? '提醒时间: $time' : '已禁用',
        style: TextStyle(color: enabled ? Colors.grey : Colors.grey[600]),
      ),
      trailing: enabled
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _selectTime(context, time, onChanged),
                  child: const Text('修改', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : null,
      onTap: () {
        if (enabled) {
          _selectTime(context, time, onChanged);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 总开关
        Card(
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            title: const Text(
              '主动提醒',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              '开启后系统将在特定时间主动播报提醒',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            value: _enabled,
            activeColor: const Color(0xFFD4AF37),
            onChanged: (value) async {
              setState(() {
                _enabled = value;
              });
              await _saveSettings();
            },
          ),
        ),

        if (_enabled) ...[
          const SizedBox(height: 8),

          // 开盘前提醒
          Card(
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('开盘前提醒', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('每日开盘前播报系统状态', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  value: _preMarketEnabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) async {
                    setState(() {
                      _preMarketEnabled = value;
                    });
                    await _saveSettings();
                  },
                ),
                if (_preMarketEnabled)
                  _buildTimeTile('', _preMarketTime, _preMarketEnabled, (time) {
                    setState(() {
                      _preMarketTime = time;
                    });
                  }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 收盘后提醒
          Card(
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('收盘后提醒', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('每日收盘后播报今日绩效', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  value: _postMarketEnabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) async {
                    setState(() {
                      _postMarketEnabled = value;
                    });
                    await _saveSettings();
                  },
                ),
                if (_postMarketEnabled)
                  _buildTimeTile('', _postMarketTime, _postMarketEnabled, (time) {
                    setState(() {
                      _postMarketTime = time;
                    });
                  }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 午间提醒
          Card(
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('午间提醒', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('午间播报上午行情小结', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  value: _midDayEnabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) async {
                    setState(() {
                      _midDayEnabled = value;
                    });
                    await _saveSettings();
                  },
                ),
                if (_midDayEnabled)
                  _buildTimeTile('', _midDayTime, _midDayEnabled, (time) {
                    setState(() {
                      _midDayTime = time;
                    });
                  }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 晚间复盘提醒
          Card(
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('晚间复盘提醒', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('晚间播报复盘建议', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  value: _nightReviewEnabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) async {
                    setState(() {
                      _nightReviewEnabled = value;
                    });
                    await _saveSettings();
                  },
                ),
                if (_nightReviewEnabled)
                  _buildTimeTile('', _nightReviewTime, _nightReviewEnabled, (time) {
                    setState(() {
                      _nightReviewTime = time;
                    });
                  }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 盘中异常检测
          Card(
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text('盘中异常检测', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                '实时检测异常行情并主动播报',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              value: _anomalyCheckEnabled,
              activeColor: const Color(0xFFD4AF37),
              onChanged: (value) async {
                setState(() {
                  _anomalyCheckEnabled = value;
                });
                await _saveSettings();
              },
            ),
          ),

          const SizedBox(height: 16),

          // 测试提醒按钮
          Center(
            child: OutlinedButton.icon(
              onPressed: () async {
                // TODO: 调用后端测试提醒接口
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('测试提醒已发送')),
                );
              },
              icon: const Icon(Icons.volume_up, size: 18),
              label: const Text('测试提醒'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4AF37),
                side: const BorderSide(color: Color(0xFFD4AF37)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}