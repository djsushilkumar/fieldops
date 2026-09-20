import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';

void main() {
  group('UserRole Domain Tests', () {
    test('fromString parses all supported roles correctly', () {
      expect(UserRole.fromString('owner'), equals(UserRole.owner));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('manager'), equals(UserRole.manager));
      expect(UserRole.fromString('employee'), equals(UserRole.employee));
      expect(UserRole.fromString('UNKNOWN'), equals(UserRole.employee));
      expect(UserRole.fromString(null), equals(UserRole.employee));
    });

    test('Owner permissions check', () {
      const role = UserRole.owner;
      expect(role.isOwner, isTrue);
      expect(role.isAdmin, isTrue);
      expect(role.isManager, isFalse);
      expect(role.isEmployee, isFalse);
      expect(role.canManageOrganization, isTrue);
      expect(role.canManageEmployees, isTrue);
      expect(role.canManageTeams, isTrue);
      expect(role.canManageCustomers, isTrue);
      expect(role.canCreateTasks, isTrue);
      expect(role.canAssignTasks, isTrue);
      expect(role.canConfigureForms, isTrue);
    });

    test('Admin permissions check', () {
      const role = UserRole.admin;
      expect(role.isOwner, isFalse);
      expect(role.isAdmin, isTrue);
      expect(role.isManager, isFalse);
      expect(role.canManageOrganization, isTrue);
      expect(role.canManageEmployees, isTrue);
      expect(role.canCreateTasks, isTrue);
      expect(role.canAssignTasks, isTrue);
      expect(role.canConfigureForms, isTrue);
    });

    test('Manager permissions check', () {
      const role = UserRole.manager;
      expect(role.isAdmin, isFalse);
      expect(role.isManager, isTrue);
      expect(role.canManageOrganization, isFalse);
      expect(role.canManageEmployees, isFalse);
      expect(role.canManageCustomers, isTrue);
      expect(role.canCreateTasks, isTrue);
      expect(role.canAssignTasks, isTrue);
      expect(role.canConfigureForms, isFalse);
    });

    test('Employee permissions check', () {
      const role = UserRole.employee;
      expect(role.isAdmin, isFalse);
      expect(role.isManager, isFalse);
      expect(role.isEmployee, isTrue);
      expect(role.canManageOrganization, isFalse);
      expect(role.canManageEmployees, isFalse);
      expect(role.canCreateTasks, isFalse);
      expect(role.canAssignTasks, isFalse);
      expect(role.canExecuteFieldTasks, isTrue);
    });
  });
}
