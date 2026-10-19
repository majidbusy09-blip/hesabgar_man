import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../logic/jalali.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Jalali _focused;
  late Jalali _today;

  @override
  void initState() {
    super.initState();
    _today = Jalali.fromDateTime(DateTime.now());
    _focused = Jalali(_today.year, _today.month, 1);
  }

  void _prevMonth() => setState(() => _focused = _focused.addMonths(-1));
  void _nextMonth() => setState(() => _focused = _focused.addMonths(1));
  void _goToday() =>
      setState(() => _focused = Jalali(_today.year, _today.month, 1));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysInMonth = _focused.monthLength;
    final firstWeekday = Jalali(_focused.year, _focused.month, 1).weekdayIndex;
    // تعداد خانه خالی قبل از روز ۱
    final leading = firstWeekday;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقویم شمسی'),
        actions: [
          TextButton(
            onPressed: _goToday,
            child: const Text('امروز',
                style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          // هدر ماه
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_focused.monthName} ${_focused.year}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // روزهای هفته
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: Jalali.weekDays
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d.substring(0, d.length >= 2 ? 2 : 1),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: d == 'جمعه'
                                  ? AppColors.secondary
                                  : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // شبکه روزها
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: rows * 7,
                itemBuilder: (context, index) {
                  final dayNum = index - leading + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final isToday = _focused.year == _today.year &&
                      _focused.month == _today.month &&
                      dayNum == _today.day;

                  final cellDate =
                      Jalali(_focused.year, _focused.month, dayNum);
                  final isFriday = cellDate.weekdayIndex == 6;

                  return Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : (isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? null
                          : Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              width: 0.5,
                            ),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 16,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday
                              ? Colors.white
                              : (isFriday
                                  ? AppColors.secondary
                                  : (isDark ? Colors.white : Colors.black87)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // اطلاعات امروز
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'امروز: ${Jalali.weekDays[_today.weekdayIndex]}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_today.day} ${_today.monthName} ${_today.year}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  () {
                    final g = DateTime.now();
                    return 'معادل میلادی: ${g.year}/${g.month.toString().padLeft(2, '0')}/${g.day.toString().padLeft(2, '0')}';
                  }(),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
