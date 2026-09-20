import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/theme/app_theme.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_entity.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_type.dart';
import 'package:field_ops/features/attachments/domain/entities/digital_signature_data.dart';
import 'package:field_ops/features/attachments/domain/repositories/attachment_repository.dart';
import 'package:field_ops/features/attachments/presentation/controllers/task_attachments_controller.dart';
import 'package:field_ops/features/attachments/presentation/widgets/task_proof_attachments_card.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';

class StubAttachmentRepoForWidgetTest implements AttachmentRepository {
  final List<AttachmentEntity> attachments = [];

  @override
  Future<List<AttachmentEntity>> getTaskAttachments(String taskId) async {
    return attachments.where((a) => a.taskId == taskId).toList();
  }

  @override
  Future<AttachmentEntity> uploadAttachment(AttachmentEntity attachment) async {
    final toAdd = attachment.id.isNotEmpty
        ? attachment
        : attachment.copyWith(id: 'att-${attachments.length + 1}');
    attachments.add(toAdd);
    return toAdd;
  }

  @override
  Future<AttachmentEntity> saveSignature({
    required String taskId,
    required DigitalSignatureData signature,
    String? visitId,
    required String userId,
    String? userName,
    required String orgId,
  }) async {
    final att = AttachmentEntity(
      id: 'sig-${attachments.length + 1}',
      organizationId: orgId,
      taskId: taskId,
      uploadedBy: userId,
      uploadedByName: userName,
      type: AttachmentType.signature,
      storagePath: 'tasks/$taskId/signature.json',
      fileName: 'signature_${signature.signerName}.json',
      metadata: signature.toMetadata(),
      createdAt: DateTime.now(),
    );
    attachments.add(att);
    return att;
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    attachments.removeWhere((a) => a.id == attachmentId);
  }
}

void main() {
  final testTask = TaskEntity(
    id: 'tsk-001',
    organizationId: 'org-001',
    title: 'AC Service & Coil Cleaning',
    status: TaskStatus.inProgress,
    customerName: 'Metro Health Plaza',
    requiresPhoto: true,
    requiresSignature: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testUser = UserEntity(
    id: 'usr-1',
    organizationId: 'org-001',
    name: 'David Miller',
    email: 'david@fieldops.com',
    role: UserRole.employee,
    status: 'active',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('TaskProofAttachmentsCard renders proof controls, launches dialogs, and updates state', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = StubAttachmentRepoForWidgetTest();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attachmentRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWithValue(testUser),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TaskProofAttachmentsCard(task: testTask),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify card header and requirements
    expect(find.text('Proof of Work Attachments'), findsOneWidget);
    expect(find.text('Photos & Sign-Off Required'), findsOneWidget);
    expect(find.text('PENDING PROOF'), findsOneWidget);

    // Verify buttons
    expect(find.text('Add Photo Proof'), findsOneWidget);
    expect(find.text('Get Signature'), findsOneWidget);

    // Open Signature Dialog
    await tester.tap(find.text('Get Signature'));
    await tester.pumpAndSettle();

    // Verify Signature Pad Dialog is displayed
    expect(find.text('Digital Sign-Off Acceptance'), findsOneWidget);
    expect(find.text('Sign Above The Line'), findsOneWidget);

    // Enter Signer Full Name
    await tester.enterText(find.byType(TextFormField).first, 'Dr. Gregory House');
    await tester.pump();

    // Draw on the signature pad canvas
    final canvasFinder = find.byKey(const Key('signature_pad_canvas'));
    await tester.drag(canvasFinder, const Offset(60, 20));
    await tester.pump();

    // Tap Save & Sign
    await tester.tap(find.text('Save & Sign'));
    await tester.pumpAndSettle();

    // Now signature preview card should be displayed
    expect(find.text('Dr. Gregory House'), findsWidgets);
    expect(find.text('VERIFIED SIGN-OFF'), findsOneWidget);

    // Now open Photo Proof Dialog
    await tester.tap(find.text('Add Photo Proof'));
    await tester.pumpAndSettle();

    // Verify Photo Proof Dialog is open
    expect(find.text('Upload Photo Proof of Work'), findsOneWidget);
    expect(find.text('Proof Category'), findsOneWidget);

    // Select 'Before Work' category
    await tester.tap(find.text('Before Work'));
    await tester.pump();

    // Save & upload photo
    await tester.tap(find.text('Save & Upload Proof'));
    await tester.pumpAndSettle();

    // Verify photo thumbnail is now in the list
    expect(find.text('Photo Evidences (1)'), findsOneWidget);
    expect(find.text('COMPLETE'), findsOneWidget);
  });
}
