// lib/pages/book_creator/widgets/onboarding_guide.dart
import 'package:flutter/material.dart';
import 'editor_toolbar.dart'; // ✅ Import to access keys
import '../book_creator_page.dart';

/// Phase 1: Welcome Screen + Phase 2: Interactive Element Tour
class OnboardingGuide extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const OnboardingGuide({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<OnboardingGuide> createState() => _OnboardingGuideState();
}

class _OnboardingGuideState extends State<OnboardingGuide>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

final Map<int, GlobalKey> _stepKeys = {
  1: EditorToolbar.textButtonKey,
  2: EditorToolbar.imageButtonKey,
  3: EditorToolbar.shapeButtonKey,
  4: EditorToolbar.audioButtonKey,
  5: EditorToolbar.videoButtonKey,
  6: EditorToolbar.undoButtonKey,
  7: EditorToolbar.deleteButtonKey,
  8: EditorToolbar.gridButtonKey,
  9: EditorToolbar.backgroundButtonKey,
  10: EditorToolbar.helpButtonKey,     
  11: EditorToolbar.pageNavigationKey,    
  12: BookCreatorAppBarKeys.saveButtonKey,    
  13: BookCreatorAppBarKeys.previewButtonKey,  
  14: BookCreatorAppBarKeys.settingsButtonKey, 
};

final List<ElementTourStep> _tourSteps = [
  // TOOLBAR ELEMENTS
  ElementTourStep(
    key: 'text_button',
    title: 'Text Element',
    description:
        'Add and format text content for your book. Create titles, paragraphs, and lists.',
    icon: Icons.text_fields,
  ),
  ElementTourStep(
    key: 'image_button',
    title: 'Image Element',
    description:
        'Insert and position images. Upload from your device or search our online library.',
    icon: Icons.image,
  ),
  ElementTourStep(
    key: 'shape_button',
    title: 'Shape Element',
    description:
        'Add geometric shapes to your pages. Create rectangles, circles, and custom shapes.',
    icon: Icons.crop_square,
  ),
  ElementTourStep(
    key: 'audio_button',
    title: 'Audio Element',
    description:
        'Embed audio files for multimedia content. Add narration, music, or sound effects.',
    icon: Icons.audiotrack,
  ),
  ElementTourStep(
    key: 'video_button',
    title: 'Video Element',
    description:
        'Add video content to enhance your pages. Upload videos up to 50MB.',
    icon: Icons.videocam,
  ),
  ElementTourStep(
    key: 'undo_button',
    title: 'Undo & Redo',
    description:
        'Made a mistake? Use Undo to revert changes or Redo to restore them.',
    icon: Icons.undo,
  ),
  ElementTourStep(
    key: 'delete_button',
    title: 'Delete Element',
    description:
        'Remove selected elements from your page. Select an element first, then click delete.',
    icon: Icons.delete,
  ),
  ElementTourStep(
    key: 'grid_button',
    title: 'Grid View',
    description:
        'Toggle grid lines to help align elements perfectly on your page.',
    icon: Icons.grid_on,
  ),
  ElementTourStep(
    key: 'background_button',
    title: 'Background Customization',
    description:
        'Customize page backgrounds and themes. Set colors or upload background images.',
    icon: Icons.palette,
  ),
  
  // ✅ NEW: Add help step here
  ElementTourStep(
    key: 'help_button',
    title: 'Get Help Anytime',
    description:
        'Need guidance? Click here to reopen the Page Content Wizard and get step-by-step help with creating your book.',
    icon: Icons.help_outline,
  ),
  
  ElementTourStep(
    key: 'page_navigation',
    title: 'Page Navigation',
    description:
        'Navigate between pages using these controls. See your current page number and total pages.',
    icon: Icons.menu_book,
  ),
  
  // APP BAR ELEMENTS
  ElementTourStep(
    key: 'save_button',
    title: 'Save Your Work',
    description:
        'Click here to manually save your book. Your work is also auto-saved every 30 seconds.',
    icon: Icons.save,
  ),
  ElementTourStep(
    key: 'preview_button',
    title: 'Preview Book',
    description:
        'Preview how your book will look when published. Test all interactive elements.',
    icon: Icons.preview,
  ),
  ElementTourStep(
    key: 'settings_button',
    title: 'Book Settings',
    description:
        'Access book settings, export options, and grid configuration from this menu.',
    icon: Icons.settings,
  ),
];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _tourSteps.length) {
      setState(() {
        _currentStep++;
      });
      _fadeController.forward(from: 0);
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _fadeController.forward(from: 0);
    }
  }

  void _skip() {
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return _buildWelcomeScreen();
    } else {
      return _buildElementTour();
    }
  }

  Widget _buildWelcomeScreen() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: _skip,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Text(
                          '🎉',
                          style: TextStyle(fontSize: 64),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to MyCornerstone Hub',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thank you for using our app!\nLet me guide you step by step through\ncreating your first book.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'Skip Tutorial',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start Guide',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElementTour() {
    final step = _tourSteps[_currentStep - 1];
    final stepNumber = _currentStep;
    final totalSteps = _tourSteps.length;

    // ✅ NEW: Get the position of the highlighted button
    final targetKey = _stepKeys[stepNumber];
    Rect? targetRect;
    
    if (targetKey?.currentContext != null) {
      final RenderBox renderBox = targetKey!.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      targetRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    }

    return Stack(
      children: [
        // ✅ CUSTOM PAINT: Dark overlay with cutout spotlight
        CustomPaint(
          painter: SpotlightPainter(
            spotlightRect: targetRect,
            pulseAnimation: _pulseAnimation,
          ),
          child: const SizedBox.expand(),
        ),

        // ✅ ANIMATED ARROW pointing to the button
        if (targetRect != null) _buildPointingArrow(targetRect),

        // Info box positioned intelligently
        _buildInfoBox(step, stepNumber, totalSteps, targetRect),
      ],
    );
  }

Widget _buildPointingArrow(Rect targetRect) {
  return Positioned(
    left: targetRect.center.dx - 16, // Center the arrow
    top: targetRect.bottom + 8, // Position below button
    child: ScaleTransition(
      scale: _pulseAnimation,
      child: Column(
        children: [
          // ✅ Downward arrow pointing TO the info box
          const Icon(
            Icons.arrow_downward,
            color: Color(0xFF3B82F6),
            size: 32,
          ),
          const SizedBox(height: 4),
          // ✅ Optional: Add a small label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Look here!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildInfoBox(ElementTourStep step, int stepNumber, int totalSteps, Rect? targetRect) {
    // Position the info box below the toolbar if we have a target
    double? top;
    if (targetRect != null) {
      top = targetRect.bottom + 120; // Position below the arrow
    }

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step $stepNumber of $totalSteps',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _skip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step.icon,
                      size: 40,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                LinearProgressIndicator(
                  value: stepNumber / totalSteps,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF3B82F6),
                  ),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (stepNumber > 1)
                      TextButton.icon(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    TextButton(
                      onPressed: _skip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stepNumber == totalSteps ? 'Finish' : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ NEW: Custom painter for spotlight effect
class SpotlightPainter extends CustomPainter {
  final Rect? spotlightRect;
  final Animation<double> pulseAnimation;

  SpotlightPainter({
    required this.spotlightRect,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

@override
void paint(Canvas canvas, Size size) {
  // Save the canvas state
  canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

  // ✅ Draw the dark overlay
  final darkOverlay = Paint()..color = Colors.black.withValues(alpha: 0.5);
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkOverlay);

  if (spotlightRect != null) {
    // ✅ Expand rect for padding
    final expandedRect = Rect.fromLTRB(
      spotlightRect!.left - 12,
      spotlightRect!.top - 12,
      spotlightRect!.right + 12,
      spotlightRect!.bottom + 12,
    );

    final rrect = RRect.fromRectAndRadius(
      expandedRect,
      const Radius.circular(12),
    );

    // ✅ CUT OUT the spotlight area using clear blend mode
    final cutoutPaint = Paint()
      ..blendMode = BlendMode.clear;
    
    canvas.drawRRect(rrect, cutoutPaint);
  }

  // Restore canvas
  canvas.restore();

  // ✅ NOW draw the glow and border AFTER restoring (so they appear on top)
  if (spotlightRect != null) {
    final expandedRect = Rect.fromLTRB(
      spotlightRect!.left - 12,
      spotlightRect!.top - 12,
      spotlightRect!.right + 12,
      spotlightRect!.bottom + 12,
    );

    final rrect = RRect.fromRectAndRadius(
      expandedRect,
      const Radius.circular(12),
    );

    // ✅ Draw animated glow
    final glowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15 * pulseAnimation.value
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * pulseAnimation.value);

    // ✅ Draw solid border
    final borderPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);
  }
}

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect;
  }
}

class ElementTourStep {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  ElementTourStep({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}