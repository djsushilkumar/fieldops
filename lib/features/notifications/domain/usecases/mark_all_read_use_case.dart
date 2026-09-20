import '../repositories/notification_repository.dart';

class MarkAllReadUseCase {
  final NotificationRepository repository;

  MarkAllReadUseCase(this.repository);

  Future<void> call(String userId) {
    return repository.markAllAsRead(userId);
  }
}
