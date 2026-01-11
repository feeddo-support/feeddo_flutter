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

class _FeeddoTasksScreenState extends State<FeeddoTasksScreen> with SingleTickerProviderStateMixin {
  late FeeddoTheme _theme;
  late TabController _tabController;
  
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Initial load
    _loadTasks(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    
    String? newType;
    switch (_tabController.index) {
      case 0: newType = null; break;
      case 1: newType = 'feature'; break;
      case 2: newType = 'bug'; break;
    }

    if (_filterType != newType) {
      setState(() {
        _filterType = newType;
        _isLoading = true; // Show loading immediately
      });
      _loadTasks(refresh: true);
    }
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
                  'Sort & Filter',
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
                      label: 'Newest First',
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
                    child: const Text('Apply Changes'),
                  ),
                ),
                const SizedBox(height: 20),
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
      selectedColor: _theme.colors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected
            ? _theme.colors.primary
            : _theme.colors.textPrimary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: _theme.colors.primary,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTask,
        backgroundColor: _theme.colors.primary,
        elevation: 4,
        icon: Icon(Icons.add,
            color: _theme.isDark ? Colors.black : Colors.white),
        label: Text(
          'New Post',
          style: TextStyle(
            color: _theme.isDark ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          )
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: _theme.colors.appBarBackground,
            title: Text(
              'Community Board',
              style: TextStyle(
                color: _theme.colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _theme.colors.iconColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.tune_rounded, color: _theme.colors.iconColor),
                onPressed: _showFilterSheet,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelColor: _theme.colors.primary,
              unselectedLabelColor: _theme.colors.textSecondary,
              indicatorColor: _theme.colors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Features'),
                Tab(text: 'Bugs'),
              ],
            ),
            pinned: true,
            floating: true,
          ),
        ],
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: _theme.colors.primary))
            : _error != null && _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: _theme.colors.error),
                        const SizedBox(height: 16),
                        Text('Something went wrong',
                            style: TextStyle(color: _theme.colors.textPrimary, fontWeight: FontWeight.bold)),
                        Text(_error!, style: TextStyle(color: _theme.colors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadTasks(refresh: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _theme.colors.primary
                          ),
                          child: Text('Retry', style: TextStyle(color: _theme.isDark ? Colors.black : Colors.white)),
                        ),
                      ],
                    ),
                  )
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: _theme.colors.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text('No posts found',
                                style: TextStyle(
                                  color: _theme.colors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                )
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to create one!',
                              style: TextStyle(color: _theme.colors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadTasks(refresh: true),
                        color: _theme.colors.primary,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: _tasks.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
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
      ),
    );
  }
}
