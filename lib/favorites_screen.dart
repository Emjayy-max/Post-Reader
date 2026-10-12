import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'main.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  void _toast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  String _cap(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void openDetails(Map post) {
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

  Future<void> deleteFavorite(dynamic key, Map post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Remove favorite?',
          style: TextStyle(
            color: primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Remove "${post['title']}" from your saved articles?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Hive.box('favoritesBox').delete(key);
      _toast('Favorite removed successfully.');
    } catch (error) {
      debugPrint('Delete favorite error: $error');
      _toast('Unable to remove favorite. Please try again.');
    }
  }

  Future<void> editNote(dynamic key, Map post) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(
        initialNote: (post['note'] ?? '').toString(),
      ),
    );

    if (result == null) return;

    try {
      final box = Hive.box('favoritesBox');
      final updatedPost = Map<String, dynamic>.from(post);

      updatedPost['note'] = result;

      await box.put(key, updatedPost);

      _toast('Personal note saved successfully.');
    } catch (error) {
      debugPrint('Save note error: $error');
      _toast('Unable to save the note. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('favoritesBox');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('My favorites'),
        actions: [
          IconButton(
            tooltip: 'Browse articles',
            onPressed: () {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
            },
            icon: const Icon(Icons.home_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ValueListenableBuilder<Box>(
        valueListenable: box.listenable(),
        builder: (context, favoritesBox, child) {
          final keys = favoritesBox.keys.toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                    child: _banner(keys.length),
                  ),
                  Expanded(
                    child: keys.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              28,
                            ),
                            itemCount: keys.length,
                            itemBuilder: (context, index) {
                              final key = keys[index];
                              final rawPost = favoritesBox.get(key);

                              if (rawPost is! Map) {
                                return const SizedBox.shrink();
                              }

                              final post =
                                  Map<String, dynamic>.from(rawPost);

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 16),
                                child: _favoriteCard(key, post),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _banner(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR COLLECTION',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saved for later',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count ${count == 1 ? 'article' : 'articles'} '
                  'in your library',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0x26FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
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
                Icons.bookmark_border_rounded,
                size: 42,
                color: brandBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nothing saved yet',
              style: TextStyle(
                color: primaryText,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore the posts and save articles you want to read again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                );
              },
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explore articles'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteCard(dynamic key, Map post) {
    final note = (post['note'] ?? '').toString();
    final title = _cap((post['title'] ?? 'Untitled').toString());
    final category =
        postCategories[categoryIndexOf(post['id'])];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lineColor),
        boxShadow: softShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openDetails(post),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: category.tint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 14,
                            color: category.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: category.color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ARTICLE ${post['id']}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),

                    // Delete icon.
                    IconButton(
                      tooltip: 'Remove favorite',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => deleteFavorite(key, post),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: dangerRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (post['body'] ?? '').toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pageBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: lineColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      color: category.color,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Personal note',
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => editNote(key, post),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 17,
                      ),
                      label: Text(note.isEmpty ? 'Add note' : 'Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.isEmpty
                      ? 'Add a note to remember why this article matters.'
                      : note,
                  style: TextStyle(
                    color: note.isEmpty
                        ? secondaryText
                        : primaryText,
                    fontSize: 13,
                    height: 1.6,
                    fontStyle: note.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.initialNote,
  });

  final String initialNote;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.initialNote,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      title: const Text(
        'Personal note',
        style: TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Write a note about this article...',
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, controller.text.trim());
          },
          child: const Text('Save note'),
        ),
      ],
    );
  }
}