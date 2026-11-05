import 'package:flutter/material.dart';
import 'dividend_models.dart';

class DividendCalendarView extends StatefulWidget {
  const DividendCalendarView({
    super.key,
    required this.allDividends,
    required this.focusedMonth,
    required this.selectedDay,
    required this.showForeignInKrw,
    required this.onFocusedMonthChanged,
    required this.onSelectedDayChanged,
    required this.onShowForeignInKrwChanged,
  });

  final List<UpcomingDividend> allDividends;
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final bool showForeignInKrw;
  final ValueChanged<DateTime> onFocusedMonthChanged;
  final ValueChanged<DateTime?> onSelectedDayChanged;
  final ValueChanged<bool> onShowForeignInKrwChanged;

  @override
  State<DividendCalendarView> createState() => _DividendCalendarViewState();
}

class _DividendCalendarViewState extends State<DividendCalendarView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int year = widget.focusedMonth.year;
    final int month = widget.focusedMonth.month;
    
    final DateTime firstDay = DateTime(year, month, 1);
    final int startOffset = firstDay.weekday % 7;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    
    final int totalCells = startOffset + daysInMonth;
    final int rowsCount = (totalCells / 7).ceil();
    final int gridCellCount = rowsCount * 7;
    
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    final Map<int, List<UpcomingDividend>> dailyDividends = {};
    for (var div in widget.allDividends) {
      if (div.paymentDate.year == year && div.paymentDate.month == month) {
        final day = div.paymentDate.day;
        dailyDividends.putIfAbsent(day, () => []).add(div);
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        final newMonth = DateTime(widget.focusedMonth.year, widget.focusedMonth.month - 1);
                        widget.onFocusedMonthChanged(newMonth);
                        widget.onSelectedDayChanged(DateTime(newMonth.year, newMonth.month, 1));
                      },
                    ),
                    Text(
                      '$year년 $month월',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final newMonth = DateTime(widget.focusedMonth.year, widget.focusedMonth.month + 1);
                        widget.onFocusedMonthChanged(newMonth);
                        widget.onSelectedDayChanged(DateTime(newMonth.year, newMonth.month, 1));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekdays.map((day) {
                    Color textColor = isDark ? Colors.grey[400]! : const Color(0xFF8C847A);
                    if (day == '일') textColor = const Color(0xFFEAA622);
                    if (day == '토') textColor = Colors.blue;
                    return SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: gridCellCount,
                  itemBuilder: (context, index) {
                    final int dayNumber = index - startOffset + 1;
                    final bool isActualDay = dayNumber > 0 && dayNumber <= daysInMonth;
                    
                    if (!isActualDay) {
                      return const SizedBox.shrink();
                    }
                    
                    final DateTime cellDate = DateTime(year, month, dayNumber);
                    final bool isSelected = widget.selectedDay != null && 
                        widget.selectedDay!.year == cellDate.year && 
                        widget.selectedDay!.month == cellDate.month && 
                        widget.selectedDay!.day == cellDate.day;
                    
                    final bool isToday = DateTime.now().year == cellDate.year && 
                        DateTime.now().month == cellDate.month && 
                        DateTime.now().day == cellDate.day;
                    
                    final hasDividends = dailyDividends.containsKey(dayNumber);
                    
                    Color textColor = isDark ? Colors.white : Colors.black87;
                    if (index % 7 == 0) textColor = const Color(0xFFEAA622);
                    if (index % 7 == 6) textColor = Colors.blue;
                    
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        widget.onSelectedDayChanged(cellDate);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected 
                              ? const Color(0xFF176B5B) 
                              : (isToday ? (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEFEFEF)) : Colors.transparent),
                          border: isToday && !isSelected
                              ? Border.all(color: const Color(0xFF176B5B), width: 1)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayNumber.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : textColor,
                              ),
                            ),
                            if (hasDividends) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white : const Color(0xFFEAA622),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (widget.selectedDay != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${widget.selectedDay!.month}월 ${_selectedDayString(widget.selectedDay!.day)} 배당 정보',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '해외자산 원화 환산',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                      ),
                    ),
                    const SizedBox(width: 2),
                    SizedBox(
                      height: 28,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Switch(
                          value: widget.showForeignInKrw,
                          onChanged: widget.onShowForeignInKrwChanged,
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDailyDividendList(context, isDark, dailyDividends[widget.selectedDay!.day] ?? []),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _selectedDayString(int day) => '$day일';

  Widget _buildDailyDividendList(BuildContext context, bool isDark, List<UpcomingDividend> dayDividends) {
    if (dayDividends.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 40, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              '이 날짜에는 예정된 배당금이 없습니다.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: dayDividends.map((div) {
        final formattedNativeTotal = div.currency == 'KRW'
            ? '₩${formatDividendNumber(div.krwAmount.round())}'
            : '${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.totalAmount.toStringAsFixed(2)}';
            
        final displayTotal = (widget.showForeignInKrw || div.currency == 'KRW')
            ? '₩${formatDividendNumber(div.krwAmount.round())}'
            : formattedNativeTotal;
            
        String displayAmountPerShare;
        if (div.currency == 'KRW') {
          displayAmountPerShare = '주당 ${formatDividendNumber(div.amountPerShare.round())}원';
        } else if (widget.showForeignInKrw) {
          final double exchangeRate = div.totalAmount > 0 ? (div.krwAmount / div.totalAmount) : 1350.0;
          final double krwPerShare = div.amountPerShare * exchangeRate;
          displayAmountPerShare = '주당 ${formatDividendNumber(krwPerShare.round())}원';
        } else {
          displayAmountPerShare = '주당 ${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.amountPerShare.toStringAsFixed(2)}';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: div.isHistorical
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                      : const Color(0xFF176B5B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  div.isHistorical ? Icons.check_circle_outline : Icons.show_chart,
                  color: div.isHistorical ? const Color(0xFF2E7D32) : const Color(0xFF176B5B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            div.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: div.isHistorical
                                ? const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.25 : 0.12)
                                : const Color(0xFFEAA622).withValues(alpha: isDark ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            div.isHistorical
                                ? (div.isEstimated ? '추정지급일 경과' : '지급완료')
                                : (div.isEstimated ? '지급예정(추정)' : '지급예정'),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: div.isHistorical ? const Color(0xFF2E7D32) : const Color(0xFFC27B00),
                            ),
                          ),
                        ),
                        if (div.isTaxFree) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '비과세',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          div.symbol,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '기준일 ${div.date.month}/${div.date.day}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayTotal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: div.isHistorical ? const Color(0xFF2E7D32) : const Color(0xFF176B5B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayAmountPerShare,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
