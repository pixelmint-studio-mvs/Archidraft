/// Enum representing the approved drawing types in ARCHI DRAFT.
///
/// These are the standard architectural drawing categories that a Client
/// can request when submitting a project brief.
enum DrawingType {
  architectural,
  floorPlan,
  elevation,
  section,
  sitePlan,
  structural,
  electrical,
  plumbing;

  /// Converts a string to a [DrawingType] enum.
  ///
  /// Supports case-insensitive matching, Firestore strings, and common aliases.
  /// Returns `null` if the string does not match any known type.
  static DrawingType? fromString(String? type) {
    if (type == null) return null;
    final trimmed = type.trim();
    if (trimmed.isEmpty) return null;

    final normalized = trimmed.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');
    switch (normalized) {
      case 'ARCHITECTURAL':
      case 'ARCHITECTURAL_DRAFTING':
      case 'ARCHITECTURAL_PLAN':
      case 'ARCH':
        return DrawingType.architectural;
      case 'FLOOR_PLAN':
      case 'FLOORPLAN':
        return DrawingType.floorPlan;
      case 'ELEVATION':
        return DrawingType.elevation;
      case 'SECTION':
        return DrawingType.section;
      case 'SITE_PLAN':
      case 'SITEPLAN':
        return DrawingType.sitePlan;
      case 'STRUCTURAL':
      case 'STRUCTURAL_DETAILING':
      case 'STRUCT':
        return DrawingType.structural;
      case 'ELECTRICAL':
      case 'MEP':
      case 'MEP_ENGINEERING':
        return DrawingType.electrical;
      case 'PLUMBING':
      case 'CIVIL':
      case 'CIVIL_ENGINEERING':
        return DrawingType.plumbing;
      default:
        for (final val in DrawingType.values) {
          if (val.name.toUpperCase() == normalized ||
              val.toFirestoreString().toUpperCase() == normalized ||
              val.displayName.toUpperCase() == normalized) {
            return val;
          }
        }
        return null;
    }
  }

  /// Converts this [DrawingType] to its Firestore string representation.
  String toFirestoreString() {
    switch (this) {
      case DrawingType.architectural:
        return 'ARCHITECTURAL';
      case DrawingType.floorPlan:
        return 'FLOOR_PLAN';
      case DrawingType.elevation:
        return 'ELEVATION';
      case DrawingType.section:
        return 'SECTION';
      case DrawingType.sitePlan:
        return 'SITE_PLAN';
      case DrawingType.structural:
        return 'STRUCTURAL';
      case DrawingType.electrical:
        return 'ELECTRICAL';
      case DrawingType.plumbing:
        return 'PLUMBING';
    }
  }

  /// User-facing display name.
  String get displayName {
    switch (this) {
      case DrawingType.architectural:
        return 'Architectural';
      case DrawingType.floorPlan:
        return 'Floor Plan';
      case DrawingType.elevation:
        return 'Elevation';
      case DrawingType.section:
        return 'Section';
      case DrawingType.sitePlan:
        return 'Site Plan';
      case DrawingType.structural:
        return 'Structural';
      case DrawingType.electrical:
        return 'Electrical';
      case DrawingType.plumbing:
        return 'Plumbing';
    }
  }
}
