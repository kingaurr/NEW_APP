// lib/pages/ip_whitelist_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// IP白名单管理页面
/// 支持添加、删除、查看IP规则
class IPWhitelistPage extends StatefulWidget {
  const IPWhitelistPage({super.key});

  @override
  State<IPWhitelistPage> createState() => _IPWhitelistPageState();
}

class _IPWhitelistPageState extends State<IPWhitelistPage> {
  bool _isLoading = true;
  bool _enabled = true;
  String _mode = 'whitelist';
  bool _strictMode = false;
  List<Map<String, dynamic>> _rules = [];

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.ipWhitelistList();
      if (result != null) {
        setState(() {
          _enabled = result['enabled'] ?? true;
          _mode = result['mode'] ?? 'whitelist';
          _strictMode = result['strict_mode'] ?? false;
          _rules = List<Map<String, dynamic>>.from(result['rules'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('加载IP白名单失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.ipWhitelistSetMode(_mode);
      await ApiService.ipWhitelistSetStrictMode(_strictMode);
      await ApiService.ipWhitelistSetEnabled(_enabled);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存'), backgroundColor: Colors.green),
        );
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addRule() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入IP地址或模式'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.ipWhitelistAdd(
        ip,
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      );

      if (result?['success'] == true) {
        _ipController.clear();
        _reasonController.clear();
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已添加: $ip'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception(result?['message'] ?? '添加失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeRule(String pattern) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text('确定要删除规则 "$pattern" 吗？', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.ipWhitelistRemove(pattern);
      if (result?['success'] == true) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除: $pattern'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception(result?['message'] ?? '删除失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getPatternType(String pattern) {
    if (pattern.contains('/')) return 'CIDR网段';
    if (pattern.contains('*')) return '通配符';
    if (pattern == '127.0.0.1' || pattern == '::1' || pattern == 'localhost') return '本地回环';
    return '单一IP';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP白名单'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingsCard(),
                  const SizedBox(height: 16),
                  _buildAddRuleCard(),
                  const SizedBox(height: 16),
                  _buildRulesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'IP访问控制',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _enabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) {
                    setState(() {
                      _enabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('模式:', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'whitelist', label: Text('白名单')),
                    ButtonSegment(value: 'blacklist', label: Text('黑名单')),
                  ],
                  selected: {_mode},
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFFD4AF37);
                      }
                      return Colors.grey[800];
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.black;
                      }
                      return Colors.white;
                    }),
                  ),
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _mode = selection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('严格模式:', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                Switch(
                  value: _strictMode,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) {
                    setState(() {
                      _strictMode = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  '未匹配时拒绝访问',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRuleCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '添加规则',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'IP地址 / CIDR / 通配符',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: '例如: 192.168.1.1, 192.168.1.0/24, 192.168.*.*',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addRule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesList() {
    if (_rules.isEmpty) {
      return const Card(
        color: Color(0xFF2A2A2A),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              '暂无规则\n点击上方添加规则',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '规则列表',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        ..._rules.map((rule) => Card(
              color: const Color(0xFF2A2A2A),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getPatternIcon(rule['pattern']),
                  color: const Color(0xFFD4AF37),
                ),
                title: Text(
                  rule['pattern'],
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                ),
                subtitle: Text(
                  '类型: ${_getPatternType(rule['pattern'])}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeRule(rule['pattern']),
                ),
              ),
            )),
      ],
    );
  }

  IconData _getPatternIcon(String pattern) {
    if (pattern.contains('/')) return Icons.hub;
    if (pattern.contains('*')) return Icons.star;
    if (pattern == '127.0.0.1' || pattern == '::1' || pattern == 'localhost') {
      return Icons.home;
    }
    return Icons.computer;
  }
}