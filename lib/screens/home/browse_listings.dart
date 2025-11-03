import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/notification_badge.dart';
import '../home/post_book_screen.dart';

class BrowseListings extends StatefulWidget {
  const BrowseListings({super.key});

  @override
  State<BrowseListings> createState() => _BrowseListingsState();
}

class _BrowseListingsState extends State<BrowseListings> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookProvider>();
    final filteredBooks = prov.browse.where((book) {
      if (_searchQuery.isEmpty) return true;
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             book.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifications, child) {
              if (notifications.totalUnread == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: NotificationBadge(
                  count: notifications.totalUnread,
                  child: IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      // Navigate to My Listings tab
                      DefaultTabController.of(context)?.animateTo(1);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books or authors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Found ${filteredBooks.length} books'),
          ),
          Expanded(
            child: filteredBooks.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No listings yet\nTap + to add a book!'
                          : 'No books found for "$_searchQuery"',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredBooks.length,
                    itemBuilder: (c, i) {
                      final b = filteredBooks[i];
                      return BookCard(
                        book: b,
                        onSwap: () async {
                          try {
                            await prov.requestSwap(b);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Swap request sent for "${b.title}"'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostBookScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}