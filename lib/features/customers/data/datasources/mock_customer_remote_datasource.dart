import '../../../../core/errors/failures.dart';
import '../models/customer_model.dart';
import '../models/location_model.dart';
import 'customer_remote_datasource.dart';

class MockCustomerRemoteDataSource implements CustomerRemoteDataSource {
  final Map<String, CustomerModel> customers = {};
  final Map<String, LocationModel> locations = {};
  Duration simulatedDelay;
  bool shouldThrowError = false;

  MockCustomerRemoteDataSource({this.simulatedDelay = Duration.zero}) {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    final loc1 = LocationModel(
      id: 'loc-001',
      organizationId: 'org-001',
      customerId: 'cust-001',
      name: 'Main Medical Wing',
      address: '742 Evergreen Terrace, San Francisco, CA',
      latitude: 37.7749,
      longitude: -122.4194,
      radiusMeters: 100,
      type: 'site',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 30)),
    );

    final loc2 = LocationModel(
      id: 'loc-002',
      organizationId: 'org-001',
      customerId: 'cust-001',
      name: 'East Outpatient Clinic',
      address: '101 Market St, San Francisco, CA',
      latitude: 37.7812,
      longitude: -122.4110,
      radiusMeters: 150,
      type: 'branch',
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now.subtract(const Duration(days: 20)),
    );

    final cust1 = CustomerModel(
      id: 'cust-001',
      organizationId: 'org-001',
      name: 'Metro Health Plaza',
      phone: '+1 (555) 234-5678',
      email: 'contact@metrohealth.org',
      address: '742 Evergreen Terrace, San Francisco, CA',
      notes: 'Key hospital client. Check in with security desk at entrance.',
      createdBy: 'usr-admin-001',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 30)),
      locations: [loc1, loc2],
    );

    final loc3 = LocationModel(
      id: 'loc-003',
      organizationId: 'org-001',
      customerId: 'cust-002',
      name: 'Distribution Facility 4',
      address: '880 Terminal Way, San Francisco, CA',
      latitude: 37.7650,
      longitude: -122.4050,
      radiusMeters: 200,
      type: 'warehouse',
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 15)),
    );

    final cust2 = CustomerModel(
      id: 'cust-002',
      organizationId: 'org-001',
      name: 'Apex Logistics Hub',
      phone: '+1 (555) 876-5432',
      email: 'dispatch@apexlogistics.com',
      address: '880 Terminal Way, San Francisco, CA',
      notes: 'Industrial loading docks. Safety vest required on site.',
      createdBy: 'usr-admin-001',
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 15)),
      locations: [loc3],
    );

    final loc4 = LocationModel(
      id: 'loc-004',
      organizationId: 'org-001',
      customerId: 'cust-003',
      name: 'Innovation Center Floor 3',
      address: '500 Howard St, San Francisco, CA',
      latitude: 37.7890,
      longitude: -122.4010,
      radiusMeters: 80,
      type: 'client_office',
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 10)),
    );

    final cust3 = CustomerModel(
      id: 'cust-003',
      organizationId: 'org-001',
      name: 'TechFlow Solutions',
      phone: '+1 (555) 999-1212',
      email: 'facilities@techflow.io',
      address: '500 Howard St, San Francisco, CA',
      notes: 'Server room HVAC servicing point.',
      createdBy: 'usr-admin-001',
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 10)),
      locations: [loc4],
    );

    locations[loc1.id] = loc1;
    locations[loc2.id] = loc2;
    locations[loc3.id] = loc3;
    locations[loc4.id] = loc4;

    customers[cust1.id] = cust1;
    customers[cust2.id] = cust2;
    customers[cust3.id] = cust3;
  }

  @override
  Future<List<CustomerModel>> getCustomers({String? searchQuery}) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    if (shouldThrowError) throw Exception('Simulated network error');
    var list = customers.values.toList();
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              (c.address?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  @override
  Future<CustomerModel> getCustomerDetail(String customerId) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    final cust = customers[customerId];
    if (cust == null) {
      throw const NotFoundFailure('Customer not found');
    }
    // Attach current locations for this customer
    final custLocs =
        locations.values.where((l) => l.customerId == customerId).toList();
    return cust.copyWith(locations: custLocs);
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    customers[customer.id] = customer;
    for (final loc in customer.locations) {
      locations[loc.id] = LocationModel.fromEntity(loc);
    }
    return customer;
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    if (!customers.containsKey(customer.id)) {
      throw const NotFoundFailure('Customer not found');
    }
    customers[customer.id] = customer;
    return customer;
  }

  @override
  Future<List<LocationModel>> getLocations({String? customerId}) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    if (customerId == null) {
      return locations.values.toList();
    }
    return locations.values.where((l) => l.customerId == customerId).toList();
  }

  @override
  Future<LocationModel> getLocationDetail(String locationId) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    final loc = locations[locationId];
    if (loc == null) {
      throw const NotFoundFailure('Location not found');
    }
    return loc;
  }

  @override
  Future<LocationModel> createLocation(LocationModel location) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    locations[location.id] = location;
    if (location.customerId != null &&
        customers.containsKey(location.customerId)) {
      final cust = customers[location.customerId]!;
      final updatedLocs = [...cust.locations, location];
      customers[cust.id] = cust.copyWith(locations: updatedLocs);
    }
    return location;
  }
}
