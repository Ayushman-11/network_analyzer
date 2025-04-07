import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/security_models.dart';

class NetworkSecurityService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  Timer? _monitoringTimer;
  final List<dynamic Function(List<ThreatResult>)> _threatListeners = [];
  final List<dynamic Function(List<VulnerabilityResult>)> _vulnerabilityListeners =
      [];

  // Start monitoring network for threats
  Future<void> startThreatMonitoring() async {
    // Stop any existing monitoring
    stopThreatMonitoring();

    // Start periodic monitoring
    _monitoringTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkForThreats();
    });
  }

  // Stop monitoring network for threats
  void stopThreatMonitoring() {
    _monitoringTimer?.cancel();
  }

  // Add listener for threat updates
  void addThreatListener(dynamic Function(List<ThreatResult>) listener) {
    _threatListeners.add(listener);
  }

  // Remove listener for threat updates
  void removeThreatListener(dynamic Function(List<ThreatResult>) listener) {
    _threatListeners.remove(listener);
  }

  // Add listener for vulnerability updates
  void addVulnerabilityListener(
      dynamic Function(List<VulnerabilityResult>) listener) {
    _vulnerabilityListeners.add(listener);
  }

  // Remove listener for vulnerability updates
  void removeVulnerabilityListener(
      dynamic Function(List<VulnerabilityResult>) listener) {
    _vulnerabilityListeners.remove(listener);
  }

  // Check for network threats
  Future<void> _checkForThreats() async {
    try {
      final List<ThreatResult> threats = [];

      // Check for suspicious network activity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.wifi) {
        // Get WiFi information
        final wifiName = await _networkInfo.getWifiName();
        final wifiBSSID = await _networkInfo.getWifiBSSID();
        final wifiIP = await _networkInfo.getWifiIP();

        // Check for suspicious IP addresses
        if (wifiIP != null) {
          final suspiciousIPs = await _checkSuspiciousIPs(wifiIP);
          if (suspiciousIPs.isNotEmpty) {
            threats.add(ThreatResult(
              'Suspicious IP Activity',
              'Detected connections to known malicious IPs',
              DateTime.now(),
              'High',
              'Multiple connections detected to IPs associated with malicious activity:\n\n'
                  '${suspiciousIPs.join('\n')}\n\n'
                  'Recommended actions:\n'
                  '1. Block these IP addresses\n'
                  '2. Investigate affected systems\n'
                  '3. Review network logs\n'
                  '4. Update firewall rules',
            ));
          }
        }

        // Check for unusual network traffic
        final unusualTraffic = await _checkUnusualTraffic();
        if (unusualTraffic) {
          threats.add(ThreatResult(
            'Unusual Network Traffic',
            'Detected abnormal network traffic patterns',
            DateTime.now(),
            'Medium',
            'Network traffic patterns indicate potential security issues:\n\n'
                '1. Unusual data transfer volumes\n'
                '2. Multiple failed connection attempts\n'
                '3. Suspicious port activity\n\n'
                'Recommended actions:\n'
                '1. Analyze network traffic patterns\n'
                '2. Review firewall logs\n'
                '3. Check for unauthorized access\n'
                '4. Implement traffic monitoring',
          ));
        }
      }

      // Notify listeners of new threats
      for (var listener in _threatListeners) {
        listener(threats);
      }
    } catch (e) {
      print('Error checking for threats: $e');
    }
  }

  // Scan for vulnerabilities
  Future<void> scanForVulnerabilities(String ip) async {
    try {
      final List<VulnerabilityResult> vulnerabilities = [];

      // Check for open ports
      final openPorts = await _scanPorts(ip);
      if (openPorts.isNotEmpty) {
        vulnerabilities.add(VulnerabilityResult(
          'Open Ports',
          'Multiple ports are open and accessible',
          'High',
          'The following ports are open and potentially vulnerable:\n\n'
              '${openPorts.join('\n')}\n\n'
              'Recommended actions:\n'
              '1. Close unnecessary ports\n'
              '2. Implement firewall rules\n'
              '3. Review port security policies\n'
              '4. Document required open ports',
        ));
      }

      // Check for weak security configurations
      final weakConfigs = await _checkSecurityConfigurations(ip);
      if (weakConfigs.isNotEmpty) {
        vulnerabilities.add(VulnerabilityResult(
          'Weak Security Configuration',
          'System has weak security settings',
          'High',
          'The following security issues were detected:\n\n'
              '${weakConfigs.join('\n')}\n\n'
              'Recommended actions:\n'
              '1. Update security configurations\n'
              '2. Implement stronger authentication\n'
              '3. Enable encryption\n'
              '4. Review security policies',
        ));
      }

      // Check for outdated software
      final outdatedSoftware = await _checkSoftwareVersions(ip);
      if (outdatedSoftware.isNotEmpty) {
        vulnerabilities.add(VulnerabilityResult(
          'Outdated Software',
          'System is running outdated software versions',
          'Medium',
          'The following software components need updates:\n\n'
              '${outdatedSoftware.join('\n')}\n\n'
              'Recommended actions:\n'
              '1. Update all software components\n'
              '2. Enable automatic updates\n'
              '3. Review update policies\n'
              '4. Implement patch management',
        ));
      }

      // Notify listeners of vulnerabilities
      for (var listener in _vulnerabilityListeners) {
        listener(vulnerabilities);
      }
    } catch (e) {
      print('Error scanning for vulnerabilities: $e');
    }
  }

  // Helper methods for actual network scanning
  Future<List<String>> _checkSuspiciousIPs(String localIP) async {
    final List<String> suspiciousIPs = [];
    try {
      // Get active connections
      final result = await Process.run('netstat', ['-an']);
      final lines = result.stdout.toString().split('\n');

      // Check for connections to known malicious IPs
      for (var line in lines) {
        if (line.contains('ESTABLISHED')) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 5) {
            final remoteIP = parts[4].split(':')[0];
            if (_isSuspiciousIP(remoteIP)) {
              suspiciousIPs.add(remoteIP);
            }
          }
        }
      }
    } catch (e) {
      print('Error checking suspicious IPs: $e');
    }
    return suspiciousIPs;
  }

  Future<bool> _checkUnusualTraffic() async {
    try {
      // Get network statistics
      final result = await Process.run('netstat', ['-i']);
      final lines = result.stdout.toString().split('\n');

      // Analyze traffic patterns
      for (var line in lines) {
        if (line.contains('wlan0') || line.contains('eth0')) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 8) {
            final packets = int.tryParse(parts[3]) ?? 0;
            final errors = int.tryParse(parts[4]) ?? 0;

            // Check for unusual patterns
            if (errors > 0 || packets > 1000) {
              return true;
            }
          }
        }
      }
    } catch (e) {
      print('Error checking unusual traffic: $e');
    }
    return false;
  }

  Future<List<String>> _scanPorts(String ip) async {
    final List<String> openPorts = [];
    try {
      // Scan common ports
      final commonPorts = [21, 22, 23, 25, 53, 80, 443, 3306, 3389];
      for (var port in commonPorts) {
        try {
          final socket = await Socket.connect(ip, port,
              timeout: const Duration(seconds: 1));
          openPorts.add('Port $port (${_getPortService(port)})');
          socket.destroy();
        } catch (e) {
          // Port is closed or filtered
        }
      }
    } catch (e) {
      print('Error scanning ports: $e');
    }
    return openPorts;
  }

  Future<List<String>> _checkSecurityConfigurations(String ip) async {
    final List<String> weakConfigs = [];
    try {
      // Check for common security misconfigurations
      final result = await Process.run('netstat', ['-anp']);
      final lines = result.stdout.toString().split('\n');

      // Check for services running as root
      for (var line in lines) {
        if (line.contains('root')) {
          weakConfigs.add('Service running as root: ${line.trim()}');
        }
      }
    } catch (e) {
      print('Error checking security configurations: $e');
    }
    return weakConfigs;
  }

  Future<List<String>> _checkSoftwareVersions(String ip) async {
    final List<String> outdatedSoftware = [];
    try {
      // Check for outdated software versions
      final result = await Process.run('netstat', ['-anp']);
      final lines = result.stdout.toString().split('\n');

      // Check for known outdated services
      for (var line in lines) {
        if (line.contains('apache2') ||
            line.contains('mysql') ||
            line.contains('ssh')) {
          outdatedSoftware.add('Potentially outdated service: ${line.trim()}');
        }
      }
    } catch (e) {
      print('Error checking software versions: $e');
    }
    return outdatedSoftware;
  }

  bool _isSuspiciousIP(String ip) {
    // Check if IP is in known malicious ranges
    // This is a simplified example - in a real app, you'd check against a database
    return ip.startsWith('192.168.') ||
        ip.startsWith('10.') ||
        ip.startsWith('172.16.');
  }

  String _getPortService(int port) {
    switch (port) {
      case 21:
        return 'FTP';
      case 22:
        return 'SSH';
      case 23:
        return 'Telnet';
      case 25:
        return 'SMTP';
      case 53:
        return 'DNS';
      case 80:
        return 'HTTP';
      case 443:
        return 'HTTPS';
      case 3306:
        return 'MySQL';
      case 3389:
        return 'RDP';
      default:
        return 'Unknown';
    }
  }
}
