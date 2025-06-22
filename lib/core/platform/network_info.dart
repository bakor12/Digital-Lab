// File: lib/core/platform/network_info.dart
import 'dart:io'; // For InternetAddress.lookup
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract class INetworkInfo {
  Future<bool> get isConnected;
  Stream<ConnectivityResult> get onConnectivityChanged;
}

@LazySingleton(as: INetworkInfo)
class NetworkInfo implements INetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet)) {
      // Optional: Add an actual internet check beyond just connectivity
      // return await _hasInternetAccess();
      return true;
    }
    return false;
  }

  /// More reliable check for actual internet access, not just network connection.
  // ignore: unused_element
  Future<bool> _hasInternetAccess() async {
    try {
      // Ping a reliable server. Google's DNS is a common choice.
      final result = await InternetAddress.lookup('8.8.8.8');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  Stream<ConnectivityResult> get onConnectivityChanged {
    // map the list of results to a single result.
    // For this app, we are mostly concerned if there is *any* connection.
    return _connectivity.onConnectivityChanged.map((results) => results.isEmpty ? ConnectivityResult.none : results.first);
  }
}

@module
abstract class CorePlatformModule {
  @lazySingleton
  Connectivity get connectivity => Connectivity();
}
