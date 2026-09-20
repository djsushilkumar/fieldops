import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../models/organization_model.dart';

abstract class OrganizationRemoteDataSource {
  Future<OrganizationModel> getOrganization(String orgId);
  Future<OrganizationModel> updateOrganization({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
  });
}

class SupabaseOrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  final supa.SupabaseClient client;

  SupabaseOrganizationRemoteDataSourceImpl(this.client);

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    try {
      final data = await client
          .from('organizations')
          .select()
          .eq('id', orgId)
          .single();
      return OrganizationModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to get organization: $e');
    }
  }

  @override
  Future<OrganizationModel> updateOrganization({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (timezone != null) updates['timezone'] = timezone;
      if (currency != null) updates['currency'] = currency;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final data = await client
          .from('organizations')
          .update(updates)
          .eq('id', orgId)
          .select()
          .single();
      return OrganizationModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to update organization: $e');
    }
  }
}

class MockOrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  OrganizationModel _org = OrganizationModel(
    id: 'org-acme-ops-001',
    name: 'Apex Field Services Ltd',
    timezone: 'America/New_York',
    currency: 'USD',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _org;
  }

  @override
  Future<OrganizationModel> updateOrganization({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _org = OrganizationModel(
      id: orgId,
      name: name ?? _org.name,
      timezone: timezone ?? _org.timezone,
      currency: currency ?? _org.currency,
      createdAt: _org.createdAt,
      updatedAt: DateTime.now(),
    );
    return _org;
  }
}
