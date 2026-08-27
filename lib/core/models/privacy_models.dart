enum AppPermissionKind {
  notifications,
  microphone,
  camera,
  photos,
  fileReadWrite,
  allFilesAccess,
  workspaceFolder,
}

enum PermissionPurpose {
  modelDownloadProgress,
  speechToText,
  cameraAttachment,
  imageAttachment,
  workspaceAccess,
  modelStorageAccess,
  fileAccess,
}

enum PermissionDecision {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  systemPickerGranted,
  systemPickerCancelled,
}

class PermissionAuditEntry {
  const PermissionAuditEntry({
    required this.id,
    required this.permission,
    required this.purpose,
    required this.decision,
    required this.requestedAt,
    this.detail,
  });

  final int id;
  final AppPermissionKind permission;
  final PermissionPurpose purpose;
  final PermissionDecision decision;
  final DateTime requestedAt;
  final String? detail;

  factory PermissionAuditEntry.fromDatabase(Map<String, Object?> row) =>
      PermissionAuditEntry(
        id: row['id']! as int,
        permission: AppPermissionKind.values.byName(
          row['permission']! as String,
        ),
        purpose: PermissionPurpose.values.byName(row['purpose']! as String),
        decision: PermissionDecision.values.byName(row['decision']! as String),
        requestedAt: DateTime.fromMillisecondsSinceEpoch(
          row['requested_at']! as int,
        ),
        detail: row['detail'] as String?,
      );
}

class WorkLogEntry {
  const WorkLogEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.detail,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String category;
  final String title;
  final String detail;
  final String status;
  final DateTime createdAt;

  factory WorkLogEntry.fromDatabase(Map<String, Object?> row) => WorkLogEntry(
    id: row['id']! as int,
    category: row['category']! as String,
    title: row['title']! as String,
    detail: row['detail']! as String,
    status: row['status']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
  );
}
