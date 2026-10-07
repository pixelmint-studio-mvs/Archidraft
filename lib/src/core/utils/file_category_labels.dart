/// Presentation-layer mapping for internal file category identifiers.
///
/// The D1/backend values (e.g. 'client_upload') are legacy schema identifiers
/// that must never be shown directly in any Engineer-facing UI.
/// This utility provides a single source-of-truth label mapping.
///
/// DO NOT rename D1 columns, worker enums, or API values here.
/// Only the user-visible label is changed.
String fileCategoryLabel(String category) {
  switch (category) {
    case 'client_upload':
      return 'Project Brief';
    case 'draughtsman_version':
      return 'Drawing Version';
    case 'correction_attachment':
      return 'Correction Attachment';
    default:
      return category
          .split('_')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
  }
}

/// Replaces all known internal file-category tokens inside a free-text string.
///
/// Used when the category identifier is embedded inside a details/description
/// string stored verbatim in D1 (e.g. "Uploaded client_upload file: foo.jpg").
String sanitiseActivityDetails(String details) {
  return details
      .replaceAll('client_upload', 'Project Brief')
      .replaceAll('draughtsman_version', 'Drawing Version')
      .replaceAll('correction_attachment', 'Correction Attachment');
}
