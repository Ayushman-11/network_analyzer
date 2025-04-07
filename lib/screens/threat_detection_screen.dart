import 'package:flutter/material.dart';
import 'dart:async';
import '../services/network_security_service.dart';
import '../models/security_models.dart';

class ThreatDetectionScreen extends StatefulWidget {
  const ThreatDetectionScreen({super.key});

  @override
  State<ThreatDetectionScreen> createState() => _ThreatDetectionScreenState();
}

class _ThreatDetectionScreenState extends State<ThreatDetectionScreen>
    with SingleTickerProviderStateMixin {
  final NetworkSecurityService _securityService = NetworkSecurityService();
  bool _isMonitoring = false;
  List<ThreatResult> _threats = [];
  bool _isSimulated = false;
  Function(List<ThreatResult>)? _threatListener;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _startMonitoring();
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_threatListener != null) {
      _securityService.removeThreatListener(_threatListener!);
    }
    _securityService.stopThreatMonitoring();
    super.dispose();
  }

  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
    });

    _threatListener = (List<ThreatResult> threats) {
      setState(() {
        if (threats.isEmpty) {
          // Show simulated threats for demonstration
          _threats = [
            ThreatResult(
              'Suspicious Network Activity',
              'Multiple failed login attempts detected',
              DateTime.now(),
              'High',
              'Multiple failed login attempts from IP address 192.168.1.100. This could indicate a brute force attack attempt.',
            ),
            ThreatResult(
              'Unusual Port Activity',
              'Port 3389 (RDP) opened unexpectedly',
              DateTime.now(),
              'Medium',
              'Remote Desktop Protocol port was opened without user authorization. This could be a sign of unauthorized access attempt.',
            ),
            ThreatResult(
              'Malware Signature Detected',
              'Potential malware activity in system files',
              DateTime.now(),
              'High',
              'Suspicious file modification detected in system directory. File signature matches known malware patterns.',
            ),
          ];
          _isSimulated = true;
        } else {
          _threats = threats;
          _isSimulated = false;
        }
      });
      _animationController.forward(from: 0.0);
      return threats;
    };

    _securityService.addThreatListener(_threatListener!);
    _securityService.startThreatMonitoring();
  }

  void _stopMonitoring() {
    setState(() {
      _isMonitoring = false;
      _threats = [];
      _isSimulated = false;
    });
    if (_threatListener != null) {
      _securityService.removeThreatListener(_threatListener!);
      _threatListener = null;
    }
    _securityService.stopThreatMonitoring();
  }

  Color _getThreatLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('DarkNetX Threat Detection'),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _isMonitoring ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  _isMonitoring ? Icons.stop : Icons.play_arrow,
                  color: _isMonitoring ? Colors.red : Colors.green,
                ),
                onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About Threat Detection'),
                    content: const Text(
                      'Threat detection monitors your network for potential security threats and suspicious activities. Use this tool responsibly and only on networks you own or have permission to monitor.',
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
        if (_isSimulated)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonitoringCard(),
                const SizedBox(height: 16),
                _buildThreatListCard(),
                const SizedBox(height: 16),
                _buildThreatInfoCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonitoringCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_arrow,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Monitoring: $_isMonitoring',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.warning,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Threats: ${_threats.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.sim_card,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Simulated: $_isSimulated',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.play_arrow,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Start/Stop',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.play_arrow,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Reset',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThreatListCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Threats',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _threats.length,
            itemBuilder: (context, index) {
              final threat = _threats[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _getThreatLevelColor(threat.level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning,
                      color: _getThreatLevelColor(threat.level),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        threat.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        threat.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _getThreatLevelColor(threat.level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      threat.level,
                      style: TextStyle(
                        color: _getThreatLevelColor(threat.level),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Detailed Description',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.grey[800],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            threat.detailedDescription,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Detected: ${threat.timestamp.toString().split('.')[0]}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThreatInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Threat Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This section provides detailed information about the threats detected. Use this information to understand the nature of the threats and take appropriate action.',
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
