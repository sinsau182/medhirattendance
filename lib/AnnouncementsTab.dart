import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AnnouncementsTab extends StatefulWidget {
  const AnnouncementsTab({super.key});

  @override
  _AnnouncementsTabState createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  Map<String, bool> expandedStates = {}; // Tracks expanded state for each item

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        _buildAnnouncementCard(
          backgroudColor: Colors.teal.shade50,
          title: 'Quarterly Results Announcement',
          date: '20 Jun 2023',
          description:
          'We’re pleased to announce that our company has exceeded its quarterly targets by 15%. Thank you all for your hard work and dedication.',
          isNew: true,
          icon: LucideIcons.bell,
          iconColor: Colors.teal,
        ),
        const SizedBox(height: 12),
        _buildAnnouncementCard(
          backgroudColor: Colors.grey.shade400,
          title: 'Office Wi-Fi Maintenance',
          date: '18 Jun 2023',
          isNew: true,
          icon: LucideIcons.wifi,
          iconColor: Colors.black,
        ),
        const SizedBox(height: 12),
        _buildAnnouncementCard(
          backgroudColor: Colors.blue.shade100,
          title: 'Annual Team Outing',
          date: '15 Jun 2023',
          icon: LucideIcons.calendar,
          iconColor: Colors.blue.shade600,
        ),
        const SizedBox(height: 12),
        _buildAnnouncementCard(
          backgroudColor: Colors.red.shade100,
          title: 'New Health Insurance Policy',
          date: '10 Jun 2023',
          icon: LucideIcons.heart,
          iconColor: Colors.red,
        ),
        const SizedBox(height: 12),
        _buildAnnouncementCard(
          backgroudColor: Colors.amber.shade100,
          title: 'Employee Satisfaction Survey',
          date: '5 Jun 2023',
          icon: LucideIcons.messageSquare,
          iconColor: Colors.amber.shade800,
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard({
    required String title,
    required String date,
    String? description,
    bool isNew = false,
    required IconData icon, required Color iconColor, Color? backgroudColor
  }) {
    bool isExpanded = expandedStates[title] ?? false;

    return Card(
      color: Color(0xFFF9FBFB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: .5,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expandedStates[title] = !isExpanded; // Toggle expansion state
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: backgroudColor,
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'New',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more, size: 24, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
