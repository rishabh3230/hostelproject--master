// Read compatibility only: never invent balances or rewrite historical records.
class StudentRecord {
  final String id;
  final Map<String, dynamic> data;
  StudentRecord(this.id, Map<String, dynamic> source)
    : data = {
        ...source,
        for (final entry in {
          'block': 'hostelBlock',
          'roomNumber': 'roomAllotted',
          'contact': 'phone',
          'fatherContact': 'parentsContact',
          'caste': 'casteCategory',
        }.entries)
          entry.key: source[entry.key] ?? source[entry.value],
      };

  String text(String field) {
    final value = data[field];
    return value == null || value.toString().trim().isEmpty
        ? 'Not recorded'
        : value.toString();
  }

  num? amount(String field) {
    final value = data[field];
    return value is num &&
            value.isFinite &&
            value >= 0 &&
            value == value.roundToDouble()
        ? value
        : null;
  }

  bool get hasFees => [
    'feeTotal',
    'manualPaid',
    'onlinePaid',
  ].every((key) => amount(key) != null);
  bool get canManage => data['authUid'] == id && hasFees;
  num? get paid =>
      hasFees ? amount('manualPaid')! + amount('onlinePaid')! : null;
}
