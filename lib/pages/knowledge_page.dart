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
    final theme = Theme.of(context);
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
            _buildRulesTab(theme),
            _buildCasesTab(theme),
            _buildFailuresTab(theme),
            _buildConfigTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesTab(ThemeData theme) {
    return FutureBuilder<List<dynamic>>(
      future: _rulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              '加载失败: ${snapshot.error ?? '未知错误'}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          );
        }
        final rules = snapshot.data!;
        if (rules.isEmpty) {
          return Center(
            child: Text(
              '暂无规则',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自动生成规则',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...rules.map((rule) => _buildRuleItem(
                      theme,
                      rule['id'] ?? '未知',
                      rule['desc'] ?? '',
                      rule['winRate'] ?? '0%',
                      rule['status'] ?? '未知',
                      _getStatusColor(theme, rule['status']),
                    )).toList(),
                    const Divider(),
                    Text(
                      '冲突检测结果',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (rules.any((r) => r['status'] == '冲突'))
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: theme.colorScheme.errorContainer,
                        child: Text(
                          '部分规则存在逻辑冲突，建议调整',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: theme.colorScheme.primaryContainer,
                        child: Text(
                          '未检测到规则冲突',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                        ),
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

  Widget _buildCasesTab(ThemeData theme) {
    return FutureBuilder<List<dynamic>>(
      future: _casesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              '加载失败: ${snapshot.error ?? '未知错误'}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          );
        }
        final cases = snapshot.data!;
        if (cases.isEmpty) {
          return Center(
            child: Text(
              '暂无案例',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        // 分离牛股案例和惨案（根据 type 字段）
        final goodCases = cases.where((c) => c['type'] == 'good').toList();
        final badCases = cases.where((c) => c['type'] == 'bad').toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '牛股基因案例',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...goodCases.map((c) => _buildCaseItem(
                      theme,
                      c['title'] ?? '',
                      c['date'] ?? '',
                      c['desc'] ?? '',
                      Icons.trending_up,
                      theme.colorScheme.primary,
                    )).toList(),
                    const SizedBox(height: 16),
                    Text(
                      '惨案特征',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...badCases.map((c) => _buildCaseItem(
                      theme,
                      c['title'] ?? '',
                      c['date'] ?? '',
                      c['desc'] ?? '',
                      Icons.trending_down,
                      theme.colorScheme.error,
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

  Widget _buildFailuresTab(ThemeData theme) {
    return FutureBuilder<List<dynamic>>(
      future: _failuresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              '加载失败: ${snapshot.error ?? '未知错误'}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          );
        }
        final failures = snapshot.data!;
        if (failures.isEmpty) {
          return Center(
            child: Text(
              '暂无亏损案例',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '亏损案例归因',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...failures.map((f) => _buildFailureItem(
                      theme,
                      f['code'] ?? '',
                      f['date'] ?? '',
                      f['reason'] ?? '',
                      '亏损 ¥${f['loss'] ?? 0}',
                    )).toList(),
                    const Divider(),
                    Text(
                      '相似案例提示',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (failures.any((f) => f['similar'] != null))
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: theme.colorScheme.secondaryContainer,
                        child: Text(
                          failures.firstWhere((f) => f['similar'] != null)['similar'] ?? '无提示',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: theme.colorScheme.primaryContainer,
                        child: Text(
                          '暂无相似案例提示',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                        ),
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

  Widget _buildConfigTab(ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              '加载失败: ${snapshot.error ?? '未知错误'}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          );
        }
        final config = snapshot.data!;
        final experts = config['experts'] as List<dynamic>? ?? [];
        final books = config['books'] as List<dynamic>? ?? [];
        final keywords = config['keywords'] as List<dynamic>? ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '专家白名单',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...experts.map((e) => _buildConfigItem(
                      theme,
                      e['name'] ?? '',
                      e['detail'] ?? '',
                      e['status'] ?? '',
                    )).toList(),
                    const Divider(),
                    Text(
                      '书籍规则库',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...books.map((b) => _buildConfigItem(
                      theme,
                      b['name'] ?? '',
                      b['detail'] ?? '',
                      b['status'] ?? '',
                    )).toList(),
                    const Divider(),
                    Text(
                      '动态关键词库',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...keywords.map((k) => _buildConfigItem(
                      theme,
                      k['name'] ?? '',
                      k['detail'] ?? '',
                      k['weight'] != null ? '权重 ${k['weight']}' : '',
                    )).toList(),
                    const SizedBox(height: 16),
                    Text(
                      '知识统计',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _knowledgeStatsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || snapshot.data == null) {
                          return Text(
                            '加载失败',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                          );
                        }
                        final data = snapshot.data!;
                        return Column(
                          children: [
                            _infoRow(theme, '总条目', '${data['total_entries'] ?? 0}'),
                            _infoRow(theme, '向量库大小', '${data['vector_size'] ?? 0} MB'),
                            _infoRow(theme, '最近新增', '${data['new_today'] ?? 0}条'),
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

  Widget _buildRuleItem(ThemeData theme, String id, String desc, String winRate, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$id: $desc', style: theme.textTheme.bodyMedium),
                Text(winRate, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseItem(ThemeData theme, String title, String date, String desc, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(date, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(desc, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureItem(ThemeData theme, String code, String date, String reason, String loss) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('$date $reason', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(loss, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
        ],
      ),
    );
  }

  Widget _buildConfigItem(ThemeData theme, String name, String detail, String status) {
    final bool isPositive = status.contains('启用') || status.contains('导入');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium),
                Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPositive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, String status) {
    switch (status) {
      case '生效':
        return theme.colorScheme.primary;
      case '冲突':
        return theme.colorScheme.error;
      case '待验证':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}