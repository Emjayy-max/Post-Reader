import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

import 'main.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const String apiUrl = 'https://jsonplaceholder.typicode.com/posts';

  final TextEditingController searchController = TextEditingController();

  List<dynamic> posts = [];
  bool isLoading = true;
  bool isError = false;
  String message = '';
  String query = '';
  int selectedTab = 0;
  int selectedCategory = -1; // -1 means all categories

  Box get favoritesBox => Hive.box('favoritesBox');

  List<dynamic> get filteredPosts {
    final List<dynamic> source;

    if (selectedTab == 1) {
      source = favoritesBox.values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      source = posts;
    }

    List<dynamic> list = source;

    if (selectedCategory >= 0) {
      list = list
          .where((post) => categoryIndexOf(post['id']) == selectedCategory)
          .toList();
    }

    final search = query.trim().toLowerCase();
    if (search.isEmpty) return list;

    return list.where((post) {
      final title = (post['title'] ?? '').toString().toLowerCase();
      final body = (post['body'] ?? '').toString().toLowerCase();
      return title.contains(search) || body.contains(search);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchPosts(); // async GET request started from initState
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// GET request. 200 -> parse with jsonDecode, otherwise show an error.
  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
      isError = false;
      message = '';
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          posts = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          message = 'Unable to load articles. HTTP ${response.statusCode}.';
        });
        if (posts.isNotEmpty) _toast(message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isError = true;
        message = 'Connection failed. Check your internet.';
      });
      if (posts.isNotEmpty) _toast(message);
    }
  }

  /// POST request. Returns null on success (201), or an error message.
  Future<String?> _publish(String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );

      if (response.statusCode != 201) {
        return 'Failed to publish the post. HTTP ${response.statusCode}.';
      }
      if (!mounted) return null;

      // The demo API does not store posts, so add it to the local list.
      final nextId = posts.fold<int>(0, (maxId, p) {
            final id = p['id'];
            return id is int && id > maxId ? id : maxId;
          }) +
          1;

      setState(() {
        posts.insert(0, {
          'id': nextId,
          'title': title,
          'body': body,
          'userId': 1,
        });
        selectedTab = 0;
        selectedCategory = -1;
      });
      return null;
    } catch (_) {
      return 'Failed to publish the post. Check your connection.';
    }
  }

  Future<void> createPost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CreatePostDialog(onSubmit: _publish),
    );
    if (ok == true) _toast('Post published successfully!');
  }

  void openDetails(dynamic post) {
    Navigator.pushNamed(
      context,
      '/details',
      arguments: {
        'id': post['id'],
        'title': post['title'],
        'body': post['body'],
      },
    );
  }

  void openFavorites() {
    Navigator.pushNamed(context, '/favorites');
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 18) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  int _readMinutes(String body) {
    final text = body.trim();
    if (text.isEmpty) return 1;
    final words = text.split(RegExp(r'\s+')).length;
    return words <= 200 ? 1 : (words / 200).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: favoritesBox.listenable(),
      builder: (context, box, _) {
        final favIds =
            box.values.whereType<Map>().map((e) => e['id']).toSet();
        final items = filteredPosts;
        final showFavs = selectedTab == 1;

        final loadingAll = !showFavs && isLoading && posts.isEmpty;
        final errorAll = !showFavs && isError && posts.isEmpty;
        final hasItems = !loadingAll && !errorAll && items.isNotEmpty;

        return Scaffold(
          backgroundColor: pageBackground,
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              tooltip: 'Menu',
              onPressed: _showMenu,
              icon: const Icon(Icons.menu_rounded, size: 26),
            ),
            title: const Text('Post Reader'),
            actions: [
              // AppBar button that opens the Favorites screen.
              IconButton(
                tooltip: 'Favorites',
                onPressed: openFavorites,
                icon: Badge(
                  isLabelVisible: favIds.isNotEmpty,
                  label: Text('${favIds.length}'),
                  child: const Icon(Icons.favorite_border_rounded, size: 25),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pad = constraints.maxWidth > 760
                    ? (constraints.maxWidth - 720) / 2
                    : 20.0;

                return RefreshIndicator(
                  onRefresh: fetchPosts,
                  color: brandBlue,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(pad, 6, pad, 110),
                    itemCount: hasItems ? items.length + 1 : 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _header(items.length, favIds.length);
                      }

                      if (!hasItems) {
                        return _stateView(loadingAll, errorAll, showFavs);
                      }

                      final post = items[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _animatedIn(
                          _articleCard(
                            post,
                            showFavs || favIds.contains(post['id']),
                          ),
                          index - 1,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x445B5BD6),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: createPost,
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.edit_rounded),
              label: const Text(
                'New post',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: lineColor)),
            ),
            child: NavigationBar(
              height: 68,
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: softBlue,
              selectedIndex: 0,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    setState(() => selectedTab = 0);
                    break;
                  case 1:
                    openFavorites();
                    break;
                  case 2:
                    if (posts.isNotEmpty) {
                      openDetails(posts.first);
                    } else {
                      _toast('No articles to read yet.');
                    }
                    break;
                  case 3:
                    _showProfile();
                    break;
                }
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded, color: brandBlue),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: favIds.isNotEmpty,
                    label: Text('${favIds.length}'),
                    child: const Icon(Icons.favorite_border_rounded),
                  ),
                  label: 'Favorites',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  label: 'Reading',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Loading, error or empty content shown under the header.
  Widget _stateView(bool loadingAll, bool errorAll, bool showFavs) {
    if (loadingAll) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: brandBlue)),
      );
    }

    if (errorAll) {
      return _emptyState(
        Icons.cloud_off_rounded,
        'Unable to load articles',
        message,
        action: FilledButton.icon(
          onPressed: fetchPosts,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }

    final noFilters = query.trim().isEmpty && selectedCategory < 0;

    return _emptyState(
      showFavs ? Icons.favorite_border_rounded : Icons.search_off_rounded,
      showFavs && noFilters ? 'No favorites yet' : 'No articles found',
      showFavs && noFilters
          ? 'Open an article and save it to your favorites.'
          : 'Try another keyword or category.',
    );
  }

  /// Fades and slides a child in when it first appears.
  Widget _animatedIn(Widget child, int index) {
    final delayed = index < 6 ? index : 0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delayed * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _header(int resultCount, int savedCount) {
    final showFavs = selectedTab == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(savedCount),
        const SizedBox(height: 20),
        TextField(
          controller: searchController,
          onChanged: (value) => setState(() => query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search articles...',
            prefixIcon: const Icon(Icons.search_rounded, color: secondaryText),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      searchController.clear();
                      setState(() => query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFECECF5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _segment(
                'All posts',
                Icons.article_outlined,
                !showFavs,
                () => setState(() => selectedTab = 0),
              ),
              _segment(
                'Favorites',
                Icons.favorite_border_rounded,
                showFavs,
                () => setState(() => selectedTab = 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(
                'All',
                Icons.apps_rounded,
                selectedCategory == -1,
                primaryText,
                () => setState(() => selectedCategory = -1),
              ),
              for (var i = 0; i < postCategories.length; i++)
                _chip(
                  postCategories[i].name,
                  postCategories[i].icon,
                  selectedCategory == i,
                  postCategories[i].color,
                  () => setState(() => selectedCategory = i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              showFavs ? 'Saved articles' : 'Latest articles',
              style: const TextStyle(
                color: primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Text(
              '$resultCount ${resultCount == 1 ? 'result' : 'results'}',
              style: const TextStyle(color: secondaryText, fontSize: 12),
            ),
          ],
        ),
        if (isLoading && posts.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              minHeight: 3,
              color: brandBlue,
              backgroundColor: softBlue,
            ),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _hero(int savedCount) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandBlue, brandViolet],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x445B5BD6),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: _circle(160, const Color(0x1FFFFFFF)),
            ),
            Positioned(
              right: 40,
              bottom: -60,
              child: _circle(120, const Color(0x14FFFFFF)),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'What will you\nread today?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _heroStat('${posts.length}', 'Articles'),
                      const SizedBox(width: 10),
                      _heroStat('$savedCount', 'Saved'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed:
                        posts.isEmpty ? null : () => openDetails(posts.first),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: brandBlue,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.auto_stories_rounded, size: 18),
                    label: const Text('Start reading'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _heroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x1417233C),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? brandBlue : secondaryText),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? primaryText : secondaryText,
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    IconData icon,
    bool active,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : lineColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Article card built around a ListTile.
  Widget _articleCard(dynamic post, bool saved) {
    final title = _cap((post['title'] ?? 'Untitled').toString());
    final body = (post['body'] ?? '').toString();
    final category = postCategories[categoryIndexOf(post['id'])];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lineColor),
        boxShadow: softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => openDetails(post),
          isThreeLine: true,
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: category.tint,
            child: Icon(category.icon, color: category.color, size: 22),
          ),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        color: category.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '  ·  ${_readMinutes(body)} min read',
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved ? brandBlue : secondaryText,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(
    IconData icon,
    String title,
    String subtitle, {
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: softBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: brandBlue, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryText,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: secondaryText, height: 1.5),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: softBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: brandBlue, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuTile(Icons.article_outlined, 'All posts', () {
              Navigator.pop(sheetContext);
              setState(() => selectedTab = 0);
            }),
            _menuTile(Icons.favorite_border_rounded, 'My favorites', () {
              Navigator.pop(sheetContext);
              openFavorites();
            }),
            _menuTile(Icons.refresh_rounded, 'Refresh posts', () {
              Navigator.pop(sheetContext);
              fetchPosts();
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showProfile() {
    final saved = favoritesBox.length;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [brandBlue, brandViolet],
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Reader Profile',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your personal reading space',
                style: TextStyle(color: secondaryText),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _stat('${posts.length}', 'Articles'),
                  const SizedBox(width: 12),
                  _stat('$saved', 'Saved'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: pageBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: lineColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: secondaryText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog with title and body fields (neither may be empty).
/// It owns its controllers, so they are disposed safely.
class _CreatePostDialog extends StatefulWidget {
  const _CreatePostDialog({required this.onSubmit});

  /// Returns null on success, or an error message.
  final Future<String?> Function(String title, String body) onSubmit;

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  bool submitting = false;
  String? errorText;

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      submitting = true;
      errorText = null;
    });

    final error = await widget.onSubmit(
      titleController.text.trim(),
      bodyController.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        submitting = false;
        errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_rounded, color: brandBlue, size: 21),
          ),
          const SizedBox(width: 12),
          const Text(
            'Create a post',
            style: TextStyle(color: primaryText, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                TextFormField(
                  controller: titleController,
                  enabled: !submitting,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Post title',
                    hintText: 'Enter your article title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bodyController,
                  enabled: !submitting,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Article content',
                    hintText: 'Write something...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Content is required.';
                    }
                    return null;
                  },
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: dangerRed, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: submitting ? null : _submit,
          icon: submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(submitting ? 'Publishing...' : 'Publish post'),
        ),
      ],
    );
  }
}