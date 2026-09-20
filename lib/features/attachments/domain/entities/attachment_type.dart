import 'package:flutter/material.dart';

enum AttachmentType {
  photo,
  signature,
  document,
  notes;

  String get code {
    switch (this) {
      case AttachmentType.photo:
        return 'PHOTO';
      case AttachmentType.signature:
        return 'SIGNATURE';
      case AttachmentType.document:
        return 'DOCUMENT';
      case AttachmentType.notes:
        return 'NOTES';
    }
  }

  String get displayName {
    switch (this) {
      case AttachmentType.photo:
        return 'Photo Proof';
      case AttachmentType.signature:
        return 'Digital Signature';
      case AttachmentType.document:
        return 'Document';
      case AttachmentType.notes:
        return 'Field Notes';
    }
  }

  IconData get icon {
    switch (this) {
      case AttachmentType.photo:
        return Icons.photo_camera_rounded;
      case AttachmentType.signature:
        return Icons.draw_rounded;
      case AttachmentType.document:
        return Icons.description_rounded;
      case AttachmentType.notes:
        return Icons.note_rounded;
    }
  }

  static AttachmentType fromString(String? val) {
    if (val == null) return AttachmentType.photo;
    switch (val.toUpperCase().trim()) {
      case 'PHOTO':
        return AttachmentType.photo;
      case 'SIGNATURE':
        return AttachmentType.signature;
      case 'DOCUMENT':
        return AttachmentType.document;
      case 'NOTES':
        return AttachmentType.notes;
      default:
        return AttachmentType.photo;
    }
  }
}
