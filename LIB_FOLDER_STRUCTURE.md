# CornerStone Hub - Lib Folder Structure

## Complete Directory Structure

```
lib/
├── app_theme.dart                          # Theme configuration
├── home_page.dart                          # Home page widget
├── main.dart                               # Application entry point
│
├── models/                                 # Data models
│   ├── app_theme_mode.dart                # Theme mode enums
│   ├── book_models.dart                   # Book-related models
│   ├── book_search_models.dart            # Book search models
│   ├── book_size_type.dart                # Book size types
│   ├── feedback_model.dart                # Feedback model
│   ├── image_search_service.dart          # Image search models
│   ├── library_models.dart                # Library-related models
│   ├── organization_model.dart            # Organization model
│   ├── search_image.dart                  # Search image model
│   ├── user_group_model.dart              # User group model
│   └── user_model.dart                    # User model
│
├── pages/                                  # UI Pages
│   ├── about_us_page.dart                 # About us page
│   ├── feedback_page.dart                 # Feedback page
│   ├── introduction_animation_screen.dart # Intro animation
│   │
│   ├── auth/                              # Authentication pages
│   │   ├── auth_wrapper.dart              # Auth wrapper
│   │   ├── login_page.dart                # Login page
│   │   └── signup_page.dart               # Signup page
│   │
│   ├── book/                              # Book-related pages
│   │   └── widgets/
│   │       └── books_list_dialog.dart     # Books list dialog
│   │
│   ├── book_creator/                      # Book creator module
│   │   ├── book_creator_page.dart         # Main creator page
│   │   ├── choose_book_size_page.dart     # Book size selection
│   │   └── widgets/
│   │       ├── advanced_text_editor.dart  # Text editing widget
│   │       ├── audio_player_widget.dart   # Audio player
│   │       ├── background_settings_dialog.dart  # Background settings
│   │       ├── book_size_card.dart        # Size card widget
│   │       ├── canvas_element.dart        # Canvas element
│   │       ├── editor_toolbar.dart        # Editor toolbar
│   │       ├── image_search_dialog.dart   # Image search dialog
│   │       ├── layer_management_panel.dart # Layer management
│   │       ├── onboarding_guide.dart      # Onboarding guide
│   │       ├── pages_panel.dart           # Pages panel
│   │       ├── properties_panel.dart      # Properties panel
│   │       ├── shape_picker_dialog.dart   # Shape picker
│   │       └── video_player_widget.dart   # Video player
│   │
│   ├── book_view/                         # Book viewing module
│   │   ├── book_view_page.dart            # Main view page
│   │   └── widgets/
│   │       ├── book_view_controls.dart    # View controls
│   │       ├── page_content_widget.dart   # Page content display
│   │       └── page_spread_widget.dart    # Page spread display
│   │
│   ├── dashboard/                         # Dashboard module
│   │   ├── book_dashboard_page.dart       # Book dashboard
│   │   ├── principal_dashboard.dart       # Principal view
│   │   ├── student_dashboard.dart         # Student view
│   │   ├── teacher_dashboard.dart         # Teacher view
│   │   └── widgets/
│   │       ├── book_3d_widget.dart        # 3D book widget
│   │       ├── book_actions_dialog.dart   # Book actions
│   │       ├── book_info_panel.dart       # Book info display
│   │       ├── combine_books_page.dart    # Combine books feature
│   │       ├── dashboard_app_bar.dart     # Dashboard app bar
│   │       ├── dashboard_drawer.dart      # Dashboard drawer
│   │       └── share_options_dialog.dart  # Share options dialog
│   │
│   └── library/                           # Library module
│       └── widgets/
│           ├── create_library_dialog.dart # Create library dialog
│           ├── join_library_dialog.dart   # Join library dialog
│           ├── libraries_list_dialog.dart # Libraries list
│           └── library_details_page.dart  # Library details
│
├── providers/                              # State management (Riverpod)
│   ├── auth_providers.dart                # Auth state providers
│   ├── book_providers.dart                # Book state providers
│   ├── book_search_providers.dart         # Search state providers
│   └── library_providers.dart             # Library state providers
│
├── services/                               # Business logic & services
│   ├── auth_service.dart                  # Authentication service
│   ├── book_export_service.dart           # Book export functionality
│   ├── book_page_service.dart             # Book page management
│   ├── book_search_service.dart           # Book search service
│   ├── book_service.dart                  # Book operations
│   ├── image_search_service.dart          # Image search service
│   ├── language_service.dart              # Language/localization service
│   ├── library_service.dart               # Library operations
│   ├── platform_file_saver.dart           # Platform file saver interface
│   ├── platform_file_saver_io.dart        # IO implementation
│   ├── platform_file_saver_stub.dart      # Stub implementation
│   ├── platform_file_saver_web.dart       # Web implementation
│   ├── storage_service.dart               # Storage management
│   ├── supabase_service.dart              # Supabase backend integration
│   └── undo_redo_manager.dart             # Undo/redo functionality
│
├── utils/                                  # Utility functions
│   ├── id_helpers.dart                    # ID generation helpers
│   ├── image_cache_manager.dart           # Image caching
│   └── role_redirect.dart                 # Role-based redirection
│
└── widgets/                                # Reusable widgets
    ├── app_drawer.dart                    # App navigation drawer
    ├── book_preview_3d.dart               # 3D book preview
    ├── image_search_service.dart          # Image search widget
    └── page_thumbnail_widget.dart         # Page thumbnail display
```

## Key Directories Overview

### 📁 **models/** - Data Models
Contains all data class definitions and model classes used throughout the application.

### 📁 **pages/** - UI Pages
Organized by feature modules:
- **auth/** - Authentication (login, signup)
- **book/** - Book listing and management
- **book_creator/** - Book creation and editing tools
- **book_view/** - Book viewing and reading experience
- **dashboard/** - User dashboards (role-based)
- **library/** - Library management

### 📁 **providers/** - State Management
Riverpod-based state management providers for:
- Authentication state
- Book data
- Search functionality
- Library management

### 📁 **services/** - Business Logic
Core application services handling:
- Backend integration (Supabase)
- File operations and exports
- Search functionality
- Authentication
- Storage management

### 📁 **utils/** - Helper Functions
Utility functions for common tasks like ID generation, image caching, and role-based navigation.

### 📁 **widgets/** - Reusable Components
Shared UI components used across multiple pages.

---

## File Count Summary

- **Total Dart Files**: 80+
- **Models**: 11
- **Pages**: 25+ (including subpages)
- **Services**: 15
- **Providers**: 4
- **Widgets**: 4
- **Utils**: 3

## Architecture Pattern
This project follows a **layered architecture**:
1. **Models** - Data definitions
2. **Services** - Business logic
3. **Providers** - State management
4. **Pages** - UI/Presentation layer
5. **Widgets** - Reusable UI components
6. **Utils** - Helper functions
