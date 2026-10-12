import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'main.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _saveFavorite(
    BuildContext context,
    dynamic id,
    String title,
    String body,
  ) async {
    try {
      final box = Hive.box('favoritesBox');

      if (box.containsKey(id)) {
        _showMessage(context, 'This article is already in your favorites.');
        return;
      }

      await box.put(id, {
        'id': id,
        'title': title,
        'body': body,
        'note': '',
      });

      if (!context.mounted) return;

      _showMessage(context, 'Article saved to favorites!');
    } catch (error) {
      debugPrint('Save favorite error: $error');

      if (!context.mounted) return;

      _showMessage(context, 'Unable to save article. Please try again.');
    }
  }

  Widget _missingArguments(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: softBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.article_outlined,
                  size: 42,
                  color: brandBlue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Article not found',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please go back to the posts list and select an article '
                'to view its details.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to posts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safely retrieve arguments instead of casting null to Map.
    final routeArguments =
        ModalRoute.of(context)?.settings.arguments;

    if (routeArguments is! Map) {
      return _missingArguments(context);
    }

    final args = Map<String, dynamic>.from(routeArguments);

    final dynamic id = args['id'];
    final String title = (args['title'] ?? '').toString();
    final String body = (args['body'] ?? '').toString();

    if (id == null || title.isEmpty) {
      return _missingArguments(context);
    }

    final category = postCategories[categoryIndexOf(id)];
    final box = Hive.box('favoritesBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article details'),
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'My favorites',
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
            icon: const Icon(Icons.bookmark_border_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ValueListenableBuilder<Box>(
            valueListenable: box.listenable(),
            builder: (context, favoritesBox, child) {
              final bool isSaved = favoritesBox.containsKey(id);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Article header.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [brandBlue, brandViolet],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x245B5BD6),
                            blurRadius: 22,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.icon,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'ARTICLE $id',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title[0].toUpperCase() + title.substring(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white70,
                                size: 17,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Post Reader',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'ARTICLE CONTENT',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: lineColor),
                        boxShadow: softShadow,
                      ),
                      child: SelectableText(
                        body.isEmpty
                            ? 'No content is available for this article.'
                            : body,
                        style: const TextStyle(
                          color: primaryText,
                          fontSize: 16,
                          height: 1.9,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save to Favorites.
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: isSaved
                            ? null
                            : () => _saveFavorite(
                                  context,
                                  id,
                                  title,
                                  body,
                                ),
                        icon: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_add_outlined,
                        ),
                        label: Text(
                          isSaved
                              ? 'Already in Favorites'
                              : 'Save to Favorites',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: brandBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: softBlue,
                          disabledForegroundColor: brandBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/favorites');
                        },
                        icon: const Icon(Icons.bookmarks_outlined),
                        label: const Text('View My Favorites'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brandBlue,
                          side: const BorderSide(color: lineColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}