import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  _LeaveManagementScreenState createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  int _selectedIndex = 0;
  bool _showApplyLeaveForm = false;
  late final PageController _pageController;
  Map<String, int> _leaveBalance = {
    'casualLeave': 0,
    'sickLeave': 0,
    'privilegeLeave': 0,
  };

  List<Map<String, dynamic>> _leaveHistory = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _fetchLeaveBalance();
    _fetchLeaveHistory();

    // TEMP: Add mock data for testing UI
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _leaveHistory = [
          {
            'startDate': '5/20/2025',
            'endDate': '5/20/2025',
            'leaveType': 'Leave',
            'status': 'Pending',
            'reason': 'Family function'
          },
          {
            'startDate': '5/20/2025',
            'endDate': '5/20/2025',
            'leaveType': 'Comp-Off',
            'status': 'Rejected',
            'reason': 'Worked on weekend'
          },
          {
            'startDate': '5/20/2025',
            'endDate': '5/22/2025',
            'leaveType': 'Leave',
            'status': 'Approved',
            'reason': 'Medical'
          },
        ];
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaveBalance() async {
    try {
      print('Fetching leave balance...');
      final response = await http.get(Uri.parse('http://192.168.0.200:8084/leaves/balance/emp123'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Leave balance fetched successfully: $data');
        setState(() {
          _leaveBalance = {
            'casualLeave': data['casualLeave'],
            'sickLeave': data['sickLeave'],
            'privilegeLeave': data['privilegeLeave'],
          };
        });
      } else {
        print('Failed to fetch leave balance. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching leave balance: $e');
    }
  }

  Future<void> _fetchLeaveHistory() async {
    try {
      print('Fetching leave history...');
      final response = await http.get(Uri.parse('http://192.168.0.200:8084/leaves/emp123'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Leave history fetched successfully: $data');
        setState(() {
          _leaveHistory = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Failed to fetch leave history. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching leave history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_NavTab> navTabs = [
      _NavTab(
        icon: Icons.account_circle_outlined,
        label: 'Balance',
        content: _LeaveBalanceTab(leaveBalance: _leaveBalance),
      ),
      _NavTab(
        icon: Icons.history,
        label: 'History',
        content: _LeaveHistoryTab(leaveHistory: _leaveHistory),
      ),
      _NavTab(
        icon: Icons.celebration,
        label: 'Holidays',
        content: const _PublicHolidaysTab(),
      ),
      _NavTab(
        icon: Icons.policy,
        label: 'Policies',
        content: const _LeavePoliciesTab(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header (screen background, black text/icons)
            Container(
              color: const Color(0xFFF4FBFB),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 26),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Leave',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // Toggle Bar (darker background, pill style)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7EF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _SwipeableSegmentedTabBar(
                tabs: navTabs,
                selectedIndex: _selectedIndex,
                onTabSelected: (i) {
                  setState(() => _selectedIndex = i);
                  _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.ease);
                  _showApplyLeaveForm = false;
                },
              ),
            ),
            const SizedBox(height: 18),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => showApplyLeaveDialog(context),
                      icon: Icon(Icons.calendar_month, color: Colors.blue.shade700),
                      label: Text('Apply for Leave', style: TextStyle(fontSize: 15, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade700, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => showApplyCompOffDialog(context),
                      icon: Icon(Icons.autorenew, color: Colors.teal.shade600),
                      label: Text('Apply for Comp-off', style: TextStyle(fontSize: 15, color: Colors.teal.shade600, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.teal.shade600, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tab Content with animation and swipe
            Expanded(
              child: _showApplyLeaveForm
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut
                    )
                  : PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) => setState(() => _selectedIndex = i),
                      children: navTabs.map((tab) => tab.content).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void showApplyLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: _ApplyLeaveDialogContent(),
          ),
        );
      },
    );
  }

  void showApplyCompOffDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: _ApplyCompOffDialogContent(),
          ),
        );
      },
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final Widget content;
  _NavTab({required this.icon, required this.label, required this.content});
}

class _SwipeableSegmentedTabBar extends StatelessWidget {
  final List<_NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  const _SwipeableSegmentedTabBar({required this.tabs, required this.selectedIndex, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = (constraints.maxWidth - (tabs.length - 1) * 8) / tabs.length;
        final pillWidth = tabWidth + 12; // Make pill a bit wider than tab
        return Stack(
          children: [
            // Sliding pill indicator
            AnimatedAlign(
              alignment: Alignment(-1 + 2 * (selectedIndex / (tabs.length - 1)), 0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Container(
                width: pillWidth,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: List.generate(tabs.length, (i) {
                final selected = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(i),
                    child: Container(
                      height: 44,
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tabs[i].icon,
                            color: selected ? Colors.black : Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tabs[i].label,
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.grey.shade600,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _LeaveBalanceTab extends StatefulWidget {
  final Map<String, int> leaveBalance;
  const _LeaveBalanceTab({required this.leaveBalance});

  @override
  State<_LeaveBalanceTab> createState() => _LeaveBalanceTabState();
}

class _LeaveBalanceTabState extends State<_LeaveBalanceTab> with SingleTickerProviderStateMixin {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    // Delay to trigger animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Example values, replace with your logic if needed
    final double carried = 0;
    final double earned = 1.5;
    final double compOffCarried = 0;
    final double compOffEarned = 1;
    final double taken = -6;
    final double total = carried + earned + compOffCarried + compOffEarned + taken;

    final List<_BalanceRowData> rows = [
      _BalanceRowData('Leave carried from previous year', carried),
      _BalanceRowData('Leaves earned since January', earned),
      _BalanceRowData('Comp-off carried forward', compOffCarried),
      _BalanceRowData('Comp-off earned this month', compOffEarned),
      _BalanceRowData('Leaves taken in this year', taken, negative: taken < 0),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leave Balance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.1),
              ),
              const SizedBox(height: 20),
              // Table-like alignment
              Column(
                children: rows.map((row) => _AnimatedBalanceRow(
                  label: row.label,
                  value: row.value,
                  negative: row.negative,
                  animate: _animate,
                )).toList(),
              ),
              const Divider(height: 32, thickness: 1),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: _animate ? total : 0),
                      duration: const Duration(milliseconds: 900),
                      builder: (context, value, child) => Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: total < 0 ? Colors.red.shade700 : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '* Total = Previous year leaves + Earned leaves + Comp-off (carried & earned) - Taken leaves',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceRowData {
  final String label;
  final double value;
  final bool negative;
  _BalanceRowData(this.label, this.value, {this.negative = false});
}

class _AnimatedBalanceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool negative;
  final bool animate;
  const _AnimatedBalanceRow({required this.label, required this.value, required this.negative, required this.animate});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: animate ? value : 0),
      duration: const Duration(milliseconds: 800),
      builder: (context, val, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Text(label, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(
                width: 18,
                child: Center(child: Text('-', style: TextStyle(fontSize: 15, color: Colors.black54))),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  val > 0 ? val.toStringAsFixed(1) : val.toStringAsFixed(1),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    color: negative ? Colors.red.shade700 : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeavePoliciesTab extends StatelessWidget {
  const _LeavePoliciesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Annual Leave Policy
          _PolicyCard(
            icon: Icons.event_note,
            accentColor: Colors.blue.shade600,
            title: 'Annual Leave Policy',
            points: const [
              'All employees are entitled to 18 days of annual leave per year.',
              'Unused leave can be carried forward to the next year.',
            ],
          ),
          const SizedBox(height: 18),
          // Section: Comp-off Leave Policy
          _PolicyCard(
            icon: Icons.autorenew,
            accentColor: Colors.purple.shade600,
            title: 'Comp-off Leave Policy',
            points: const [
              'When applying for leave, it will first be deducted from available comp-off balance.',
              'If comp-off balance is exhausted, remaining days will be deducted from annual leave.',
              'Unused comp-off can be carried forward to the next month.',
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final List<String> points;
  const _PolicyCard({required this.icon, required this.accentColor, required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
            ],
          ),
          const SizedBox(height: 14),
          ...points.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 7, color: accentColor.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(point, style: const TextStyle(fontSize: 14, color: Colors.black87))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _LeaveHistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> leaveHistory;
  const _LeaveHistoryTab({required this.leaveHistory});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: leaveHistory.isEmpty
          ? Card(
              color: const Color(0xFFFDFEFE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200, width: 1.2),
              ),
              elevation: 0,
              child: const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No leave history found.', style: TextStyle(color: Colors.black54))),
              ),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Leave History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                ...leaveHistory.map((leave) => _LeaveHistoryCard(leave: leave)).toList(),
              ],
            ),
    );
  }
}

class _LeaveHistoryCard extends StatelessWidget {
  final Map<String, dynamic> leave;
  const _LeaveHistoryCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    String date = leave['startDate'] == leave['endDate']
        ? leave['startDate']
        : '${leave['startDate']} - ${leave['endDate']}';
    String type = leave['leaveType'] ?? 'Leave';
    String status = leave['status'] ?? 'Pending';
    String shift = 'Full Day'; // You can update if you have this info
    String reason = leave['reason'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    _TypeBadge(type: type),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 15, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(shift, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(reason, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color = type == 'Comp-Off' ? Colors.purple.shade100 : Colors.blue.shade100;
    Color textColor = type == 'Comp-Off' ? Colors.purple : Colors.blue.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    IconData icon;
    if (status == 'Approved') {
      color = Colors.green.shade100;
      textColor = Colors.green;
      icon = Icons.check_circle;
    } else if (status == 'Rejected') {
      color = Colors.red.shade100;
      textColor = Colors.red;
      icon = Icons.cancel;
    } else {
      color = Colors.yellow.shade100;
      textColor = Colors.orange.shade800;
      icon = Icons.hourglass_empty;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _PublicHolidaysTab extends StatelessWidget {
  const _PublicHolidaysTab();

  @override
  Widget build(BuildContext context) {
    final holidays = [
      {
        'name': 'Holi Puja',
        'desc': 'Festival of colors and joy',
        'date': '10 Mar 2025',
      },
      {
        'name': 'Diwali',
        'desc': 'Festival of lights and prosperity',
        'date': '10 Nov 2025',
      },
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Upcoming Holidays', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...holidays.map((h) => _HolidayCard(
                name: h['name']!,
                desc: h['desc']!,
                date: h['date']!,
              )),
        ],
      ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  final String name;
  final String desc;
  final String date;
  const _HolidayCard({required this.name, required this.desc, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration, color: Colors.orange.shade400, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue.shade400, size: 16),
                  const SizedBox(width: 4),
                  Text(date, style: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}

class _ApplyLeaveDialogContent extends StatefulWidget {
  @override
  State<_ApplyLeaveDialogContent> createState() => _ApplyLeaveDialogContentState();
}

class _ApplyLeaveDialogContentState extends State<_ApplyLeaveDialogContent> {
  String leaveType = 'Full Day';
  DateTime? rangeStart;
  DateTime? rangeEnd;
  TextEditingController reasonController = TextEditingController();
  bool isDropdownOpen = false;
  bool isSelectDaysFocused = false;
  bool showSuccess = false;

  void _showSuccessAndClose() {
    setState(() => showSuccess = true);
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _openCalendarDialog() async {
    DateTime? tempStart = rangeStart;
    DateTime? tempEnd = rangeEnd;
    DateTime _focusedDay = tempStart ?? DateTime.now();
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Info message for range selection
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select the start and end date. All days in between will be selected automatically.',
                                style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Calendar
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        rangeStartDay: tempStart,
                        rangeEndDay: tempEnd,
                        rangeSelectionMode: (tempStart != null && tempEnd != null)
                            ? RangeSelectionMode.toggledOn
                            : (tempStart != null ? RangeSelectionMode.toggledOn : RangeSelectionMode.toggledOff),
                        selectedDayPredicate: (day) => false,
                        onDaySelected: (selectedDay, focusedDay) {
                          setStateDialog(() {
                            if (tempStart == null && tempEnd == null) {
                              tempStart = selectedDay;
                              tempEnd = null;
                            } else if (tempStart != null && tempEnd == null) {
                              if (selectedDay.isBefore(tempStart!)) {
                                tempStart = selectedDay;
                              } else if (selectedDay.isAfter(tempStart!)) {
                                tempEnd = selectedDay;
                              } else {
                                // Clicked same day again, clear selection
                                tempStart = null;
                                tempEnd = null;
                              }
                            } else {
                              // If both are set, start new range
                              tempStart = selectedDay;
                              tempEnd = null;
                            }
                            _focusedDay = focusedDay;
                          });
                        },
                        onRangeSelected: (start, end, focusedDay) {
                          setStateDialog(() {
                            tempStart = start;
                            tempEnd = end;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          isTodayHighlighted: true,
                          rangeHighlightColor: Color(0xFF3B82F6).withOpacity(0.18),
                          rangeStartDecoration: BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Color(0xFF60A5FA),
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        enabledDayPredicate: (day) => day.isAfter(DateTime.now().subtract(Duration(days: 1))) || isSameDay(day, DateTime.now()),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                rangeStart = tempStart;
                                rangeEnd = tempEnd;
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = rangeStart != null && reasonController.text.isNotEmpty;
    String selectedRangeText = '';
    if (rangeStart != null && rangeEnd != null) {
      selectedRangeText = '${rangeStart!.day}/${rangeStart!.month}/${rangeStart!.year} - ${rangeEnd!.day}/${rangeEnd!.month}/${rangeEnd!.year}';
    } else if (rangeStart != null) {
      selectedRangeText = '${rangeStart!.day}/${rangeStart!.month}/${rangeStart!.year}';
    }
    return showSuccess
        ? Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: Center(
              child: Container(
                width: 280,
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 48),
                    SizedBox(height: 18),
                    Text(
                      'Leave request submitted!',
                      style: TextStyle(
                        color: Color(0xFF1558B0),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Apply for Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Simple DropdownButtonFormField (original style)
                  DropdownButtonFormField<String>(
                    value: leaveType,
                    decoration: InputDecoration(
                      labelText: 'Leave Type',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Full Day', child: Text('Full Day')),
                      DropdownMenuItem(value: 'First Half', child: Text('First Half')),
                      DropdownMenuItem(value: 'Second Half', child: Text('Second Half')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        leaveType = val!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  // Select Days with floating label and range
                  FocusScope(
                    child: Focus(
                      onFocusChange: (focus) => setState(() => isSelectDaysFocused = focus),
                      child: GestureDetector(
                        onTap: _openCalendarDialog,
                        child: AbsorbPointer(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Select Days',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
                            ),
                            controller: TextEditingController(
                              text: selectedRangeText,
                            ),
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Reason field with floating label and standard color
                  FocusScope(
                    child: Focus(
                      onFocusChange: (focus) {},
                      child: TextField(
                        controller: reasonController,
                        minLines: 2,
                        maxLines: 4,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          labelStyle: TextStyle(color: Colors.grey.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSubmit ? Colors.blue.shade100 : Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: canSubmit
                            ? _showSuccessAndClose
                            : null,
                        child: Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}

class _ApplyCompOffDialogContent extends StatefulWidget {
  @override
  State<_ApplyCompOffDialogContent> createState() => _ApplyCompOffDialogContentState();
}

class _ApplyCompOffDialogContentState extends State<_ApplyCompOffDialogContent> {
  String compOffType = 'Comp-Off';
  DateTime? selectedDay;
  TextEditingController reasonController = TextEditingController();
  bool showSuccess = false;

  void _showSuccessAndClose() {
    setState(() => showSuccess = true);
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _openCalendarDialog() async {
    DateTime? tempDay = selectedDay;
    DateTime _focusedDay = tempDay ?? DateTime.now();
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        selectedDayPredicate: (day) => tempDay != null && isSameDay(day, tempDay),
                        onDaySelected: (selectedDay, focusedDay) {
                          setStateDialog(() {
                            if (tempDay != null && isSameDay(selectedDay, tempDay)) {
                              tempDay = null;
                            } else {
                              tempDay = selectedDay;
                            }
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          isTodayHighlighted: true,
                          selectedDecoration: BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.teal.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        enabledDayPredicate: (day) => day.isAfter(DateTime.now().subtract(Duration(days: 1))) || isSameDay(day, DateTime.now()),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedDay = tempDay;
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = selectedDay != null && reasonController.text.isNotEmpty;
    String selectedDayText = selectedDay != null
        ? '${selectedDay!.day}/${selectedDay!.month}/${selectedDay!.year}'
        : '';
    return showSuccess
        ? Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: Center(
              child: Container(
                width: 280,
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.teal, size: 48),
                    SizedBox(height: 18),
                    Text(
                      'Comp-off applied successfully',
                      style: TextStyle(
                        color: Colors.teal.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Apply for Comp-off', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Comp-Off type as read-only field (no dropdown, no arrow)
                  TextFormField(
                    readOnly: true,
                    initialValue: 'Comp-Off',
                    decoration: InputDecoration(
                      labelText: 'Type',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  // Select Day with floating label
                  FocusScope(
                    child: Focus(
                      onFocusChange: (focus) {},
                      child: GestureDetector(
                        onTap: _openCalendarDialog,
                        child: AbsorbPointer(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Select Day',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              suffixIcon: Icon(Icons.calendar_today, color: Colors.teal),
                            ),
                            controller: TextEditingController(
                              text: selectedDayText,
                            ),
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Reason field with floating label and standard color
                  FocusScope(
                    child: Focus(
                      onFocusChange: (focus) {},
                      child: TextField(
                        controller: reasonController,
                        minLines: 2,
                        maxLines: 4,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          labelStyle: TextStyle(color: Colors.grey.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.teal,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSubmit ? Colors.blue.shade100 : Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: canSubmit
                            ? _showSuccessAndClose
                            : null,
                        child: Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}