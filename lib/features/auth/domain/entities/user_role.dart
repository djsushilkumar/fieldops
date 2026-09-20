enum UserRole {
  owner('owner', 'Owner'),
  admin('admin', 'Admin'),
  manager('manager', 'Manager'),
  employee('employee', 'Field Employee');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.employee;
    switch (role.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }

  bool get isOwner => this == UserRole.owner;
  bool get isAdmin => this == UserRole.owner || this == UserRole.admin;
  bool get isManager => this == UserRole.manager;
  bool get isEmployee => this == UserRole.employee;

  // Authorization checks based on Section 3 of PRD
  bool get canManageOrganization => isAdmin;
  bool get canManageEmployees => isAdmin;
  bool get canManageTeams => isAdmin;
  bool get canManageCustomers => isAdmin || isManager;
  bool get canCreateTasks => isAdmin || isManager;
  bool get canAssignTasks => isAdmin || isManager;
  bool get canConfigureForms => isAdmin;
  bool get canExecuteFieldTasks => true;
}
