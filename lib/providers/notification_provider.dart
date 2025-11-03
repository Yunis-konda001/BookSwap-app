import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class NotificationProvider with ChangeNotifier {
  final _svc = FirestoreService.instance;
  final _auth = FirebaseAuth.instance;
  
  int _unreadIncomingOffers = 0;
  int _unreadMyOffers = 0;
  
  int get unreadIncomingOffers => _unreadIncomingOffers;
  int get unreadMyOffers => _unreadMyOffers;
  int get totalUnread => _unreadIncomingOffers + _unreadMyOffers;
  
  StreamSubscription? _incomingSub;
  StreamSubscription? _myOffersSub;
  
  NotificationProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _startListening();
      } else {
        _stopListening();
        _unreadIncomingOffers = 0;
        _unreadMyOffers = 0;
        notifyListeners();
      }
    });
  }
  
  void _startListening() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    _incomingSub?.cancel();
    _myOffersSub?.cancel();
    
    // Listen to incoming offers (new swap requests for my books)
    _incomingSub = _svc.incomingOffers(uid).listen((snapshot) {
      _unreadIncomingOffers = snapshot.docs
          .where((doc) => doc.data()['status'] == 'Pending')
          .length;
      notifyListeners();
    });
    
    // Listen to my offers status changes
    _myOffersSub = _svc.myOffers(uid).listen((snapshot) {
      _unreadMyOffers = snapshot.docs
          .where((doc) => doc.data()['status'] == 'Accepted')
          .length;
      notifyListeners();
    });
  }
  
  void _stopListening() {
    _incomingSub?.cancel();
    _myOffersSub?.cancel();
  }
  
  void markIncomingAsRead() {
    _unreadIncomingOffers = 0;
    notifyListeners();
  }
  
  void markMyOffersAsRead() {
    _unreadMyOffers = 0;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}