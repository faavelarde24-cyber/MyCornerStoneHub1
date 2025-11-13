import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_page.dart';
import '../../services/auth_service.dart';
import '../../utils/role_redirect.dart';

// ===== START DASHBOARD QUICK ACCESS =====
// Import your dashboards here
import '../dashboard/principal_dashboard.dart';
import '../dashboard/teacher_dashboard.dart';
import '../dashboard/student_dashboard.dart';
// ===== END DASHBOARD QUICK ACCESS =====

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _obscurePassword = true;
  bool _isHoveringEmail = false;
  bool _isHoveringPassword = false;
  bool _isLoading = false;

  // ===== START DASHBOARD QUICK ACCESS =====
  bool _showDashboardMenu = false;
  
  void _navigateToDashboard(String dashboardType) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          switch (dashboardType) {
            case 'principal':
              return const PrincipalDashboard();
            case 'teacher':
              return const ModernTeacherDashboard();
            case 'student':
              return const StudentDashboard();
            default:
              return const LoginPage();
          }
        },
      ),
    );
  }
  // ===== END DASHBOARD QUICK ACCESS =====

 Future<void> _handleLogin() async {
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    _showSnackBar('Please fill in all fields');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final result = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (result.success && result.role != null) {
      _showSnackBar('Login successful! Redirecting...');
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      // Navigate with fresh ProviderScope to force provider refresh
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return ProviderScope(
              child: RoleRedirect.getDashboardForRole(result.role),
            );
          },
        ),
      );
    } else {
      _showSnackBar(result.error ?? 'Login failed');
      
      // Show option to resend confirmation email if needed
      if (result.needsEmailConfirmation) {
        _showResendConfirmationDialog();
      }
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('An error occurred. Please try again.');
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _showResendConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Not Confirmed'),
        content: const Text(
          'Your email address has not been confirmed yet. Would you like us to resend the confirmation email?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _authService.resendConfirmationEmail(
                _emailController.text.trim(),
              );
              if (mounted) {
                _showSnackBar(
                  success
                      ? 'Confirmation email sent! Please check your inbox.'
                      : 'Failed to send confirmation email. Please try again.',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/page.png'),
                fit: BoxFit.fill,
                alignment: Alignment.center,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ===== START DASHBOARD QUICK ACCESS =====
                        // Clickable Logo with dropdown indicator
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showDashboardMenu = !_showDashboardMenu;
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha:0.0),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha:0.0),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/cornerstone_logo.jpeg',
                                    width: 210,
                                    height: 210,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.business_center,
                                        size: 48,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Dropdown indicator badge
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _showDashboardMenu ? Icons.close : Icons.apps,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Dropdown menu
                        if (_showDashboardMenu)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildDashboardMenuItem(
                                  icon: Icons.school,
                                  title: 'Principal Dashboard',
                                  color: Colors.blueAccent,
                                  onTap: () => _navigateToDashboard('principal'),
                                ),
                                Divider(height: 1, color: Colors.grey.shade300),
                                _buildDashboardMenuItem(
                                  icon: Icons.menu_book,
                                  title: 'Teacher Dashboard',
                                  color: Colors.orangeAccent,
                                  onTap: () => _navigateToDashboard('teacher'),
                                ),
                                Divider(height: 1, color: Colors.grey.shade300),
                                _buildDashboardMenuItem(
                                  icon: Icons.people,
                                  title: 'Student Dashboard',
                                  color: Colors.green,
                                  onTap: () => _navigateToDashboard('student'),
                                ),
                              ],
                            ),
                          ),
                        // ===== END DASHBOARD QUICK ACCESS =====
                        
                        const SizedBox(height: 24),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            children: const [
                              TextSpan(
                                text: 'CORNER',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'STONE',
                                style: TextStyle(color: Colors.orange),
                              ),
                              TextSpan(
                                text: ' HUB',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Email Field
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isHoveringEmail
                                ? [
                                    BoxShadow(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _isHoveringEmail = true),
                            onExit: (_) => setState(() => _isHoveringEmail = false),
                            child: TextField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(color: const Color.fromARGB(255, 118, 110, 110)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.orange),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 20,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isHoveringPassword
                                ? [
                                    BoxShadow(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _isHoveringPassword = true),
                            onExit: (_) => setState(() => _isHoveringPassword = false),
                            child: TextField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: const Color.fromARGB(255, 118, 110, 110)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: _isLoading ? null : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : () {},
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.orange.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Login',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.3),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.3),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            )
          );
        },
      ),
    );
  }

  // ===== START DASHBOARD QUICK ACCESS =====
  Widget _buildDashboardMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
  // ===== END DASHBOARD QUICK ACCESS =====
}