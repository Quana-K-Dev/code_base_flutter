import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';

extension BuildContextX on BuildContext {
  S get s => S.of(this);
}
