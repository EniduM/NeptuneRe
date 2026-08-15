import 'package:intl/intl.dart';

import '../models/api_models.dart';

String formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return DateFormat('dd MMM yyyy').format(dt);
}

String formatTime(DateTime? dt) {
  if (dt == null) return '—';
  return DateFormat('hh:mm a').format(dt);
}

String formatDateTime(DateTime? dt) {
  if (dt == null) return '—';
  return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
}

String formatWeight(double kg) {
  final formatted = kg.toStringAsFixed(2);
  if (formatted.endsWith('.00')) return kg.toStringAsFixed(0);
  if (formatted.endsWith('0')) return kg.toStringAsFixed(1);
  return formatted;
}

String statusLabel(RequestStatus status) => switch (status) {
      RequestStatus.pending => 'PENDING',
      RequestStatus.accepted => 'ACCEPTED',
      RequestStatus.completed => 'COMPLETED',
      RequestStatus.cancelled => 'CANCELLED',
    };

String statusHint(RequestStatus status) => switch (status) {
      RequestStatus.pending => 'Awaiting a Rider to accept',
      RequestStatus.accepted => 'A Rider is on the way',
      RequestStatus.completed => 'Collection completed',
      RequestStatus.cancelled => 'Request was cancelled',
    };