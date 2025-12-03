import 'package:flutter/material.dart';
import 'package:student_management_system/screens/admin/manage_teachers.dart';
import 'package:student_management_system/screens/admin/manage_students.dart';
import 'package:student_management_system/screens/admin/manage_parents.dart';
import 'package:student_management_system/screens/admin/manage_timetable.dart';
import 'package:student_management_system/screens/admin/send_notification.dart';

import 'package:student_management_system/screens/common/profile_screen.dart';
import 'package:student_management_system/widgets/drawer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const ManageTeachersScreen(),
    const ManageStudentsScreen(),
    const ManageParentsScreen(),
    const ManageTimetableScreen(),
  ];

  final List<String> _titles = [
    'Admin Dashboard',
    'Manage Teachers',
    'Manage Students',
    'Manage Parents',
    'Manage Timetable',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SendNotificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(role: 'admin'),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Teachers',
          ),
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom),
            label: 'Parents',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule),
            label: 'Timetable',
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Admin!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const Text('Here\'s your overview'),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _StatCard(
                title: 'Total Students',
                value: '450',
                icon: Icons.school,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Total Teachers',
                value: '35',
                icon: Icons.people,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Total Parents',
                value: '420',
                icon: Icons.family_restroom,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Classes',
                value: '15',
                icon: Icons.class_,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activities',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text('New student registered'),
                            subtitle: Text('2 hours ago'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}