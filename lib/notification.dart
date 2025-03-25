import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'AnnouncementsTab.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double containerWidth = (MediaQuery.of(context).size.width - 32) / 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFB),
      body: Padding(
        padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'Company Updates',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _selectedIndex * containerWidth + 4,
                    top: 4,
                    child: Container(
                      width: containerWidth - 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = 0;
                              _tabController.animateTo(0);
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            height: 48,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 6),
                                Text(
                                  'Announcements',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedIndex == 0 ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = 1;
                              _tabController.animateTo(1);
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            height: 48,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 6),
                                Text(
                                  'Holidays',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedIndex == 1 ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollStartNotification) {
                    if (scrollNotification.metrics.axis == Axis.horizontal) {
                      return true; // Prevent horizontal scroll
                    }
                  }
                  return false;
                },
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  children: [
                    AnnouncementsTab(),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUpcomingHolidays(),
                          const SizedBox(height: 16),
                          Text(
                            'Past Holidays',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSimpleUpcomingHolidays(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingHolidays() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Light shadow
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4), // Shadow at the bottom
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Holidays',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _holidayItem('Independence Day', '15 Aug 2023'),
          _holidayItem('Gandhi Jayanti', '2 Oct 2023'),
          _holidayItem('Diwali', '12 Nov 2023'),
          _holidayItem('Christmas', '25 Dec 2023'),
        ],
      ),
    );
  }

  Widget _holidayItem(String title, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Space between items
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC), // Light grey background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.amber.withOpacity(0.2),
                child: Icon(LucideIcons.calendar, color: Color(0xFFE3993B), size: 20),
              ),
              const SizedBox(width: 12), // Space between icon and text
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSimpleUpcomingHolidays() {
    List<Map<String, String>> holidays = [
      {'title': 'Republic Day', 'date': '26 Jan 2023'},
      {'title': 'Holi', 'date': '8 Mar 2023'},
      {'title': 'Good Friday', 'date': '7 Apr 2023'},
      {'title': 'Labor Day', 'date': '1 May 2023'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LimitedBox(
        maxHeight: holidays.length * 40.0, // Adjust height based on number of items
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: holidays
              .map((holiday) => _simpleHolidayItem(holiday['title']!, holiday['date']!))
              .toList(),
        ),
      ),
    );
  }

  Widget _simpleHolidayItem(String title, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            date,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }


}