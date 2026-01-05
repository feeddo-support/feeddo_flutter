import 'package:flutter/material.dart';
import '../../feeddo_client.dart';
import '../../models/task.dart';
import '../../theme/feeddo_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/task_details_sheet.dart';
import 'feeddo_chat_screen.dart';

class FeeddoTasksScreen extends StatefulWidget {
  final FeeddoTheme? theme;

  const FeeddoTasksScreen({
    super.key,
    this.theme,
  });

  @override
  State<FeeddoTasksScreen> createState() => _FeeddoTasksScreenState();
}

class _FeeddoTasksScreenState extends State<FeeddoTasksScreen> {
  late FeeddoTheme _theme;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<Task> _tasks = [];

  // Filters & Sort
  String _sortBy = 'time'; // 'time' or 'upvotes'
  String? _filterType; // null, 'feature', 'bug'
  bool _showMyTasksOnly = false;

  // Pagination
  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _theme = widget.theme ?? FeeddoTheme.light();
    _loadTasks(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadTasks(refresh: false);
    }
  }

  Future<void> _loadTasks({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        if (refresh) _tasks = [];
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final newTasks = await FeeddoInternal.instance.apiService.getTasks(
        userId: FeeddoInternal.instance.userId,
        page: _page,
        limit: _limit,
        sortBy: _sortBy,
        type: _filterType,
        createdByMe: _showMyTasksOnly ? true : null,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _tasks = newTasks;
          } else {
            _tasks.addAll(newTasks);
          }

          _hasMore = newTasks.length >= _limit;
          if (_hasMore) _page++;

          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (refresh) {
            _error = e.toString();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load more tasks: ${e.toString()}'),
                backgroundColor: _theme.colors.error,
              ),
            );
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _createNewTask() async {
    // Navigate to chat screen with a specific message for feature request/bug report
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FeeddoChatScreen(
          conversation: null,
          theme: _theme,
          initialMessage:
              'Describe about any feature you want to see in our app or report a bug.\nI will create it for you!',
        ),
      ),
    );
    // Refresh tasks when returning
    _loadTasks(refresh: true);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _theme.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _theme.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Sort By
                Text('Sort By',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _theme.colors.textPrimary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFilterChip(
                      label: 'Newest',
                      selected: _sortBy == 'time',
                      onSelected: (selected) {
                        if (selected) setSheetState(() => _sortBy = 'time');
                      },
                    ),
                    _buildFilterChip(
                      label: 'Most Upvoted',
                      selected: _sortBy == 'upvotes',
                      onSelected: (selected) {
                        if (selected) setSheetState(() => _sortBy = 'upvotes');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Type
                Text('Type',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _theme.colors.textPrimary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      selected: _filterType == null,
                      onSelected: (selected) {
                        if (selected) setSheetState(() => _filterType = null);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Features',
                      selected: _filterType == 'feature',
                      onSelected: (selected) {
                        if (selected)
                          setSheetState(() => _filterType = 'feature');
                      },
                    ),
                    _buildFilterChip(
                      label: 'Bugs',
                      selected: _filterType == 'bug',
                      onSelected: (selected) {
                        if (selected) setSheetState(() => _filterType = 'bug');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // My Tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Show created by me only',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _theme.colors.textPrimary)),
                    Switch(
                      value: _showMyTasksOnly,
                      onChanged: (value) {
                        setSheetState(() => _showMyTasksOnly = value);
                      },
                      activeThumbColor: _theme.colors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadTasks(refresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _theme.colors.primary,
                      foregroundColor:
                          _theme.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: _theme.colors.background,
      selectedColor: _theme.colors.primary,
      labelStyle: TextStyle(
        color: selected
            ? (_theme.isDark ? Colors.black : Colors.white)
            : _theme.colors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: _theme.isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? _theme.colors.primary : _theme.colors.border,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.colors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: 48,
          height: 48,
          child: FloatingActionButton(
            onPressed: _createNewTask,
            backgroundColor: _theme.colors.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: Icon(Icons.add,
                size: 20, color: _theme.isDark ? Colors.black : Colors.white),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: _theme.colors.appBarBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: _theme.colors.iconColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Features & Bugs',
          style: TextStyle(
            color: _theme.colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.filter_list,
                    color: _theme.colors.iconColor, size: 20),
                if (_filterType != null ||
                    _showMyTasksOnly ||
                    _sortBy != 'time')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _theme.colors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: _theme.colors.divider.withOpacity(0.1),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _theme.colors.primary))
          : _error != null && _tasks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error',
                            style: TextStyle(color: _theme.colors.textPrimary)),
                        TextButton(
                          onPressed: () => _loadTasks(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('No tasks found',
                              style:
                                  TextStyle(color: _theme.colors.textPrimary)),
                          if (_filterType != null || _showMyTasksOnly)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _filterType = null;
                                  _showMyTasksOnly = false;
                                  _sortBy = 'time';
                                });
                                _loadTasks(refresh: true);
                              },
                              child: const Text('Clear Filters'),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadTasks(refresh: true),
                      color: _theme.colors.primary,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == _tasks.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _theme.colors.primary,
                                ),
                              ),
                            );
                          }
                          final task = _tasks[index];
                          return TaskCard(
                            task: task,
                            theme: _theme,
                            onTap: () {
                              TaskDetailsSheet.show(
                                context,
                                task: task,
                                theme: _theme,
                                onTaskUpdated: (updatedTask) {
                                  setState(() {
                                    _tasks[index] = updatedTask;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
