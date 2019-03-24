/// This library defines constant classes which interface with the
/// Firebase Cloud Firestore database backend. Each class defines a
/// specific group of queries.

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
export 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DatabaseHandler {
  static Firestore db;

  static const DatabaseHandler _singleton = DatabaseHandler._internal();

  factory DatabaseHandler() => _singleton;

  const DatabaseHandler._internal();

  static void initDatabase() async {
    final FirebaseApp firebaseApp = await FirebaseApp.configure(
      name: "Prep",
      options: FirebaseOptions(
        googleAppID: (Platform.isIOS)
            ? "1:633103334646:ios:c95e32521ac6a78d"
            : "1:633103334646:android:c95e32521ac6a78d",
        gcmSenderID: "633103334646",
        apiKey: "AIzaSyBPz3NKdjY8uyYJgZTAc56xg6ncfmMT2cs",
        projectID: "prep-232116",
      ),
    );
    db = Firestore(app: firebaseApp);
    await db.settings(timestampsInSnapshotsEnabled: true);
  }
}

abstract class BaseBackend {
  String appointmentID;
  String testID;
  String appointmentName;
  String location;
  DateTime dateTime;
  String doctorName;
  Color color;

  BaseBackend setBackendParams(newAppointmentID, newTestID, newAppointmentName,
      newLocation, newDateTime, newDoctorName, newColor);

  Future<QuerySnapshot> get appointmentCodes;

  Stream<QuerySnapshot> get messageSnapshots;

  void sendMessage(String message);

  void setSeenByPatient(DocumentReference docRef);

  Stream<QuerySnapshot> get dailyCheckupsSnapshots;

  Stream<QuerySnapshot> get prepCardsSnapshots;

  Stream<QuerySnapshot> get faqSnapshots;

  Stream<DocumentSnapshot> get testSnapshots;

  Stream<QuerySnapshot> get recipeSnapshots;

  Stream<DocumentSnapshot> informationSnapshots(String documentId);

  Stream<DocumentSnapshot> categoryListSnapshots(String documentId);
}

class FirestoreBackend implements BaseBackend {
  String appointmentID;
  String testID;
  String appointmentName;
  String location;
  DateTime dateTime;
  String doctorName;
  Color color;

  static final FirestoreBackend _singleton = FirestoreBackend._internal();

  factory FirestoreBackend() => _singleton;

  FirestoreBackend._internal();

  BaseBackend setBackendParams(newAppointmentID, newTestID, newAppointmentName,
      newLocation, newDateTime, newDoctorName, newColor) {
    appointmentID = newAppointmentID;
    testID = newTestID;
    appointmentName = newAppointmentName;
    location = newLocation;
    dateTime = newDateTime;
    doctorName = newDoctorName;
    color = newColor;

    return FirestoreBackend();
  }

  Future<QuerySnapshot> get appointmentCodes => _appointmentsCollection
      .where('expired', isEqualTo: false)
      .where('datetime',
          isGreaterThan: DateTime.now().subtract(Duration(days: 1)))
      .orderBy('datetime')
      .getDocuments();

  DocumentReference get _testReference =>
      DatabaseHandler.db.collection('tests').document(testID);

  CollectionReference get _appointmentsCollection =>
      DatabaseHandler.db.collection('appointments');

  DocumentReference get _appointmentReference =>
      _appointmentsCollection.document(appointmentID);

  CollectionReference get _messagesCollection =>
      _appointmentReference.collection('messages');

  Stream<QuerySnapshot> get messageSnapshots =>
      _messagesCollection.orderBy('datetime', descending: false).snapshots();

  void sendMessage(String message) => _messagesCollection.add({
        'content': message,
        'datetime': DateTime.now(),
        'isPatient': true,
        'seenByPatient': true,
        'seenByStaff': false,
      });

  void setSeenByPatient(DocumentReference docRef) =>
      docRef.updateData({'seenByPatient': true});

  Stream<QuerySnapshot> get dailyCheckupsSnapshots => _appointmentReference
      .collection('dailyCheckups')
      .orderBy('daysBeforeTest', descending: true)
      .snapshots();

  Stream<QuerySnapshot> get prepCardsSnapshots =>
      _testReference.collection('prepCards').snapshots();

  Stream<QuerySnapshot> get faqSnapshots => _testReference
      .collection('prepCards')
      .where('type', isEqualTo: 'faqs')
      .snapshots();

  Stream<DocumentSnapshot> get testSnapshots => _testReference.snapshots();

  Stream<QuerySnapshot> get recipeSnapshots => _testReference
      .collection('prepCards')
      .where('cardType', isEqualTo: 'recipe')
      .snapshots();

  Stream<DocumentSnapshot> informationSnapshots(documentId) =>
      _testReference.collection('prepCards').document(documentId).snapshots();

  Stream<DocumentSnapshot> categoryListSnapshots(String documentId) =>
      _testReference.collection('prepCards').document(documentId).snapshots();
}