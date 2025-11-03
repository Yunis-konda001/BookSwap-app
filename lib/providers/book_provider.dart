import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../models/book.dart';

class BookProvider with ChangeNotifier {
  final _svc = FirestoreService.instance;
  final _auth = FirebaseAuth.instance;

  List<Book> _browse = [];
  List<Book> _mine = [];

  List<Book> get browse => _browse;
  List<Book> get mine => _mine;

  StreamSubscription? _allSub;
  StreamSubscription? _mineSub;

  BookProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _bind();
      } else {
        _browse = [];
        _mine = [];
        _allSub?.cancel();
        _mineSub?.cancel();
        notifyListeners();
      }
    });
  }

  void _bind() {
    _allSub?.cancel();
    _mineSub?.cancel();
    
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    _allSub = _svc.books().listen((s) {
      _browse = s.docs.map((d) => Book.fromDoc(d)).toList();
      // Sort by creation time if available
      _browse.sort((a, b) => b.id.compareTo(a.id));
      notifyListeners();
    }, onError: (e) {
      print('Error loading books: $e');
    });

    _mineSub = _svc.booksByOwner(uid).listen((s) {
      _mine = s.docs.map((d) => Book.fromDoc(d)).toList();
      _mine.sort((a, b) => b.id.compareTo(a.id));
      notifyListeners();
    }, onError: (e) {
      print('Error loading my books: $e');
    });
  }

  @override
  void dispose() {
    _allSub?.cancel();
    _mineSub?.cancel();
    super.dispose();
  }

  // ------------ CRUD ------------
  Future<void> create({
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    XFile? image,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    String imageUrl = '';
    
    // Upload image first if provided
    if (image != null) {
      try {
        imageUrl = await _svc.uploadImage(image, user.uid);
      } catch (e) {
        // Continue without image
      }
    }
    
    // Create book with image URL
    await _svc.createBook({
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'imageUrl': imageUrl,
      'ownerId': user.uid,
      'ownerEmail': user.email ?? '',
      'status': '',
    });
  }

  Future<void> update({
    required String id,
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    XFile? image,
    String? currentImageUrl,
  }) async {
    String imageUrl = currentImageUrl ?? '';
    
    if (image != null) {
      try {
        imageUrl = await _svc.uploadImage(image, _auth.currentUser!.uid);
      } catch (e) {
        // Keep current image URL if new upload fails
      }
    }
    
    await _svc.updateBook(id, {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'imageUrl': imageUrl,
    });
  }

  Future<void> delete(String id) => _svc.deleteBook(id);

  // ------------ Swap ------------
  Future<void> requestSwap(Book book) async {
    final me = _auth.currentUser!;
    if (me.uid == book.ownerId) return;
    
    print('Requesting swap for book: ${book.id}');
    await _svc.createSwap(bookId: book.id, senderId: me.uid, receiverId: book.ownerId);
    await _svc.ensureThread(me.uid, book.ownerId);
    print('Swap request completed');
  }

  Future<void> acceptSwap(String swapId, String bookId) async {
    await _svc.acceptSwap(swapId, bookId);
  }

  Future<void> rejectSwap(String swapId, String bookId) async {
    await _svc.rejectSwap(swapId, bookId);
  }

  Future<void> completeSwap(String swapId, String bookId) async {
    await _svc.completeSwap(swapId, bookId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get myOffers {
    final uid = _auth.currentUser?.uid;
    return uid != null ? _svc.myOffers(uid) : const Stream.empty();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get incomingOffers {
    final uid = _auth.currentUser?.uid;
    return uid != null ? _svc.incomingOffers(uid) : const Stream.empty();
  }
}