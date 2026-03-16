// lib/pages/knowledge_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({Key? key}) : super(key: key);

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>?>? _knowledgeStatsFuture;
  late Future<List<dynamic>> _rulesFuture;
  late Future<List<dynamic>> _casesFuture;
  late Future<List<dynamic>> _failuresFuture;
  late Future<Map<String, dynamic>> _configFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _knowledgeStatsFuture = ApiService.getKnowledgeStats();
      _rulesFuture = ApiService.getRules();
      _casesFuture = ApiService.getCases();
      _failuresFuture = ApiService.getFailures();
      _configFuture = ApiService.getConfig();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '规则库'),
            Tab(text: '案例库'),
            Tab(text: '痛苦记忆'),
            Tab(text: '外脑配置'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRulesTab(),
            _buildCasesTab(),
            _buildFailuresTab(),
            _buildConfigTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesTab() {
    return FutureBuilder<List<dynamic>>(
      future: _rulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}'));
        }
        final rules = snapshot.data!;
        if (rules.isEmpty) {
          return const Center(child: Text('暂无规则'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('自动生成规则', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...rules.map((rule) => _buildRuleItem(
                      rule['id'] ?? '未知',
                      rule['desc'] ?? '',
                      rule['winRate'] ?? '0%',
                      rule['status'] ?? '未知',
                      _getStatusColor(rule['status']),
                    )).toList(),
                    const Divider(),
                    const Text('冲突检测结果', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (rules.any((r) => r['status'] == '冲突'))
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.shade900.withOpacity(0.3),
                        child: const Text('部分规则存在逻辑冲突，建议调整'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.green.shade900.withOpacity(0.3),
                        child: const Text('未检测到规则冲突'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCasesTab() {
    return FutureBuilder<List<dynamic>>(
      future: _casesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}'));
        }
        final cases = snapshot.data!;
        if (cases.isEmpty) {
          return const Center(child: Text('暂无案例'));
        }
        // 分离牛股案例和惨案（根据 type 字段）
        final goodCases = cases.where((c) => c['type'] == 'good').toList();
        final badCases = cases.where((c) => c['type'] == 'bad').toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('牛股基因案例', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...goodCases.map((c) => _buildCaseItem(
                      c['title'] ?? '',
                      c['date'] ?? '',
                      c['desc'] ?? '',
                      Icons.trending_up,
                      Colors.green,
                    )).toList(),
                    const SizedBox(height: 16),
                    const Text('惨案特征', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...badCases.map((c) => _buildCaseItem(
                      c['title'] ?? '',
                      c['date'] ?? '',
                      c['desc'] ?? '',
                      Icons.trending_down,
                      Colors.red,
                    )).toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFailuresTab() {
    return FutureBuilder<List<dynamic>>(
      future: _failuresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}'));
        }
        final failures = snapshot.data!;
        if (failures.isEmpty) {
          return const Center(child: Text('暂无亏损案例'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('亏损案例归因', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...failures.map((f) => _buildFailureItem(
                      f['code'] ?? '',
                      f['date'] ?? '',
                      f['reason'] ?? '',
                      '亏损 ¥${f['loss'] ?? 0}',
                    )).toList(),
                    const Divider(),
                    const Text('相似案例提示', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (failures.any((f) => f['similar'] != null))
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.orange.shade900.withOpacity(0.3),
                        child: Text(failures.firstWhere((f) => f['similar'] != null)['similar'] ?? '无提示'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.green.shade900.withOpacity(0.3),
                        child: const Text('暂无相似案例提示'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfigTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}'));
        }
        final config = snapshot.data!;
        final experts = config['experts'] as List<dynamic>? ?? [];
        final books = config['books'] as List<dynamic>? ?? [];
        final keywords = config['keywords'] as List<dynamic>? ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('专家白名单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...experts.map((e) => _buildConfigItem(
                      e['name'] ?? '',
                      e['detail'] ?? '',
                      e['status'] ?? '',
                    )).toList(),
                    const Divider(),
                    const Text('书籍规则库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...books.map((b) => _buildConfigItem(
                      b['name'] ?? '',
                      b['detail'] ?? '',
                      b['status'] ?? '',
                    )).toList(),
                    const Divider(),
                    const Text('动态关键词库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...keywords.map((k) => _buildConfigItem(
                      k['name'] ?? '',
                      k['detail'] ?? '',
                      k['weight'] != null ? '权重 ${k['weight']}' : '',
                    )).toList(),
                    const SizedBox(height: 16),
                    const Text('知识统计', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _knowledgeStatsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || snapshot.data == null) {
                          return const Text('加载失败');
                        }
                        final data = snapshot.data!;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('总条目:'),
                                Text('${data['total_entries'] ?? 0}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('向量库大小:'),
                                Text('${data['vector_size'] ?? 0} MB'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('最近新增:'),
                                Text('${data['new_today'] ?? 0}条'),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRuleItem(String id, String desc, String winRate, String status, Color statusColor) {
    return ListTile(
      title: Text('$id: $desc'),
      subtitle: Text(winRate),
      trailing: Chip(label: Text(status), backgroundColor: statusColor.withOpacity(0.2), labelStyle: TextStyle(color: statusColor)),
      dense: true,
    );
  }

  Widget _buildCaseItem(String title, String date, String desc, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text('$date\n$desc'),
      isThreeLine: true,
    );
  }

  Widget _buildFailureItem(String code, String date, String reason, String loss) {
    return ListTile(
      leading: const Icon(Icons.error, color: Colors.red),
      title: Text(code),
      subtitle: Text('$date  $reason'),
      trailing: Text(loss, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildConfigItem(String name, String detail, String status) {
    return ListTile(
      title: Text(name),
      subtitle: Text(detail),
      trailing: Text(status, style: TextStyle(color: status.contains('启用') || status.contains('导入') ? Colors.green : Colors.white54)),
      dense: true,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '生效':
        return Colors.green;
      case '冲突':
        return Colors.red;
      case '待验证':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}