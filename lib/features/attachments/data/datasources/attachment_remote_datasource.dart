import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/attachment_model.dart';

abstract class AttachmentRemoteDataSource {
  Future<List<AttachmentModel>> getTaskAttachments(String taskId);
  Future<AttachmentModel> uploadAttachment(AttachmentModel attachment);
  Future<void> deleteAttachment(String attachmentId);
}

class SupabaseAttachmentRemoteDataSource implements AttachmentRemoteDataSource {
  final SupabaseClient _client;

  SupabaseAttachmentRemoteDataSource(this._client);

  @override
  Future<List<AttachmentModel>> getTaskAttachments(String taskId) async {
    try {
      final response = await _client
          .from('attachments')
          .select('*, users(full_name)')
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        if (map['users'] != null && map['users'] is Map) {
          map['uploaded_by_name'] = map['users']['full_name'];
        }
        return AttachmentModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw ServerException('Failed to fetch attachments from remote: $e');
    }
  }

  @override
  Future<AttachmentModel> uploadAttachment(AttachmentModel attachment) async {
    try {
      final payload = attachment.toJson();
      payload.remove('uploaded_by_name');
      payload.remove('raw_data');

      final response = await _client
          .from('attachments')
          .insert(payload)
          .select()
          .single();

      return AttachmentModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw ServerException('Failed to upload attachment to remote: $e');
    }
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    try {
      await _client
          .from('attachments')
          .delete()
          .eq('id', attachmentId);
    } catch (e) {
      throw ServerException('Failed to delete attachment: $e');
    }
  }
}

class MockAttachmentRemoteDataSource implements AttachmentRemoteDataSource {
  final Map<String, AttachmentModel> _attachments = {};

  MockAttachmentRemoteDataSource() {
    _seedAttachments();
  }

  void _seedAttachments() {
    final now = DateTime.now();

    final seedList = [
      AttachmentModel(
        id: 'att-001',
        organizationId: 'org-acme-ops-001',
        taskId: 'tsk-002',
        visitId: 'vst-001',
        uploadedBy: 'usr-emp-003',
        uploadedByName: 'David Miller (Technician)',
        type: 'PHOTO',
        storagePath: 'tasks/tsk-002/photos/main_switchboard_thermal_before.jpg',
        fileName: 'main_switchboard_thermal_before.jpg',
        fileSize: 245000,
        mimeType: 'image/jpeg',
        metadata: {
          'latitude': 37.774929,
          'longitude': -122.419416,
          'accuracy': 4.2,
          'captured_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
          'category': 'before',
          'notes': 'Initial IR scan shows 48°C hotspot on breaker line 3.',
          'is_watermarked': true,
        },
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AttachmentModel(
        id: 'att-002',
        organizationId: 'org-acme-ops-001',
        taskId: 'tsk-003',
        visitId: 'vst-002',
        uploadedBy: 'usr-emp-003',
        uploadedByName: 'David Miller (Technician)',
        type: 'SIGNATURE',
        storagePath: 'tasks/tsk-003/signatures/customer_acceptance.json',
        fileName: 'customer_acceptance_signature.json',
        fileSize: 12400,
        mimeType: 'application/json',
        metadata: {
          'latitude': 37.775100,
          'longitude': -122.418900,
          'accuracy': 3.5,
          'captured_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
          'signer_name': 'Marcus Vance',
          'signer_role': 'Facilities Director',
          'signer_email': 'mvance@metrohealth.example.com',
          'category': 'customer_signoff',
          'is_watermarked': true,
        },
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ];

    for (final att in seedList) {
      _attachments[att.id] = att;
    }
  }

  @override
  Future<List<AttachmentModel>> getTaskAttachments(String taskId) async {
    final list = _attachments.values.where((a) => a.taskId == taskId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<AttachmentModel> uploadAttachment(AttachmentModel attachment) async {
    _attachments[attachment.id] = attachment;
    return attachment;
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    _attachments.remove(attachmentId);
  }
}
