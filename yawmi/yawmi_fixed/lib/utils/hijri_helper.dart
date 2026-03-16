import 'package:hijri/hijri_calendar.dart';

class HijriHelper {

  static String getGregorianMonthName(DateTime date, bool arabic) {
    const monthsEn = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    const monthsAr = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    final month = arabic ? monthsAr[date.month - 1] : monthsEn[date.month - 1];
    return '$month ${date.year}';
  }

  static String getHijriMonthRange(DateTime date, bool arabic) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    final hFirst = HijriCalendar.fromDate(firstDay);
    final hLast = HijriCalendar.fromDate(lastDay);
    final n1 = arabic ? _hijriMonthAr(hFirst.hMonth) : hFirst.longMonthName;
    final n2 = arabic ? _hijriMonthAr(hLast.hMonth) : hLast.longMonthName;
    if (hFirst.hMonth == hLast.hMonth && hFirst.hYear == hLast.hYear) {
      return '$n1 ${hFirst.hYear}';
    }
    return '$n1 - $n2 ${hLast.hYear}';
  }

  static String getFullHijriDate(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    return '${_toAr(h.hDay)} ${_hijriMonthAr(h.hMonth)} ${_toAr(h.hYear)}';
  }

  static String getHijriDay(DateTime date) {
    return _toAr(HijriCalendar.fromDate(date).hDay);
  }

  static String getFullHijriMonthName(DateTime date) {
    return _hijriMonthAr(HijriCalendar.fromDate(date).hMonth);
  }

  static String getHijriDateString(DateTime date, {bool arabic = true}) {
    final h = HijriCalendar.fromDate(date);
    if (arabic) return '${_toAr(h.hDay)} ${_hijriMonthAr(h.hMonth)}';
    return '${h.hDay} ${h.longMonthName}';
  }

  static String getHijriFullString(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    return '${h.hDay} ${h.longMonthName} ${h.hYear}';
  }

  static String getGregorianMonthYear(DateTime date, {bool arabic = false}) {
    return getGregorianMonthName(date, arabic);
  }

  static String getHijriMonthYear(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    return '${h.longMonthName} ${h.hYear}';
  }

  static String _toAr(int n) {
    const w = ['0','1','2','3','4','5','6','7','8','9'];
    const a = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    var r = n.toString();
    for (int i = 0; i < w.length; i++) r = r.replaceAll(w[i], a[i]);
    return r;
  }

  static String _hijriMonthAr(int m) {
    const months = ['محرم','صفر','ربيع الأول','ربيع الآخر','جمادى الأولى','جمادى الآخرة','رجب','شعبان','رمضان','شوال','ذو القعدة','ذو الحجة'];
    return months[m - 1];
  }
}
