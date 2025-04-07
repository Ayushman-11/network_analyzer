import 'dart:async';
import 'dart:io';

class NetworkUtils {
  static Future<Map<String, dynamic>> measureNetworkSpeed() async {
    try {
      // Measure download speed
      final downloadSpeed = await _measureDownloadSpeed();

      // Measure upload speed
      final uploadSpeed = await _measureUploadSpeed();

      // Measure latency
      final latency = await _measureLatency();

      return {
        'download': downloadSpeed,
        'upload': uploadSpeed,
        'latency': latency,
      };
    } catch (e) {
      print('Error measuring network speed: $e');
      return {
        'download': 0,
        'upload': 0,
        'latency': 0,
      };
    }
  }

  static Future<double> _measureDownloadSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      final client = HttpClient();

      final request =
          await client.getUrl(Uri.parse('https://speed.cloudflare.com/__down'));
      final response = await request.close();

      int bytesReceived = 0;
      await for (final chunk in response) {
        bytesReceived += chunk.length;
      }

      stopwatch.stop();
      final duration =
          stopwatch.elapsed.inMilliseconds / 1000; // Convert to seconds

      return (bytesReceived * 8) / (1024 * 1024 * duration); // Convert to Mbps
    } catch (e) {
      print('Error measuring download speed: $e');
      return 0;
    }
  }

  static Future<double> _measureUploadSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      final client = HttpClient();

      final request =
          await client.postUrl(Uri.parse('https://speed.cloudflare.com/__up'));
      final data = List<int>.generate(1024 * 1024, (i) => 0); // 1MB of data
      request.add(data);

      final response = await request.close();
      await response.drain<void>();

      stopwatch.stop();
      final duration =
          stopwatch.elapsed.inMilliseconds / 1000; // Convert to seconds

      return (data.length * 8) / (1024 * 1024 * duration); // Convert to Mbps
    } catch (e) {
      print('Error measuring upload speed: $e');
      return 0;
    }
  }

  static Future<double> _measureLatency() async {
    try {
      // Try multiple hosts in case one is down
      final hosts = [
        '8.8.8.8', // Google DNS
        '1.1.1.1', // Cloudflare DNS
        '208.67.222.222', // OpenDNS
      ];

      double bestLatency = double.infinity;

      for (final host in hosts) {
        try {
          final stopwatch = Stopwatch()..start();
          final socket = await Socket.connect(host, 53,
              timeout: const Duration(seconds: 2));
          stopwatch.stop();
          await socket.close();

          final latency = stopwatch.elapsed.inMilliseconds.toDouble();
          if (latency < bestLatency) {
            bestLatency = latency;
          }
        } catch (e) {
          print('Error measuring latency for $host: $e');
          continue;
        }
      }

      return bestLatency == double.infinity ? 0 : bestLatency;
    } catch (e) {
      print('Error measuring latency: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveConnections() async {
    try {
      if (Platform.isAndroid) {
        // For Android, try to get connections without root first
        try {
          final result = await Process.run('netstat', ['-an']);
          return _parseNetstatOutput(result.stdout.toString());
        } catch (e) {
          print('Error getting connections without root: $e');
          return [];
        }
      } else {
        final result = await Process.run('netstat', ['-an']);
        return _parseNetstatOutput(result.stdout.toString());
      }
    } catch (e) {
      print('Error getting active connections: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseNetstatOutput(String output) {
    final connections = <Map<String, dynamic>>[];
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.contains('ESTABLISHED') || line.contains('LISTENING')) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          connections.add({
            'localAddress': parts[1],
            'remoteAddress': parts[2],
            'protocol': parts[0],
            'state': parts[3],
          });
        }
      }
    }

    return connections;
  }

  static Future<List<Map<String, dynamic>>> getInterfaceConnections(
      String interfaceName) async {
    try {
      if (Platform.isAndroid) {
        // For Android, try to get interface info without root
        try {
          // Get all connections
          final allConnections = await getActiveConnections();

          // Filter connections based on interface name
          return allConnections.where((conn) {
            final localAddr = conn['localAddress'].toString();
            // Check if the connection belongs to the selected interface
            return localAddr.contains(interfaceName) ||
                localAddr.contains('0.0.0.0') ||
                localAddr.contains('::');
          }).toList();
        } catch (e) {
          print('Error getting interface connections without root: $e');
          return [];
        }
      } else {
        // For other platforms, use netstat with interface filter
        final result =
            await Process.run('netstat', ['-an', '-i', interfaceName]);
        return _parseNetstatOutput(result.stdout.toString());
      }
    } catch (e) {
      print('Error getting interface connections: $e');
      return [];
    }
  }

  static Future<String?> getInterfaceIpAddress(String interfaceName) async {
    try {
      if (Platform.isAndroid) {
        // For Android, try to get IP address without root
        try {
          final result =
              await Process.run('ip', ['addr', 'show', interfaceName]);
          final lines = result.stdout.toString().split('\n');

          for (final line in lines) {
            if (line.contains('inet ')) {
              final ipMatch =
                  RegExp(r'inet (\d+\.\d+\.\d+\.\d+)').firstMatch(line);
              if (ipMatch != null) {
                return ipMatch.group(1);
              }
            }
          }
        } catch (e) {
          print('Error getting IP address without root: $e');
        }
      } else {
        final result = await Process.run('ifconfig', [interfaceName]);
        final lines = result.stdout.toString().split('\n');

        for (final line in lines) {
          if (line.contains('inet ')) {
            final ipMatch =
                RegExp(r'inet (\d+\.\d+\.\d+\.\d+)').firstMatch(line);
            if (ipMatch != null) {
              return ipMatch.group(1);
            }
          }
        }
      }
    } catch (e) {
      print('Error getting interface IP address: $e');
    }
    return null;
  }
}
