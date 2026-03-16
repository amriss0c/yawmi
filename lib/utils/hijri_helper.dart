// lib/utils/hijri_helper.dart

import 'package:hijri/hijri_calendar.dart';

class HijriHelper {
  /// Returns the Hijri day number (e.g., "14")
  static String getHijriDay(DateTime date) => HijriCalendar.fromDate(date).hDay.toString();
  
  /// Returns the FULL Hijri month name (e.g., "رمضان")
  static String getFullHijriMonthName(DateTime date) {
    return HijriCalendar.fromDate(date).longMonthName;
  }

  /// Returns Full Hijri Date for the Task Box (e.g., "14 رمضان 1447")
  static String getFullHijriDate(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    return '${h.hDay} ${h.longMonthName} ${h.hYear}';
  }

  /// Returns the Hijri Month and Year for the Header
  static String getHijriMonthRange(DateTime date, bool isArabic) {
    final h = HijriCalendar.fromDate(date);
    return '${h.longMonthName} ${h.hYear}';
  }

  /// Returns the Gregorian Month name in Arabic
  static String getGregorianMonthName(DateTime date, bool isArabic) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return isArabic ? months[date.month - 1] : "Month ${date.month}";
  }
}