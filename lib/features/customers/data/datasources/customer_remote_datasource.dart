import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../models/customer_model.dart';
import '../models/location_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers({String? searchQuery});
  Future<CustomerModel> getCustomerDetail(String customerId);
  Future<CustomerModel> createCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<List<LocationModel>> getLocations({String? customerId});
  Future<LocationModel> getLocationDetail(String locationId);
  Future<LocationModel> createLocation(LocationModel location);
}

class SupabaseCustomerRemoteDataSource implements CustomerRemoteDataSource {
  final SupabaseClient _client;

  SupabaseCustomerRemoteDataSource(this._client);

  @override
  Future<List<CustomerModel>> getCustomers({String? searchQuery}) async {
    try {
      var query = _client.from('customers').select('''
        *,
        locations (*)
      ''');

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('name', '%${searchQuery.trim()}%');
      }

      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((data) => CustomerModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch customers from Supabase: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerDetail(String customerId) async {
    try {
      final response = await _client
          .from('customers')
          .select('''
            *,
            locations (*)
          ''')
          .eq('id', customerId)
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Failed to fetch customer detail: $e');
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      final json = customer.toJson();
      json.remove('locations');
      final response = await _client
          .from('customers')
          .insert(json)
          .select('''
            *,
            locations (*)
          ''')
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Failed to create customer: $e');
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final json = customer.toJson();
      json.remove('locations');
      final response = await _client
          .from('customers')
          .update(json)
          .eq('id', customer.id)
          .select('''
            *,
            locations (*)
          ''')
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Failed to update customer: $e');
    }
  }

  @override
  Future<List<LocationModel>> getLocations({String? customerId}) async {
    try {
      var query = _client.from('locations').select();
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      final response = await query.order('name', ascending: true);
      return (response as List)
          .map((data) => LocationModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch locations: $e');
    }
  }

  @override
  Future<LocationModel> getLocationDetail(String locationId) async {
    try {
      final response = await _client
          .from('locations')
          .select()
          .eq('id', locationId)
          .single();
      return LocationModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Failed to fetch location detail: $e');
    }
  }

  @override
  Future<LocationModel> createLocation(LocationModel location) async {
    try {
      final response = await _client
          .from('locations')
          .insert(location.toJson())
          .select()
          .single();
      return LocationModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Failed to create location: $e');
    }
  }
}
