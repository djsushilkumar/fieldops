import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<NotificationEntity>> call({
    required String userId,
    String? organizationId,
  }) {
    return repository.getNotifications(
      userId: userId,
      organizationId: organizationId,
    );
  }
}
