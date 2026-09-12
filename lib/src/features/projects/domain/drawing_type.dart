/// Enum representing the approved drawing types in ARCHI DRAFT.
///
/// These are the standard architectural drawing categories that a Client
/// can request when submitting a project brief.
enum DrawingType {
  floorPlan,
  elevation,
  section,
  sitePlan,
  structural,
  electrical,
  plumbing;

  /// Converts a Firestore string to a [DrawingType] enum.
  ///
  /// Returns `null` if the string does not match any known type.
  static DrawingType? fromString(String? type) {
    switch (type) {
      case 'FLOOR_PLAN':
        return DrawingType.floorPlan;
      case 'ELEVATION':
        return DrawingType.elevation;
      case 'SECTION':
        return DrawingType.section;
      case 'SITE_PLAN':
        return DrawingType.sitePlan;
      case 'STRUCTURAL':
        return DrawingType.structural;
      case 'ELECTRICAL':
        return DrawingType.electrical;
      case 'PLUMBING':
        return DrawingType.plumbing;
      default:
        return null;
    }
  }

  /// Converts this [DrawingType] to its Firestore string representation.
  String toFirestoreString() {
    switch (this) {
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
