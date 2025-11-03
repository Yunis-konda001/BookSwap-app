import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/book_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/book.dart';
import '../../widgets/book_card.dart';
import '../../widgets/notification_badge.dart';
import 'post_book_screen.dart';

class MyListings extends StatelessWidget {
  const MyListings({super.key});

  void _confirmDelete(BuildContext context, BookProvider prov, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              prov.delete(book.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Listings'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'My Books'),
              Tab(
                child: NotificationBadge(
                  count: notifications.unreadMyOffers,
                  child: const Text('My Offers'),
                ),
              ),
              Tab(
                child: NotificationBadge(
                  count: notifications.unreadIncomingOffers,
                  child: const Text('Incoming'),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyBooks(context),
            _buildMyOffers(context),
            _buildIncomingOffers(context),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostBookScreen())),
          label: const Text('Post'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMyBooks(BuildContext context) {
    final prov = context.watch<BookProvider>();
    return prov.mine.isEmpty
        ? const Center(child: Text('You have not posted any books yet'))
        : ListView.builder(
            itemCount: prov.mine.length,
            itemBuilder: (c, i) {
              final b = prov.mine[i];
              return BookCard(
                book: b,
                ownerActions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PostBookScreen(editing: b)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, prov, b),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildMyOffers(BuildContext context) {
    final prov = context.watch<BookProvider>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: prov.myOffers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final offers = snapshot.data!.docs;
        if (offers.isEmpty) return const Center(child: Text('No offers sent yet'));
        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, i) {
            final offer = offers[i].data();
            return _buildOfferCard(context, offer, false);
          },
        );
      },
    );
  }

  Widget _buildIncomingOffers(BuildContext context) {
    final prov = context.watch<BookProvider>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: prov.incomingOffers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final offers = snapshot.data!.docs;
        if (offers.isEmpty) return const Center(child: Text('No incoming offers'));
        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, i) {
            final offer = offers[i].data();
            return _buildOfferCard(context, offer, true, offers[i].id);
          },
        );
      },
    );
  }

  Widget _buildOfferCard(BuildContext context, Map<String, dynamic> offer, bool isIncoming, [String? swapId]) {
    final status = offer['status'] ?? 'Pending';
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('Book ID: ${offer['bookId']}'),
        subtitle: Text('Status: $status'),
        trailing: _buildTrailingWidget(context, offer, status, isIncoming, swapId),
      ),
    );
  }

  Widget _buildTrailingWidget(BuildContext context, Map<String, dynamic> offer, String status, bool isIncoming, String? swapId) {
    if (isIncoming && status == 'Pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => context.read<BookProvider>().acceptSwap(swapId!, offer['bookId']),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => context.read<BookProvider>().rejectSwap(swapId!, offer['bookId']),
          ),
        ],
      );
    }
    
    if (status == 'Accepted') {
      return ElevatedButton(
        onPressed: () => _showCompleteDialog(context, swapId!, offer),
        child: const Text('Complete'),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, String swapId, Map<String, dynamic> offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Swap'),
        content: const Text('Mark this swap as completed and rate your swap partner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookProvider>().completeSwap(swapId, offer['bookId']);
              _showRatingDialog(context, offer['senderId'] ?? offer['receiverId']);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String userId) {
    int rating = 5;
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Swap Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => rating = index + 1,
                  icon: Icon(
                    Icons.star,
                    color: index < rating ? Colors.amber : Colors.grey,
                  ),
                );
              }),
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Optional comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement rating submission
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}