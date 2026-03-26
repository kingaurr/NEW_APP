// lib/pages/war_game_history_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 红蓝军历史记录页面
/// 显示所有红蓝军对抗历史，支持查看详情
class WarGameHistoryPage extends StatefulWidget {
  const WarGameHistoryPage({super.key});

  @override
  State<WarGameHistoryPage> createState() => _WarGameHistoryPageState();
}

class _WarGameHistoryPageState extends State<WarGameHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _lightGames = [];
  List<dynamic> _deepGames = [];
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
        ApiService.getLightWarGameHistory(),
        ApiService.getDeepWarGameHistory(),
      ]);

      if (results[0] != null && results[0]['games'] != null) {
        setState(() {
          _lightGames = results[0]['games'];
        });
      }
      
      if (results[1] != null && results[1]['games'] != null) {
        setState(() {
          _deepGames = results[1]['games'];
        });
      }
    } catch (e) {
      debugPrint('加载红蓝军历史失败: $e');
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.substring(0, 16);
    }
  }

  String _getWinnerText(String winner) {
    if (winner == 'blue') return '蓝军胜';
    if (winner == 'red') return '红军胜';
    return '平局';
  }

  Color _getWinnerColor(String winner) {
    if (winner == 'blue') return Colors.blue;
    if (winner == 'red') return Colors.red;
    return Colors.grey;
  }

  void _showDetailDialog(Map<String, dynamic> game, bool isLight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          isLight ? '轻量对抗详情' : '深度对抗详情',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('时间', _formatDate(game['timestamp'])),
              const Divider(color: Colors.grey),
              _buildDetailRow('市场状态', game['market_style'] ?? '震荡'),
              const Divider(color: Colors.grey),
              _buildDetailRow('蓝军收益', '${(game['blue_return'] ?? 0) >= 0 ? '+' : ''}${((game['blue_return'] ?? 0) * 100).toStringAsFixed(2)}%'),
              const Divider(color: Colors.grey),
              _buildDetailRow('红军收益', '${(game['red_return'] ?? 0) >= 0 ? '+' : ''}${((game['red_return'] ?? 0) * 100).toStringAsFixed(2)}%'),
              const Divider(color: Colors.grey),
              _buildDetailRow('胜者', _getWinnerText(game['winner'] ?? '')),
              if (!isLight && game['scenario'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('场景', game['scenario']),
              ],
              if (!isLight && game['conclusion'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('结论', game['conclusion']),
              ],
              if (game['suggestion'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('建议', game['suggestion']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('红蓝军历史'),
          backgroundColor: const Color(0xFF1E1E1E),
          bottom: const TabBar(
            tabs: [
              Tab(text: '轻量对抗'),
              Tab(text: '深度对抗'),
            ],
            labelColor: Color(0xFFD4AF37),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFD4AF37),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
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
                : TabBarView(
                    children: [
                      // 轻量对抗列表
                      _buildGameList(_lightGames, true),
                      // 深度对抗列表
                      _buildGameList(_deepGames, false),
                    ],
                  ),
      ),
    );
  }

  Widget _buildGameList(List<dynamic> games, bool isLight) {
    if (games.isEmpty) {
      return const Center(
        child: Text(
          '暂无记录',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final winner = game['winner'] ?? '';
        final blueReturn = game['blue_return'] ?? 0;
        final redReturn = game['red_return'] ?? 0;
        final timestamp = game['timestamp'];

        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getWinnerColor(winner).withOpacity(0.3),
            ),
          ),
          child: InkWell(
            onTap: () => _showDetailDialog(game, isLight),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getWinnerColor(winner).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          winner == 'blue'
                              ? Icons.shield
                              : (winner == 'red' ? Icons.flash_on : Icons.remove),
                          color: _getWinnerColor(winner),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(timestamp),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '市场: ${game['market_style'] ?? '震荡'}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getWinnerColor(winner).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getWinnerText(winner),
                          style: TextStyle(
                            color: _getWinnerColor(winner),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildReturnCard('蓝军', blueReturn, Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildReturnCard('红军', redReturn, Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReturnCard(String name, double ret, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            '${ret >= 0 ? '+' : ''}${(ret * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              color: ret >= 0 ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}