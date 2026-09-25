enum ConveyanceStatus {
  draft,
  pendingApproval,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case ConveyanceStatus.draft:
        return 'Draft / In Progress';
      case ConveyanceStatus.pendingApproval:
        return 'Pending Approval';
      case ConveyanceStatus.approved:
        return 'Approved & Reimbursable';
      case ConveyanceStatus.rejected:
        return 'Rejected';
    }
  }

  static ConveyanceStatus fromString(String? val) {
    if (val == null) return ConveyanceStatus.draft;
    switch (val.toUpperCase()) {
      case 'PENDING':
      case 'PENDINGAPPROVAL':
      case 'PENDING_APPROVAL':
        return ConveyanceStatus.pendingApproval;
      case 'APPROVED':
        return ConveyanceStatus.approved;
      case 'REJECTED':
        return ConveyanceStatus.rejected;
      default:
        return ConveyanceStatus.draft;
    }
  }
}
