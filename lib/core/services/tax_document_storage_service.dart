import 'dart:typed_data';
import 'package:spots/core/services/logger.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

/// Tax Document Storage Service
/// 
/// Handles secure storage of tax documents (PDFs).
/// 
/// **Storage Options:**
/// - Firebase Storage (production)
/// - Local file system (development/fallback)
/// 
/// **Philosophy Alignment:**
/// - Opens doors to secure document storage
/// - Protects sensitive tax documents
/// - Enables document retrieval for users
class TaxDocumentStorageService {
  static const AppLogger _logger = AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final firebase_storage.FirebaseStorage? _firebaseStorage;
  final bool _useFirebase;
  
  TaxDocumentStorageService({
    firebase_storage.FirebaseStorage? firebaseStorage,
    bool useFirebase = true,
  }) : _firebaseStorage = firebaseStorage,
       _useFirebase = useFirebase;
  
  /// Upload tax document PDF
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `documentId`: Document ID
  /// - `taxYear`: Tax year
  /// - `pdfBytes`: PDF document bytes
  /// 
  /// **Returns:**
  /// URL to access the stored document
  Future<String> uploadTaxDocument({
    required String userId,
    required String documentId,
    required int taxYear,
    required Uint8List pdfBytes,
  }) async {
    try {
      _logger.info(
        'Uploading tax document: doc=$documentId, user=$userId, year=$taxYear',
        tag: 'TaxDocumentStorageService',
      );
      
      if (_useFirebase && _firebaseStorage != null) {
        return await _uploadToFirebase(
          userId: userId,
          documentId: documentId,
          taxYear: taxYear,
          pdfBytes: pdfBytes,
        );
      } else {
        return await _uploadToLocal(
          userId: userId,
          documentId: documentId,
          taxYear: taxYear,
          pdfBytes: pdfBytes,
        );
      }
    } catch (e) {
      _logger.error('Failed to upload tax document', error: e, tag: 'TaxDocumentStorageService');
      rethrow;
    }
  }
  
  /// Download tax document PDF
  /// 
  /// **Parameters:**
  /// - `documentUrl`: URL to the stored document
  /// 
  /// **Returns:**
  /// PDF document bytes
  Future<Uint8List> downloadTaxDocument(String documentUrl) async {
    try {
      _logger.info('Downloading tax document: $documentUrl', tag: 'TaxDocumentStorageService');
      
      if (documentUrl.startsWith('gs://') || documentUrl.contains('firebase')) {
        return await _downloadFromFirebase(documentUrl);
      } else {
        return await _downloadFromLocal(documentUrl);
      }
    } catch (e) {
      _logger.error('Failed to download tax document', error: e, tag: 'TaxDocumentStorageService');
      rethrow;
    }
  }
  
  /// Delete tax document
  Future<void> deleteTaxDocument(String documentUrl) async {
    try {
      _logger.info('Deleting tax document: $documentUrl', tag: 'TaxDocumentStorageService');
      
      if (documentUrl.startsWith('gs://') || documentUrl.contains('firebase')) {
        await _deleteFromFirebase(documentUrl);
      } else {
        await _deleteFromLocal(documentUrl);
      }
    } catch (e) {
      _logger.error('Failed to delete tax document', error: e, tag: 'TaxDocumentStorageService');
      rethrow;
    }
  }
  
  // Firebase Storage methods
  
  Future<String> _uploadToFirebase({
    required String userId,
    required String documentId,
    required int taxYear,
    required Uint8List pdfBytes,
  }) async {
    final storageRef = _firebaseStorage!.ref();
    final documentRef = storageRef.child('tax_documents/$userId/$taxYear/$documentId.pdf');
    
    await documentRef.putData(
      pdfBytes,
      firebase_storage.SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'userId': userId,
          'documentId': documentId,
          'taxYear': taxYear.toString(),
        },
      ),
    );
    
    final downloadUrl = await documentRef.getDownloadURL();
    return downloadUrl;
  }
  
  Future<Uint8List> _downloadFromFirebase(String documentUrl) async {
    final ref = _firebaseStorage!.refFromURL(documentUrl);
    final bytes = await ref.getData();
    
    if (bytes == null) {
      throw Exception('Failed to download document from Firebase');
    }
    
    return bytes;
  }
  
  Future<void> _deleteFromFirebase(String documentUrl) async {
    final ref = _firebaseStorage!.refFromURL(documentUrl);
    await ref.delete();
  }
  
  // Local file system methods (fallback)
  
  Future<String> _uploadToLocal({
    required String userId,
    required String documentId,
    required int taxYear,
    required Uint8List pdfBytes,
  }) async {
    // In production, would use path_provider to get documents directory
    // For now, return a placeholder URL
    _logger.warn(
      'Using local file storage (fallback). In production, use Firebase Storage.',
      tag: 'TaxDocumentStorageService',
    );
    
    return 'file://tax_documents/$userId/$taxYear/$documentId.pdf';
  }
  
  Future<Uint8List> _downloadFromLocal(String documentUrl) async {
    // In production, would read from local file system
    throw Exception('Local file download not implemented. Use Firebase Storage in production.');
  }
  
  Future<void> _deleteFromLocal(String documentUrl) async {
    // In production, would delete from local file system
    _logger.warn('Local file deletion not implemented', tag: 'TaxDocumentStorageService');
  }
}

