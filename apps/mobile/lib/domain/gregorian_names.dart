// Weekday and Gregorian month names for the home screen (Egyptian Arabic usage
// and English), without the intl date-symbol data.

const _weekdaysAr = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const _weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthsAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];
const _monthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Name of the day of the week of [d] (y/m/d only).
String weekdayName(DateTime d, {required bool arabic}) =>
    (arabic ? _weekdaysAr : _weekdaysEn)[DateTime.utc(d.year, d.month, d.day).weekday - 1];

/// Name of month [m] (1–12).
String gregorianMonthName(int m, {required bool arabic}) => (arabic ? _monthsAr : _monthsEn)[m - 1];
