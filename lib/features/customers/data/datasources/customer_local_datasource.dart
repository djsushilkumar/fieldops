import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../models/location_model.dart';

abstract class CustomerLocalDataSource {
  Future<List<CustomerModel>> getCachedCustomers();
  Future<void> cacheCustomers(List<CustomerModel> customers);
  Future<CustomerModel?> getCachedCustomer(String id);
  Future<void> cacheCustomer(CustomerModel customer);
  Future<List<LocationModel>> getCachedLocations({String? customerId});
  Future<void> cacheLocations(List<LocationModel> locations);
  Future<void> cacheLocation(LocationModel location);
  Future<void> clearCache();
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  static const String _customersKey = 'field_ops_cached_customers';
  static const String _locationsKey = 'field_ops_cached_locations';

  final SharedPreferences? _prefs;
  final Map<String, CustomerModel> _memoryCustomers = {};
  final Map<String, LocationModel> _memoryLocations = {};

  CustomerLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    if (_prefs == null) return;

    final customersJson = _prefs.getString(_customersKey);
    if (customersJson != null) {
      try {
        final list = jsonDecode(customersJson) as List;
        for (final item in list) {
          final model = CustomerModel.fromJson(item as Map<String, dynamic>);
          _memoryCustomers[model.id] = model;
        }
      } catch (_) {}
    }

    final locationsJson = _prefs.getString(_locationsKey);
    if (locationsJson != null) {
      try {
        final list = jsonDecode(locationsJson) as List;
        for (final item in list) {
          final model = LocationModel.fromJson(item as Map<String, dynamic>);
          _memoryLocations[model.id] = model;
        }
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final customersList = _memoryCustomers.values.map((c) => c.toJson()).toList();
    await _prefs.setString(_customersKey, jsonEncode(customersList));

    final locationsList = _memoryLocations.values.map((l) => l.toJson()).toList();
    await _prefs.setString(_locationsKey, jsonEncode(locationsList));
  }

  @override
  Future<List<CustomerModel>> getCachedCustomers() async {
    return _memoryCustomers.values.toList();
  }

  @override
  Future<void> cacheCustomers(List<CustomerModel> customers) async {
    for (final customer in customers) {
      _memoryCustomers[customer.id] = customer;
      for (final loc in customer.locations) {
        _memoryLocations[loc.id] = LocationModel.fromEntity(loc);
      }
    }
    await _persist();
  }

  @override
  Future<CustomerModel?> getCachedCustomer(String id) async {
    return _memoryCustomers[id];
  }

  @override
  Future<void> cacheCustomer(CustomerModel customer) async {
    _memoryCustomers[customer.id] = customer;
    for (final loc in customer.locations) {
      _memoryLocations[loc.id] = LocationModel.fromEntity(loc);
    }
    await _persist();
  }

  @override
  Future<List<LocationModel>> getCachedLocations({String? customerId}) async {
    if (customerId == null) {
      return _memoryLocations.values.toList();
    }
    return _memoryLocations.values
        .where((loc) => loc.customerId == customerId)
        .toList();
  }

  @override
  Future<void> cacheLocations(List<LocationModel> locations) async {
    for (final loc in locations) {
      _memoryLocations[loc.id] = loc;
    }
    await _persist();
  }

  @override
  Future<void> cacheLocation(LocationModel location) async {
    _memoryLocations[location.id] = location;
    // Also attach to customer if present in memory
    if (location.customerId != null &&
        _memoryCustomers.containsKey(location.customerId)) {
      final customer = _memoryCustomers[location.customerId]!;
      final updatedLocs = [...customer.locations.where((l) => l.id != location.id), location];
      _memoryCustomers[customer.id] = customer.copyWith(locations: updatedLocs);
    }
    await _persist();
  }

  @override
  Future<void> clearCache() async {
    _memoryCustomers.clear();
    _memoryLocations.clear();
    if (_prefs != null) {
      await _prefs.remove(_customersKey);
      await _prefs.remove(_locationsKey);
    }
  }
}
