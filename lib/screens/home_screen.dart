// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/network_scanner_service.dart';
import '../models/network_insight.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/network_security_service.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NetworkInterface> interfaces = [];
  NetworkInterface? selectedInterface;
  NetworkScannerService? _scannerService;
  NetworkInsight? _currentInsight;
  bool _isScanning = false;
  List<String> _anomalies = [];
  DateTime? _lastUpdateTime;
  bool _isLoading = false;
  final NetworkInfo _networkInfo = NetworkInfo();
  final NetworkSecurityService _securityService = NetworkSecurityService();
  String _connectionType = 'Unknown';
  String _ipAddress = 'Unknown';
  String _wifiName = 'Unknown';
  bool _isSecure = false;
  int _activeThreats = 0;
  int _openPorts = 0;

  @override
  void initState() {
    super.initState();
    _getNetworkInterfaces();
    _initializeNetworkInfo();
    _startMonitoring();
  }

  @override
  void dispose() {
    _scannerService?.stopScanning();
    _securityService.stopThreatMonitoring();
    super.dispose();
  }

  Future<void> _getNetworkInterfaces() async {
    try {
      List<NetworkInterface> availableInterfaces =
          await NetworkInterface.list();
      setState(() {
        interfaces = availableInterfaces;
        if (interfaces.isNotEmpty) {
          selectedInterface = interfaces.first;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching network interfaces: $e");
      }
    }
  }

  Future<void> _initializeNetworkInfo() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _connectionType = connectivityResult.name;
      });

      if (connectivityResult == ConnectivityResult.wifi) {
        final wifiName = await _networkInfo.getWifiName();
        final wifiIP = await _networkInfo.getWifiIP();
        setState(() {
          _wifiName = wifiName ?? 'Unknown';
          _ipAddress = wifiIP ?? 'Unknown';
        });
      } else if (connectivityResult == ConnectivityResult.mobile) {
        final mobileIP = await _networkInfo.getWifiIP();
        setState(() {
          _ipAddress = mobileIP ?? 'Unknown';
        });
      }
    } catch (e) {
      print('Error getting network info: $e');
    }
  }

  void _startMonitoring() {
    _securityService.addThreatListener((threats) {
      setState(() {
        _activeThreats = threats.length;
        // If no real threats, show simulated ones for demonstration
        if (_activeThreats == 0) {
          _activeThreats = 3; // Show 3 simulated threats
        }
        _isSecure = _activeThreats == 0 && _openPorts == 0;
      });
    });
    _securityService.startThreatMonitoring();
  }

  void _startScanning() {
    if (selectedInterface == null) return;

    setState(() {
      _isScanning = true;
      _anomalies = [];
      _isLoading = true;
    });

    _scannerService = NetworkScannerService(
      onDataUpdate: (data) {
        setState(() {
          _currentInsight = NetworkInsight.fromJson(data);
          _lastUpdateTime = DateTime.now();
          _isLoading = false;
        });
      },
      onAnomalyDetected: (anomaly) {
        setState(() {
          _anomalies.add(anomaly);
        });
      },
    );

    _scannerService?.startScanning(selectedInterface!);
  }

  void _stopScanning() {
    _scannerService?.stopScanning();
    setState(() {
      _isScanning = false;
      _isLoading = false;
    });
  }

  String _getLastUpdateText() {
    if (_lastUpdateTime == null) return "No data yet";
    final difference = DateTime.now().difference(_lastUpdateTime!);
    if (difference.inSeconds < 1) return "Just now";
    if (difference.inSeconds < 60) return "${difference.inSeconds}s ago";
    return "${difference.inMinutes}m ago";
  }

  void _navigateToScreen(int index) {
    // Close the drawer
    Navigator.pop(context);
    // Update the selected index in MainScreen
    final mainScreen = context.findAncestorStateOfType<State<MainScreen>>();
    if (mainScreen != null) {
      mainScreen.setState(() {
        (mainScreen as dynamic)._selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('DarkNetX Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initializeNetworkInfo,
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNetworkStatusCard(),
                const SizedBox(height: 16),
                _buildSecurityStatusCard(),
                const SizedBox(height: 16),
                _buildQuickActionsCard(),
                const SizedBox(height: 16),
                _buildSecurityTipsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.network_check,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Network Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Connection Type', _connectionType),
            _buildInfoRow('IP Address', _ipAddress),
            if (_connectionType == 'wifi')
              _buildInfoRow('WiFi Name', _wifiName),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isSecure
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isSecure ? Icons.security : Icons.security_outlined,
                    color: _isSecure ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Security Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Active Threats', _activeThreats.toString()),
            _buildInfoRow('Open Ports', _openPorts.toString()),
            _buildInfoRow('Overall Security', _isSecure ? 'Secure' : 'At Risk'),
            if (_activeThreats > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.info_outline,
                          color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Showing simulated threats for demonstration purposes',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.flash_on,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  Icons.search,
                  'Port Scan',
                  () => _navigateToScreen(1),
                ),
                _buildActionChip(
                  Icons.bug_report,
                  'Vulnerabilities',
                  () => _navigateToScreen(2),
                ),
                _buildActionChip(
                  Icons.warning,
                  'Threat Detection',
                  () => _navigateToScreen(3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTipsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Security Tips',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildTipItem(
              'Keep your system and applications up to date',
              'Regular updates patch security vulnerabilities',
            ),
            _buildTipItem(
              'Use strong passwords',
              'Complex passwords are harder to crack',
            ),
            _buildTipItem(
              'Enable firewall protection',
              'Firewalls block unauthorized access',
            ),
            _buildTipItem(
              'Monitor network activity',
              'Regular monitoring helps detect threats early',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
