enum VehicleType {
  twoWheelerBike,
  fourWheelerCar,
  electricVehicle,
  publicTransit;

  String get displayName {
    switch (this) {
      case VehicleType.twoWheelerBike:
        return 'Two-Wheeler / Motorcycle';
      case VehicleType.fourWheelerCar:
        return 'Four-Wheeler / Car';
      case VehicleType.electricVehicle:
        return 'Electric Vehicle (EV)';
      case VehicleType.publicTransit:
        return 'Public Transit / Bus';
    }
  }

  /// Default reimbursement rate per km (e.g., standard ₹/km or $/km)
  double get defaultRatePerKm {
    switch (this) {
      case VehicleType.twoWheelerBike:
        return 3.50;
      case VehicleType.fourWheelerCar:
        return 8.00;
      case VehicleType.electricVehicle:
        return 4.00;
      case VehicleType.publicTransit:
        return 2.50;
    }
  }

  static VehicleType fromString(String? val) {
    if (val == null) return VehicleType.twoWheelerBike;
    switch (val.toLowerCase()) {
      case 'car':
      case 'fourwheelercar':
        return VehicleType.fourWheelerCar;
      case 'ev':
      case 'electricvehicle':
        return VehicleType.electricVehicle;
      case 'transit':
      case 'publictransit':
        return VehicleType.publicTransit;
      default:
        return VehicleType.twoWheelerBike;
    }
  }
}
