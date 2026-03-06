import 'package:hijri/hijri_calendar.dart';

class HijriHelper {
  static String getHijriDay(DateTime date) => HijriCalendar.fromDate(date).hDay.toString();
  
  static String getFullHijriMonthName(DateTime date) {
    return HijriCalendar.fromDate(date).longMonthName;
  }

  static String getFullHijriDate(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    return '${h.hDay} ${h.longMonthName} ${h.hYear}';
  }

  static String getHijriMonthRange(DateTime date, bool isArabic) {
    final h = HijriCalendar.fromDate(date);
    return '${h.longMonthName} ${h.hYear}';
  }

  static String getGregorianMonthName(DateTime date, bool isArabic) {
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return isArabic ? months[date.month - 1] : "Month ${date.month}";
  }
}