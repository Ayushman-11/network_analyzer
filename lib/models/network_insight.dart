class NetworkInsight {
  final String interfaceName;
  final String ipAddress;
  final NetworkSpeed speed;
  final List<NetworkConnection> activeConnections;
  final DateTime timestamp;
  final List<String> anomalies;

  NetworkInsight({
    required this.interfaceName,
    required this.ipAddress,
    required this.speed,
    required this.activeConnections,
    required this.timestamp,
    this.anomalies = const [],
  });

  factory NetworkInsight.fromJson(Map<String, dynamic> json) {
    return NetworkInsight(
      interfaceName: json['interfaceName'],
      ipAddress: json['ipAddress'],
      speed: NetworkSpeed.fromJson(json['networkSpeed']),
      activeConnections: (json['activeConnections'] as List)
          .map((conn) => NetworkConnection.fromJson(conn))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
      anomalies: List<String>.from(json['anomalies'] ?? []),
    );
  }
}

class NetworkSpeed {
  final double download;
  final double upload;
  final double latency;

  NetworkSpeed({
    required this.download,
    required this.upload,
    required this.latency,
  });

  factory NetworkSpeed.fromJson(Map<String, dynamic> json) {
    return NetworkSpeed(
      download: json['download'].toDouble(),
      upload: json['upload'].toDouble(),
      latency: json['latency'].toDouble(),
    );
  }
}

class NetworkConnection {
  final String localAddress;
  final String remoteAddress;
  final String protocol;
  final String state;

  NetworkConnection({
    required this.localAddress,
    required this.remoteAddress,
    required this.protocol,
    required this.state,
  });

  factory NetworkConnection.fromJson(Map<String, dynamic> json) {
    return NetworkConnection(
      localAddress: json['localAddress'],
      remoteAddress: json['remoteAddress'],
      protocol: json['protocol'],
      state: json['state'],
    );
  }
}
