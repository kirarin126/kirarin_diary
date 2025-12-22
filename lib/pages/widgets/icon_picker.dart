import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// Iconify API 基础URL
const String _apiBaseUrl = 'https://api.iconify.design';

/// 彩色图标集前缀列表（这些图标不应用颜色滤镜）
const List<String> _colorfulPrefixes = [
  'fluent-emoji',
  'fluent-emoji-flat',
  'fluent-emoji-high-contrast',
  'noto',
  'noto-v1',
  'twemoji',
  'openmoji',
  'emojione',
  'emojione-v1',
  'fxemoji',
  'logos',
  'skill-icons',
  'vscode-icons',
  'file-icons',
  'devicon',
  'catppuccin',
];

/// 判断图标是否是彩色图标
bool isColorfulIcon(String iconName) {
  final prefix = iconName.split(':').first;
  return _colorfulPrefixes.any((p) => prefix.startsWith(p));
}

/// 获取图标的SVG URL
String getIconSvgUrl(String iconName, {String? color}) {
  final parts = iconName.split(':');
  if (parts.length != 2) return '';
  final prefix = parts[0];
  final name = parts[1];
  var url = '$_apiBaseUrl/$prefix/$name.svg';
  // 只有非彩色图标才添加颜色参数
  if (color != null && !isColorfulIcon(iconName)) {
    url += '?color=${Uri.encodeComponent(color)}';
  }
  return url;
}

/// 预设的热门图标列表 - 精简版，避免首次加载卡顿
const List<String> _popularIcons = [
  // 彩色 Emoji 图标（不应用颜色滤镜）
  'fluent-emoji-flat:heart-suit',
  'fluent-emoji-flat:star',
  'fluent-emoji-flat:fire',
  'fluent-emoji-flat:check-mark-button',
  'fluent-emoji-flat:water-wave',
  'fluent-emoji-flat:sun',
  'fluent-emoji-flat:crescent-moon',
  'fluent-emoji-flat:running-shoe',
  'noto:person-running',
  'noto:person-biking',
  'noto:person-swimming',
  'twemoji:books',
  'twemoji:laptop',
  'twemoji:musical-note',
  // MDI 常用图标
  'mdi:heart',
  'mdi:star',
  'mdi:check-circle',
  'mdi:alarm',
  'mdi:water',
  'mdi:fire',
  'mdi:run',
  'mdi:walk',
  'mdi:bike',
  'mdi:dumbbell',
  'mdi:book-open-page-variant',
  'mdi:pencil',
  'mdi:laptop',
  'mdi:music',
  'mdi:sleep',
  'mdi:weather-sunny',
];

/// 分页大小
const int _pageSize = 32;

/// 显示图标选择器对话框，返回选中的图标名称（格式: prefix:name）
Future<String?> showIconPicker(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _IconPickerContent(),
  );
}

class _IconPickerContent extends StatefulWidget {
  const _IconPickerContent();

  @override
  State<_IconPickerContent> createState() => _IconPickerContentState();
}

class _IconPickerContentState extends State<_IconPickerContent> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<String> _displayIcons = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _isSearching = false;
  String _currentQuery = '';
  int _totalResults = 0;
  int _currentStart = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    // 初始显示热门图标
    _displayIcons = List.from(_popularIcons);

    // 监听滚动以实现无限加载
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 接近底部，加载更多
      if (_hasMore && !_isLoadingMore && _isSearching) {
        _loadMore();
      }
    }
  }

  Future<void> _searchIcons(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _displayIcons = List.from(_popularIcons);
        _errorMessage = null;
        _currentQuery = '';
        _totalResults = 0;
        _currentStart = 0;
        _hasMore = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _errorMessage = null;
      _currentQuery = query;
      _currentStart = 0;
      _displayIcons = [];
    });

    try {
      final url = Uri.parse(
        '$_apiBaseUrl/search?query=${Uri.encodeComponent(query)}&limit=$_pageSize',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final icons =
            (data['icons'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final total = data['total'] as int? ?? icons.length;
        final limit = data['limit'] as int? ?? _pageSize;

        setState(() {
          _displayIcons = icons;
          _totalResults = total;
          _currentStart = icons.length;
          _hasMore = total == limit; // 如果返回数量等于limit，说明可能还有更多
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '搜索失败，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误，请检查网络连接';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final url = Uri.parse(
        '$_apiBaseUrl/search?query=${Uri.encodeComponent(_currentQuery)}&limit=64&start=$_currentStart',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final icons =
            (data['icons'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final total = data['total'] as int? ?? 0;
        final limit = data['limit'] as int? ?? 64;

        setState(() {
          _displayIcons.addAll(icons);
          _currentStart += icons.length;
          _hasMore = total == limit && icons.isNotEmpty;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
                const Text(
                  '选择图标',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 搜索栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索图标（英文，如：heart, emoji, run）',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchIcons('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                // 延迟搜索，避免频繁请求
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchIcons(value);
                  }
                });
              },
              onSubmitted: _searchIcons,
            ),
          ),
          const SizedBox(height: 8),

          // 提示文字
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _isSearching
                      ? '搜索结果${_totalResults > 0 ? " ($_currentStart/$_totalResults)" : ""}'
                      : '热门图标（含彩色Emoji）',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (_hasMore)
                  Text(
                    ' · 下滑加载更多',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 图标网格
          Expanded(child: _buildIconGrid()),
        ],
      ),
    );
  }

  Widget _buildIconGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE581A3)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _searchIcons(_searchController.text),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_displayIcons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '未找到匹配的图标',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              '试试搜索: heart, emoji, star, home',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _displayIcons.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多指示器
        if (index == _displayIcons.length) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE581A3),
              ),
            ),
          );
        }

        final iconName = _displayIcons[index];
        return _IconGridItem(
          iconName: iconName,
          onTap: () => Navigator.pop(context, iconName),
        );
      },
    );
  }
}

/// 单个图标网格项 - 使用懒加载
class _IconGridItem extends StatefulWidget {
  final String iconName;
  final VoidCallback onTap;

  const _IconGridItem({required this.iconName, required this.onTap});

  @override
  State<_IconGridItem> createState() => _IconGridItemState();
}

class _IconGridItemState extends State<_IconGridItem> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // 延迟加载，实现懒加载效果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final svgUrl = getIconSvgUrl(widget.iconName);
    final isColorful = isColorfulIcon(widget.iconName);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Tooltip(
          message: widget.iconName,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: _isVisible
                ? SvgPicture.network(
                    svgUrl,
                    width: 28,
                    height: 28,
                    // 彩色图标不应用颜色滤镜
                    colorFilter: isColorful
                        ? null
                        : const ColorFilter.mode(
                            Colors.black87,
                            BlendMode.srcIn,
                          ),
                    placeholderBuilder: (context) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const SizedBox(
      width: 28,
      height: 28,
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
