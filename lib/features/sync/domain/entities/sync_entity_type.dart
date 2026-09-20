enum SyncEntityType {
  task,
  visit,
  attendance,
  form,
  formSubmission,
  customer,
  location,
  attachment,
  notification;

  String get code {
    switch (this) {
      case SyncEntityType.task:
        return 'task';
      case SyncEntityType.visit:
        return 'visit';
      case SyncEntityType.attendance:
        return 'attendance';
      case SyncEntityType.form:
        return 'form';
      case SyncEntityType.formSubmission:
        return 'form_submission';
      case SyncEntityType.customer:
        return 'customer';
      case SyncEntityType.location:
        return 'location';
      case SyncEntityType.attachment:
        return 'attachment';
      case SyncEntityType.notification:
        return 'notification';
    }
  }

  String get displayName {
    switch (this) {
      case SyncEntityType.task:
        return 'Task';
      case SyncEntityType.visit:
        return 'Field Visit';
      case SyncEntityType.attendance:
        return 'Attendance';
      case SyncEntityType.form:
        return 'Form';
      case SyncEntityType.formSubmission:
        return 'Form Submission';
      case SyncEntityType.customer:
        return 'Customer';
      case SyncEntityType.location:
        return 'Site Location';
      case SyncEntityType.attachment:
        return 'Proof Attachment';
      case SyncEntityType.notification:
        return 'Notification';
    }
  }

  static SyncEntityType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'task':
        return SyncEntityType.task;
      case 'visit':
        return SyncEntityType.visit;
      case 'attendance':
        return SyncEntityType.attendance;
      case 'form':
        return SyncEntityType.form;
      case 'form_submission':
      case 'formsubmission':
        return SyncEntityType.formSubmission;
      case 'customer':
        return SyncEntityType.customer;
      case 'location':
        return SyncEntityType.location;
      case 'attachment':
        return SyncEntityType.attachment;
      case 'notification':
        return SyncEntityType.notification;
      default:
        return SyncEntityType.task;
    }
  }
}
