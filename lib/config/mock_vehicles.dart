import '../models/api_models.dart';

// PENDING BACKEND: no rider-accessible vehicle list endpoint exists yet
const List<Vehicle> kMockVehicles = [
  Vehicle(
    id: 'mock-vh-001',
    vehicleCode: 'NP-TRK-01',
    vehicleType: 'Truck',
    status: 'ACTIVE',
  ),
  Vehicle(
    id: 'mock-vh-002',
    vehicleCode: 'NP-VAN-02',
    vehicleType: 'Van',
    status: 'ACTIVE',
  ),
  Vehicle(
    id: 'mock-vh-003',
    vehicleCode: 'NP-EV-03',
    vehicleType: 'Electric Mini Truck',
    status: 'ACTIVE',
  ),
];
