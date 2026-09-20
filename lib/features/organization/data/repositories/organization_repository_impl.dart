import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationRemoteDataSource remoteDataSource;

  OrganizationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<OrganizationEntity> getOrganization(String orgId) async {
    try {
      final model = await remoteDataSource.getOrganization(orgId);
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<OrganizationEntity> updateOrganization({
    required String orgId,
    String? name,
    String? timezone,
    String? currency,
  }) async {
    try {
      final model = await remoteDataSource.updateOrganization(
        orgId: orgId,
        name: name,
        timezone: timezone,
        currency: currency,
      );
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
