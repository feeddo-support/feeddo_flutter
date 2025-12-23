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
  final int _limit = 20;
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
      final newTasks = await Feeddo.instance.getTasks(
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
          _error = e.toString();
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
              'Describe about any bug or feature you would like to report.\nI will create it for you!',
        ),
      ),
    );
    // Refresh tasks when returning
    _loadTasks(refresh: true);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Sort By
              const Text('Sort By',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip(
                    label: 'Newest',
                    selected: _sortBy == 'time',
                    onSelected: (selected) {
                      if (selected) setSheetState(() => _sortBy = 'time');
                    },
                  ),
                  const SizedBox(width: 12),
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
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                    selected: _filterType == null,
                    onSelected: (selected) {
                      if (selected) setSheetState(() => _filterType = null);
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    label: 'Features',
                    selected: _filterType == 'feature',
                    onSelected: (selected) {
                      if (selected)
                        setSheetState(() => _filterType = 'feature');
                    },
                  ),
                  const SizedBox(width: 12),
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
                  const Text('Show created by me only',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Switch(
                    value: _showMyTasksOnly,
                    onChanged: (value) {
                      setSheetState(() => _showMyTasksOnly = value);
                    },
                    activeColor: Colors.black,
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
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
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
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? Colors.black : Colors.grey[300]!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton(
          onPressed: _createNewTask,
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Features & Bugs',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, color: Colors.black),
                if (_filterType != null ||
                    _showMyTasksOnly ||
                    _sortBy != 'time')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
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
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error',
                            style: const TextStyle(color: Colors.black)),
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
                          const Text('No tasks found',
                              style: TextStyle(color: Colors.black)),
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
                      color: Colors.black,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == _tasks.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }
                          final task = _tasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () {
                              TaskDetailsSheet.show(
                                context,
                                task: task,
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
