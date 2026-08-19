import 'package:permission_handler/permission_handler.dart';

import '../database/local_database.dart';
import '../models/privacy_models.dart';

class PermissionService {
  const PermissionService(this._database);

  final LocalDatabase _database;

  Future<PermissionDecision> request(
    AppPermissionKind kind,
    PermissionPurpose purpose, {
    String? detail,
  }) async {
    final permission = _runtimePermission(kind);
    if (permission == null) {
      throw ArgumentError.value(
        kind,
        'kind',
        'Use recordSystemPicker instead.',
      );
    }
    final status = await permission.request();
    final decision = _decision(status);
    await _database.addPermissionAudit(
      permission: kind,
      purpose: purpose,
      decision: decision,
      detail: detail,
    );
    return decision;
  }

  Future<PermissionStatus?> status(AppPermissionKind kind) async =>
      _runtimePermission(kind)?.status;

  Future<void> recordSystemPicker({
    required AppPermissionKind kind,
    required PermissionPurpose purpose,
    required bool granted,
    String? detail,
  }) => _database.addPermissionAudit(
    permission: kind,
    purpose: purpose,
    decision: granted
        ? PermissionDecision.systemPickerGranted
        : PermissionDecision.systemPickerCancelled,
    detail: detail,
  );

  Future<bool> openSystemSettings() => openAppSettings();

  Permission? _runtimePermission(AppPermissionKind kind) => switch (kind) {
    AppPermissionKind.notifications => Permission.notification,
    AppPermissionKind.microphone => Permission.microphone,
    AppPermissionKind.camera => Permission.camera,
    AppPermissionKind.photos => Permission.photos,
    AppPermissionKind.workspaceFolder => null,
  };

  PermissionDecision _decision(PermissionStatus status) {
    if (status.isGranted) return PermissionDecision.granted;
    if (status.isPermanentlyDenied) {
      return PermissionDecision.permanentlyDenied;
    }
    if (status.isRestricted) return PermissionDecision.restricted;
    if (status.isLimited) return PermissionDecision.limited;
    return PermissionDecision.denied;
  }
}
