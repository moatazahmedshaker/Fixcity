import 'package:flutter/material.dart';

// ── FixCity Design Tokens ──────────────────────────────────────────────────
const kRed     = Color(0xFFCC0000);
const kBlue    = Color(0xFF185FA5);
const kDark    = Color(0xFF1A1A2E);
const kDark2   = Color(0xFF16213E);
const kAccent  = Color(0xFFE8B4B8);
const kBg      = Color(0xFFF0F4F8);
const kWhite   = Colors.white;
const kGrey    = Color(0xFF64748B);
const kSuccess = Color(0xFF16A34A);
const kWarning = Color(0xFFF59E0B);

// Status colors
Color statusColor(String status) {
  switch (status) {
    case 'pending':     return kWarning;
    case 'in_progress': return kBlue;
    case 'resolved':    return kSuccess;
    default:            return kGrey;
  }
}

String statusLabel(String status, String lang) {
  final isAr = lang == 'ar';
  switch (status) {
    case 'pending':     return isAr ? 'قيد الانتظار' : 'Pending';
    case 'in_progress': return isAr ? 'جارٍ العمل'   : 'In Progress';
    case 'resolved':    return isAr ? 'تم الحل'       : 'Resolved';
    default:            return status;
  }
}
