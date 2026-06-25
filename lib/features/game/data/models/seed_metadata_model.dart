import '../../../../core/database/app_database.dart';

class SeedMetadataModel {
  const SeedMetadataModel({
    required this.seedKey,
    required this.seedVersion,
    required this.appliedAt,
    required this.status,
  });

  final String seedKey;
  final int seedVersion;
  final DateTime appliedAt;
  final String status;

  factory SeedMetadataModel.fromRow(SeedMetadataData row) {
    return SeedMetadataModel(
      seedKey: row.seedKey,
      seedVersion: row.seedVersion,
      appliedAt: row.appliedAt,
      status: row.status,
    );
  }
}
