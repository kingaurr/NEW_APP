// lib/pages/trade_pool_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/trade_pool_item.dart';

/// AI交易池完整列表页面
/// 显示所有AI推荐的股票，支持搜索和筛选
class TradePoolPage extends StatefulWidget {
  const TradePoolPage({super.key});

  @override
  State<TradePoolPage> createState() => _TradePoolPageState();
}

class _TradePoolPageState extends State<TradePoolPage> {
  bool _isLoading = true;
  List<dynamic> _stocks = [];
  List<dynamic> _filteredStocks = [];
  String _searchKeyword = '';
  String _filterScore = 'all'; // all, high, medium, low
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getTradePool();
      // 使用统一提取函数，兼容 List 或 {stocks: [...]} 格式
      final stocksList = ApiService.extractList(result, key: 'stocks');
      setState(() {
        _stocks = stocksList;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('加载交易池失败: $e');
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

  void _onSearchChanged() {
    setState(() {
      _searchKeyword = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = List.from(_stocks);
    
    // 搜索筛选
    if (_searchKeyword.isNotEmpty) {
      filtered = filtered.where((stock) {
        final name = (stock['name'] ?? '').toLowerCase();
        final code = (stock['code'] ?? '').toLowerCase();
        final keyword = _searchKeyword.toLowerCase();
        return name.contains(keyword) || code.contains(keyword);
      }).toList();
    }
    
    // 得分筛选
    if (_filterScore != 'all') {
      filtered = filtered.where((stock) {
        final score = stock['score'] ?? 0.5;
        if (_filterScore == 'high') return score >= 0.8;
        if (_filterScore == 'medium') return score >= 0.6 && score < 0.8;
        if (_filterScore == 'low') return score < 0.6;
        return true;
      }).toList();
    }
    
    // 按得分排序
    filtered.sort((a, b) {
      final scoreA = a['score'] ?? 0;
      final scoreB = b['score'] ?? 0;
      return scoreB.compareTo(scoreA);
    });
    
    setState(() {
      _filteredStocks = filtered;
    });
  }

  String _getScoreFilterText() {
    switch (_filterScore) {
      case 'high':
        return '高分';
      case 'medium':
        return '中分';
      case 'low':
        return '低分';
      default:
        return '全部';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI交易池'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '搜索股票名称或代码',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
          ),
          
          // 筛选栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  '筛选:',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('全部', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('高分(≥80)', 'high'),
                const SizedBox(width: 8),
                _buildFilterChip('中分(60-79)', 'medium'),
                const SizedBox(width: 8),
                _buildFilterChip('低分(<60)', 'low'),
                const Spacer(),
                Text(
                  '共${_filteredStocks.length}只',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 股票列表
          Expanded(
            child: _isLoading
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
                    : _filteredStocks.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无股票',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredStocks.length,
                            itemBuilder: (context, index) {
                              final stock = _filteredStocks[index];
                              return TradePoolItem(stock: stock); // 移除 onTrade
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterScore == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterScore = value;
          _applyFilters();
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: const Color(0xFFD4AF37),
      checkmarkColor: Colors.black,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部', style: TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: 'all',
                groupValue: _filterScore,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (value) {
                  setState(() {
                    _filterScore = value!;
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
              ),
            ),
            ListTile(
              title: const Text('高分 (≥80)', style: TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: 'high',
                groupValue: _filterScore,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (value) {
                  setState(() {
                    _filterScore = value!;
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
              ),
            ),
            ListTile(
              title: const Text('中分 (60-79)', style: TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: 'medium',
                groupValue: _filterScore,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (value) {
                  setState(() {
                    _filterScore = value!;
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
              ),
            ),
            ListTile(
              title: const Text('低分 (<60)', style: TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: 'low',
                groupValue: _filterScore,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (value) {
                  setState(() {
                    _filterScore = value!;
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}