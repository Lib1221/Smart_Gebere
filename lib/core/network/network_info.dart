import '../services/connectivity_service.dart';

/// Abstract class for network information
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

/// Implementation using ConnectivityService
class NetworkInfoImpl implements NetworkInfo {
  final ConnectivityService _connectivityService;

  NetworkInfoImpl({required ConnectivityService connectivityService})
      : _connectivityService = connectivityService;

  @override
  Future<bool> get isConnected => _connectivityService.checkConnectivity();

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivityService.connectivityStream;
}

