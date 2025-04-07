import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

class PortScannerScreen extends StatefulWidget {
  const PortScannerScreen({super.key});

  @override
  State<PortScannerScreen> createState() => _PortScannerScreenState();
}

class _PortScannerScreenState extends State<PortScannerScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _startPortController =
      TextEditingController(text: '1');
  final TextEditingController _endPortController =
      TextEditingController(text: '1024');
  bool _isScanning = false;
  List<PortResult> _scanResults = [];
  String? _error;

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults = [];
      _error = null;
    });

    try {
      final ip = _ipController.text;
      final startPort = int.parse(_startPortController.text);
      final endPort = int.parse(_endPortController.text);

      if (startPort > endPort) {
        throw Exception('Start port must be less than end port');
      }

      for (int port = startPort; port <= endPort; port++) {
        if (!_isScanning) break;

        try {
          final socket = await Socket.connect(ip, port,
              timeout: const Duration(seconds: 1));
          await socket.close();

          setState(() {
            _scanResults.add(PortResult(port, true));
          });
        } catch (e) {
          setState(() {
            _scanResults.add(PortResult(port, false));
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('DarkNetX Port Scanner'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About Port Scanning'),
                    content: const Text(
                      'Port scanning helps identify open ports and potential security vulnerabilities in your network. Use this tool responsibly and only on networks you own or have permission to scan.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputCard(),
                const SizedBox(height: 16),
                _buildScanResultsCard(),
                const SizedBox(height: 16),
                _buildPortInfoCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Port Scanner',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: 'Enter IP address to scan',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startPortController,
                    decoration: const InputDecoration(
                      labelText: 'Start Port',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endPortController,
                    decoration: const InputDecoration(
                      labelText: 'End Port',
                      hintText: '1024',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isScanning ? _stopScan : _startScan,
              child: Text(_isScanning ? 'Stop Scan' : 'Start Scan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_scanResults.isEmpty)
              const Center(
                child: Text('No scan results available'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _scanResults.length,
                itemBuilder: (context, index) {
                  final result = _scanResults[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: result.isOpen
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        result.isOpen ? Icons.check_circle : Icons.cancel,
                        color: result.isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text('Port ${result.port}'),
                    subtitle: Text(
                      result.isOpen ? 'Open' : 'Closed',
                    ),
                    trailing: result.isOpen
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Open',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortInfoCard() {
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
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Port Scanning Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Port scanning helps identify open ports and potential security vulnerabilities in your network. Use this tool responsibly and only on networks you own or have permission to scan.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Common ports include:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildPortItem('21', 'FTP'),
            _buildPortItem('22', 'SSH'),
            _buildPortItem('23', 'Telnet'),
            _buildPortItem('25', 'SMTP'),
            _buildPortItem('80', 'HTTP'),
            _buildPortItem('443', 'HTTPS'),
            _buildPortItem('3306', 'MySQL'),
            _buildPortItem('3389', 'RDP'),
          ],
        ),
      ),
    );
  }

  Widget _buildPortItem(String port, String service) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              port,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(service),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _startPortController.dispose();
    _endPortController.dispose();
    super.dispose();
  }
}

class PortResult {
  final int port;
  final bool isOpen;

  PortResult(this.port, this.isOpen);
}
