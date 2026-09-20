import 'dart:async';

enum ConnectivityStatus {
  online,
  offline,
}

abstract class NetworkConnectivityService {
  bool get isOnline;
  Stream<ConnectivityStatus> get onConnectivityChanged;
  Future<bool> checkConnectivity();
  void dispose();
}

class NetworkConnectivityServiceImpl implements NetworkConnectivityService {
  bool _isOnline = true;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  NetworkConnectivityServiceImpl({bool initialOnline = true}) : _isOnline = initialOnline;

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> checkConnectivity() async {
    return _isOnline;
  }

  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _controller.add(online ? ConnectivityStatus.online : ConnectivityStatus.offline);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
