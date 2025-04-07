class ThreatResult {
  final String title;
  final String description;
  final DateTime timestamp;
  final String level;
  final String detailedDescription;

  ThreatResult(
    this.title,
    this.description,
    this.timestamp,
    this.level,
    this.detailedDescription,
  );
}

class VulnerabilityResult {
  final String title;
  final String description;
  final String severity;
  final String detailedDescription;

  VulnerabilityResult(
    this.title,
    this.description,
    this.severity,
    this.detailedDescription,
  );
}
