import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // ---------- Books ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> books() =>
      _db.collection('books').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> booksByOwner(String ownerId) =>
      _db.collection('books').where('ownerId', isEqualTo: ownerId).snapshots();

  Future<String> uploadImage(XFile file, String ownerId) async {
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  Future<String> createBook(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _db.collection('books').add(data);
    return ref.id;
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('books').doc(id).update(data);
  }

  Future<void> deleteBook(String id) => _db.collection('books').doc(id).delete();

  // ---------- Swaps ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> myOffers(String uid) =>
      _db.collection('swaps').where('senderId', isEqualTo: uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> incomingOffers(String uid) =>
      _db.collection('swaps').where('receiverId', isEqualTo: uid).snapshots();

  Future<String> createSwap({required String bookId, required String senderId, required String receiverId}) async {
    print('Creating swap for book: $bookId');
    final ref = _db.collection('swaps').doc();
    await ref.set({
      'bookId': bookId,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('Updating book status to Pending for book: $bookId');
    await _db.collection('books').doc(bookId).update({'status': 'Pending'});
    print('Book status updated successfully');
    return ref.id;
  }

  Future<void> updateSwapStatus(String swapId, String status) async {
    await _db.collection('swaps').doc(swapId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptSwap(String swapId, String bookId) async {
    final batch = _db.batch();
    batch.update(_db.collection('swaps').doc(swapId), {
      'status': 'Accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('books').doc(bookId), {'status': 'Accepted'});
    await batch.commit();
  }

  Future<void> rejectSwap(String swapId, String bookId) async {
    final batch = _db.batch();
    batch.update(_db.collection('swaps').doc(swapId), {
      'status': 'Rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('books').doc(bookId), {'status': ''});
    await batch.commit();
  }

  Future<void> completeSwap(String swapId, String bookId) async {
    final batch = _db.batch();
    batch.update(_db.collection('swaps').doc(swapId), {
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('books').doc(bookId), {'status': 'Completed'});
    await batch.commit();
  }

  Future<void> rateUser(String ratedUserId, String raterUserId, int rating, String comment) async {
    await _db.collection('ratings').add({
      'ratedUserId': ratedUserId,
      'raterUserId': raterUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserRatings(String userId) =>
      _db.collection('ratings').where('ratedUserId', isEqualTo: userId).snapshots();

  // ---------- Chats ----------
  // chat id is deterministic between two users (sorted UIDs)
  String chatIdFor(String a, String b) {
    final pair = [a, b]..sort();
    return pair.join('_');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> threads(String uid) =>
      _db.collection('threads').where('members', arrayContains: uid).snapshots();

  Future<void> ensureThread(String uidA, String uidB) async {
    final id = chatIdFor(uidA, uidB);
    final ref = _db.collection('threads').doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'members': [uidA, uidB],
        'lastText': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String chatId) =>
      _db.collection('threads').doc(chatId).collection('messages').orderBy('createdAt').snapshots();

  Future<void> sendMessage({
    required String chatId,
    required String from,
    required String to,
    required String text,
  }) async {
    final batch = _db.batch();
    final msgRef = _db.collection('threads').doc(chatId).collection('messages').doc();
    batch.set(msgRef, {
      'from': from,
      'to': to,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('threads').doc(chatId), {
      'lastText': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}