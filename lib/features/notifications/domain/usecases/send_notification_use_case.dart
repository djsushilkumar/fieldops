import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class SendNotificationUseCase {
  final NotificationRepository repository;

  SendNotificationUseCase(this.repository);

  Future<NotificationEntity> call(NotificationEntity notification) {
    return repository.sendNotification(notification);
  }
}
