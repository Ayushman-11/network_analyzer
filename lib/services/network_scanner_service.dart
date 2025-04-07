import 'dart:async';
import 'dart:io';
import '../utils/network_utils.dart';

class NetworkScannerService {
  Timer? _scanTimer;
  final Function(Map<String, dynamic>) onDataUpdate;
  final Function(String) onAnomalyDetected;
  Map<String, dynamic>? _previousStats;
  bool _isScanning = false;

  NetworkScannerService({
    required this.onDataUpdate,
    required this.onAnomalyDetected,
  });

  void startScanning(NetworkInterface interface) {
    // Stop any existing scan
    stopScanning();

    _isScanning = true;

    // Perform initial scan immediately
    _performScan(interface);

    // Start periodic scanning every 2 seconds
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isScanning) {
        _performScan(interface);
      }
    });
  }

  void stopScanning() {
    _isScanning = false;
    _scanTimer?.cancel();
  }

  Future<void> _performScan(NetworkInterface interface) async {
    if (!_isScanning) return;

    try {
      // Get network statistics
      final stats = await _getNetworkStats(interface);

      // Check for anomalies
      _checkAnomalies(stats);

      // Update UI with new data
      onDataUpdate(stats);

      // Store current stats for next comparison
      _previousStats = stats;
    } catch (e) {
      print('Error during network scan: $e');
      onAnomalyDetected('Error during network scan: $e');
    }
  }

  Future<Map<String, dynamic>> _getNetworkStats(
      NetworkInterface interface) async {
    // Get IP address
    final addresses = interface.addresses;
    final ipAddress =
        addresses.isNotEmpty ? addresses.first.address : 'Unknown';

    // Get network speed and traffic
    final speed = await NetworkUtils.measureNetworkSpeed();

    // Get interface-specific active connections
    final connections =
        await NetworkUtils.getInterfaceConnections(interface.name);

    return {
      'interfaceName': interface.name,
      'ipAddress': ipAddress,
      'networkSpeed': speed,
      'activeConnections': connections,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void _checkAnomalies(Map<String, dynamic> currentStats) {
    if (_previousStats == null) return;

    // Check for significant speed changes
    final currentSpeed = currentStats['networkSpeed']['download'];
    final previousSpeed = _previousStats!['networkSpeed']['download'];

    if (currentSpeed > previousSpeed * 2) {
      onAnomalyDetected('Unusual increase in download speed detected!');
    } else if (currentSpeed < previousSpeed * 0.5) {
      onAnomalyDetected('Significant decrease in download speed detected!');
    }

    // Check for high latency
    if (currentStats['networkSpeed']['latency'] > 100) {
      onAnomalyDetected('High network latency detected!');
    }

    // Check for unusual number of connections
    final currentConnections = currentStats['activeConnections'].length;
    final previousConnections = _previousStats!['activeConnections'].length;

    if (currentConnections > previousConnections * 2) {
      onAnomalyDetected('Unusual increase in active connections detected!');
    }
  }
}
