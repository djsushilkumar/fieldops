import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/attachments/data/models/attachment_model.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_entity.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_metadata.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_type.dart';
import 'package:field_ops/features/attachments/domain/entities/digital_signature_data.dart';
import 'package:field_ops/features/attachments/domain/entities/task_proof_status.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';

void main() {
  group('AttachmentType', () {
    test('fromString parses all enum codes', () {
      expect(AttachmentType.fromString('PHOTO'), equals(AttachmentType.photo));
      expect(AttachmentType.fromString('SIGNATURE'), equals(AttachmentType.signature));
      expect(AttachmentType.fromString('DOCUMENT'), equals(AttachmentType.document));
      expect(AttachmentType.fromString('NOTES'), equals(AttachmentType.notes));
      expect(AttachmentType.fromString(null), equals(AttachmentType.photo));
      expect(AttachmentType.fromString('UNKNOWN'), equals(AttachmentType.photo));
    });

    test('code and displayName return correct values', () {
      expect(AttachmentType.photo.code, equals('PHOTO'));
      expect(AttachmentType.photo.displayName, equals('Photo Proof'));
      expect(AttachmentType.signature.code, equals('SIGNATURE'));
      expect(AttachmentType.signature.displayName, equals('Digital Signature'));
    });
  });

  group('AttachmentMetadata', () {
    final now = DateTime.now();

    test('formattedGpsCoordinates formats latitude, longitude, and accuracy', () {
      const metaWithGps = AttachmentMetadata(
        latitude: 37.774929,
        longitude: -122.419416,
        accuracy: 5.2,
      );
      expect(metaWithGps.hasGps, isTrue);
      expect(metaWithGps.formattedGpsCoordinates, contains('37.774929, -122.419416 (±5.2m)'));

      const metaNoGps = AttachmentMetadata();
      expect(metaNoGps.hasGps, isFalse);
      expect(metaNoGps.formattedGpsCoordinates, equals('No GPS fix'));
    });

    test('watermarkText includes GPS, time, signer, and notes', () {
      final meta = AttachmentMetadata(
        latitude: 37.7749,
        longitude: -122.4194,
        capturedAt: now,
        signerName: 'Marcus Vance',
        signerRole: 'Site Director',
        notes: 'Coils restored to 120 PSI',
      );
      final watermark = meta.watermarkText;
      expect(watermark, contains('GPS: 37.774900, -122.419400'));
      expect(watermark, contains('SIGNED BY: Marcus Vance (Site Director)'));
      expect(watermark, contains('NOTE: Coils restored to 120 PSI'));
    });

    test('toMap and fromMap round-trip accurately', () {
      final meta = AttachmentMetadata(
        latitude: 37.77,
        longitude: -122.41,
        accuracy: 4.0,
        capturedAt: now,
        signerName: 'John Doe',
        signerRole: 'Customer',
        signerEmail: 'john@example.com',
        category: 'after',
        notes: 'Done',
        isWatermarked: true,
      );

      final map = meta.toMap();
      final restored = AttachmentMetadata.fromMap(map);

      expect(restored.latitude, equals(meta.latitude));
      expect(restored.longitude, equals(meta.longitude));
      expect(restored.accuracy, equals(meta.accuracy));
      expect(restored.signerName, equals(meta.signerName));
      expect(restored.signerRole, equals(meta.signerRole));
      expect(restored.signerEmail, equals(meta.signerEmail));
      expect(restored.category, equals(meta.category));
      expect(restored.isWatermarked, isTrue);
    });
  });

  group('DigitalSignatureData', () {
    test('point and stroke serialization', () {
      const p1 = DigitalSignaturePoint(10.5, 20.5);
      expect(p1.toOffset().dx, equals(10.5));
      expect(p1.toOffset().dy, equals(20.5));

      const stroke = DigitalSignatureStroke(
        points: [p1, DigitalSignaturePoint(15.0, 25.0)],
        colorValue: 0xFF000000,
        strokeWidth: 3.5,
      );
      final map = stroke.toMap();
      final restored = DigitalSignatureStroke.fromMap(map);

      expect(restored.points.length, equals(2));
      expect(restored.strokeWidth, equals(3.5));
      expect(restored.colorValue, equals(0xFF000000));
    });

    test('signature data getters and toMetadata conversion', () {
      final now = DateTime.now();
      final sig = DigitalSignatureData(
        strokes: [
          const DigitalSignatureStroke(
            points: [DigitalSignaturePoint(5, 5), DigitalSignaturePoint(10, 10)],
          ),
        ],
        signerName: 'Sarah Connor',
        signerRole: 'Manager',
        signerEmail: 'sarah@example.com',
        signedAt: now,
        latitude: 37.77,
        longitude: -122.41,
        accuracy: 3.0,
      );

      expect(sig.isNotEmpty, isTrue);
      expect(sig.totalPoints, equals(2));

      final meta = sig.toMetadata();
      expect(meta.signerName, equals('Sarah Connor'));
      expect(meta.signerRole, equals('Manager'));
      expect(meta.category, equals('customer_signoff'));
      expect(meta.hasGps, isTrue);

      final map = sig.toMap();
      final restored = DigitalSignatureData.fromMap(map);
      expect(restored.signerName, equals('Sarah Connor'));
      expect(restored.strokes.length, equals(1));
    });
  });

  group('AttachmentModel', () {
    final now = DateTime.now();
    final model = AttachmentModel(
      id: 'att-101',
      organizationId: 'org-001',
      taskId: 'tsk-001',
      uploadedBy: 'usr-001',
      uploadedByName: 'David Miller',
      type: 'PHOTO',
      storagePath: 'tasks/tsk-001/photos/photo.jpg',
      fileName: 'photo.jpg',
      fileSize: 124000,
      mimeType: 'image/jpeg',
      metadata: const {
        'latitude': 37.77,
        'longitude': -122.41,
        'category': 'after',
        'is_watermarked': true,
      },
      createdAt: now,
      rawData: 'base64simulateddata',
    );

    test('toEntity converts correctly', () {
      final entity = model.toEntity();
      expect(entity.id, equals('att-101'));
      expect(entity.isPhoto, isTrue);
      expect(entity.isSignature, isFalse);
      expect(entity.formattedSize, contains('121.1 KB'));
      expect(entity.metadata.category, equals('after'));
      expect(entity.rawData, equals('base64simulateddata'));
    });

    test('round trip through JSON', () {
      final json = model.toJson();
      final fromJson = AttachmentModel.fromJson(json);

      expect(fromJson.id, equals(model.id));
      expect(fromJson.fileName, equals(model.fileName));
      expect(fromJson.fileSize, equals(model.fileSize));
      expect(fromJson.type, equals(model.type));
      expect(fromJson.metadata['category'], equals('after'));
    });

    test('round trip through SQL map', () {
      final sqlMap = model.toSqlMap();
      final fromSql = AttachmentModel.fromSqlMap(sqlMap);

      expect(fromSql.id, equals(model.id));
      expect(fromSql.taskId, equals(model.taskId));
      expect(fromSql.storagePath, equals(model.storagePath));
      expect(fromSql.metadata['category'], equals('after'));
    });
  });

  group('TaskProofStatus', () {
    final now = DateTime.now();
    final taskRequiresAll = TaskEntity(
      id: 'tsk-001',
      organizationId: 'org-001',
      title: 'Major Overhaul',
      status: TaskStatus.inProgress,
      requiresGps: true,
      requiresPhoto: true,
      requiresSignature: true,
      requiresForm: true,
      createdAt: now,
      updatedAt: now,
    );

    final photoAtt = AttachmentEntity(
      id: 'att-1',
      organizationId: 'org-001',
      taskId: 'tsk-001',
      uploadedBy: 'usr-1',
      type: AttachmentType.photo,
      storagePath: 'path/photo.jpg',
      fileName: 'photo.jpg',
      createdAt: now,
    );

    final sigAtt = AttachmentEntity(
      id: 'att-2',
      organizationId: 'org-001',
      taskId: 'tsk-001',
      uploadedBy: 'usr-1',
      type: AttachmentType.signature,
      storagePath: 'path/sig.json',
      fileName: 'sig.json',
      metadata: const AttachmentMetadata(signerName: 'Jane Boss'),
      createdAt: now,
    );

    test('evaluates missing requirements accurately', () {
      final incompleteStatus = TaskProofStatus.evaluate(
        task: taskRequiresAll,
        attachments: [],
        hasActiveOrCompletedVisit: false,
        hasSubmittedForm: false,
      );

      expect(incompleteStatus.isAllSatisfied, isFalse);
      expect(incompleteStatus.hasPhotoProof, isFalse);
      expect(incompleteStatus.hasSignatureProof, isFalse);
      expect(incompleteStatus.missingRequirements.length, greaterThanOrEqualTo(2));

      final completeStatus = TaskProofStatus.evaluate(
        task: taskRequiresAll,
        attachments: [photoAtt, sigAtt],
        hasActiveOrCompletedVisit: true,
        hasSubmittedForm: true,
      );

      expect(completeStatus.isAllSatisfied, isTrue);
      expect(completeStatus.hasPhotoProof, isTrue);
      expect(completeStatus.hasSignatureProof, isTrue);
      expect(completeStatus.photoCount, equals(1));
      expect(completeStatus.signatureSignerName, equals('Jane Boss'));
      expect(completeStatus.missingRequirements, isEmpty);
    });
  });
}
