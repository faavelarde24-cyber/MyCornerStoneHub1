// lib/pages/dashboard/student_dashboard.dart
// Save this file as: lib/pages/dashboard/student_dashboard.dart

import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  AnimationController? animationController;
  bool multiple = true;

  final List<DashboardItem> studentItems = [
    DashboardItem(
      title: 'My Courses',
      icon: Icons.menu_book_outlined,
      color: Colors.blue,
    ),
    DashboardItem(
      title: 'Assignments',
      icon: Icons.assignment_outlined,
      color: Colors.orange,
    ),
    DashboardItem(
      title: 'Grades',
      icon: Icons.assessment_outlined,
      color: Colors.green,
    ),
    DashboardItem(
      title: 'Schedule',
      icon: Icons.calendar_today_outlined,
      color: Colors.purple,
    ),
    DashboardItem(
      title: 'Resources',
      icon: Icons.library_books_outlined,
      color: Colors.teal,
    ),
    DashboardItem(
      title: 'Messages',
      icon: Icons.message_outlined,
      color: Colors.pink,
    ),
  ];

  @override
  void initState() {
    animationController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    super.initState();
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 0));
    return true;
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error logging out')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isLightMode = brightness == Brightness.light;
    
    return Scaffold(
      backgroundColor: isLightMode ? AppTheme.white : AppTheme.nearlyBlack,
      body: FutureBuilder<bool>(
        future: getData(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          } else {
            return Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildAppBar(isLightMode),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 0, left: 12, right: 12),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: multiple ? 2 : 1,
                        mainAxisSpacing: 12.0,
                        crossAxisSpacing: 12.0,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: studentItems.length,
                      itemBuilder: (context, index) {
                        final int count = studentItems.length;
                        final Animation<double> animation =
                            Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animationController!,
                            curve: Interval((1 / count) * index, 1.0,
                                curve: Curves.fastOutSlowIn),
                          ),
                        );
                        animationController?.forward();
                        
                        return DashboardCard(
                          animation: animation,
                          animationController: animationController,
                          item: studentItems[index],
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening ${studentItems[index].title}')),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAppBar(bool isLightMode) {
    return SizedBox(
      height: AppBar().preferredSize.height + 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _authService.currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLightMode ? AppTheme.grey : AppTheme.white.withValues(alpha:0.7),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: AppBar().preferredSize.height - 8,
                  height: AppBar().preferredSize.height - 8,
                  decoration: BoxDecoration(
                    color: isLightMode ? Colors.white : AppTheme.nearlyBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        multiple ? Icons.dashboard : Icons.view_agenda,
                        color: isLightMode ? AppTheme.dark_grey : AppTheme.white,
                      ),
                      onTap: () {
                        setState(() {
                          multiple = !multiple;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: isLightMode ? AppTheme.dark_grey : AppTheme.white,
                  ),
                  onPressed: _handleLogout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Dashboard Item Model - Shared between all dashboards
class DashboardItem {
  final String title;
  final IconData icon;
  final Color color;

  DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}

// Dashboard Card Widget - Shared between all dashboards
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.item,
    required this.onTap,
    this.animationController,
    this.animation,
  });

  final DashboardItem item;
  final VoidCallback onTap;
  final AnimationController? animationController;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 50 * (1.0 - animation!.value), 0.0),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      item.color.withValues(alpha:0.8),
                      item.color.withValues(alpha:0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}