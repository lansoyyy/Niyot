import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.photographerData});

  final Map<String, dynamic> photographerData;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Sample booked dates (in real app, fetch from API)
  final Set<DateTime> _bookedDates = {
    DateTime(2026, 3, 15),
    DateTime(2026, 3, 16),
    DateTime(2026, 3, 20),
    DateTime(2026, 3, 22),
    DateTime(2026, 3, 25),
    DateTime(2026, 3, 26),
    DateTime(2026, 3, 27),
  };

  // Sample available time slots for selected day
  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '9:00 AM', 'available': true},
    {'time': '10:00 AM', 'available': true},
    {'time': '11:00 AM', 'available': false},
    {'time': '12:00 PM', 'available': false},
    {'time': '1:00 PM', 'available': true},
    {'time': '2:00 PM', 'available': true},
    {'time': '3:00 PM', 'available': false},
    {'time': '4:00 PM', 'available': true},
  ];

  bool _isDayBooked(DateTime day) {
    return _bookedDates.any(
      (date) =>
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.photographerData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF374151),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Availability',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: Column(
        children: [
          // Photographer summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: List<Color>.from(data['gradient'] as List),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      data['initials'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        data['specialty'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Available',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Calendar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: const Color(0xFFC62828).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: GoogleFonts.poppins(
                  color: const Color(0xFFC62828),
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFC62828),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                defaultTextStyle: GoogleFonts.poppins(
                  color: const Color(0xFF374151),
                  fontSize: 14,
                ),
                weekendTextStyle: GoogleFonts.poppins(
                  color: const Color(0xFFC62828),
                  fontSize: 14,
                ),
                outsideTextStyle: GoogleFonts.poppins(
                  color: const Color(0xFFBDBDBD),
                  fontSize: 14,
                ),
                markerDecoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
                formatButtonTextStyle: GoogleFonts.poppins(
                  color: const Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF374151),
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF374151),
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9E9E9E),
                ),
                weekendStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC62828),
                ),
              ),
              eventLoader: (day) {
                if (_isDayBooked(day)) {
                  return ['booked'];
                }
                return [];
              },
            ),
          ),
          // Legend
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                _buildLegendItem(
                  color: const Color(0xFFE53935),
                  label: 'Booked',
                ),
                const SizedBox(width: 20),
                _buildLegendItem(
                  color: const Color(0xFF2E7D32),
                  label: 'Available',
                ),
                const SizedBox(width: 20),
                _buildLegendItem(
                  color: const Color(0xFFC62828),
                  label: 'Selected',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Time slots
          Expanded(
            child: Container(
              color: const Color(0xFFF8F8F8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      _selectedDay != null
                          ? 'Available slots for ${_formatDate(_selectedDay!)}'
                          : 'Select a date to view available slots',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _selectedDay != null
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 2.5,
                                ),
                            itemCount: _timeSlots.length,
                            itemBuilder: (context, index) {
                              final slot = _timeSlots[index];
                              final isAvailable = slot['available'] as bool;
                              return GestureDetector(
                                onTap: isAvailable
                                    ? () {
                                        // Navigate to booking with selected time
                                        Navigator.of(context).pop({
                                          'date': _selectedDay,
                                          'time': slot['time'],
                                        });
                                      }
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? Colors.white
                                        : const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isAvailable
                                          ? const Color(0xFFE5E7EB)
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isAvailable)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 14,
                                            color: Color(0xFF2E7D32),
                                          )
                                        else
                                          const Icon(
                                            Icons.block_rounded,
                                            size: 14,
                                            color: Color(0xFF9E9E9E),
                                          ),
                                        const SizedBox(width: 6),
                                        Text(
                                          slot['time'] as String,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isAvailable
                                                ? const Color(0xFF1A1A1A)
                                                : const Color(0xFF9E9E9E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Select a date to continue',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
