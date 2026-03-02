import 'package:flutter/material.dart';
import '../presentation/profile_settings_screen/profile_settings_screen.dart';
import '../presentation/chat_screen/chat_screen.dart';
import '../presentation/legal_disclaimer_modal/legal_disclaimer_modal.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/documents_library_screen/documents_library_screen.dart';
import '../presentation/source_viewer_screen/source_viewer_screen.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/chat_list_screen/chat_list_screen.dart';
import '../presentation/draft_preview_approval_screen/draft_preview_approval_screen.dart';
import '../presentation/draft_type_selection_screen/draft_type_selection_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String profileSettings = '/profile-settings-screen';
  static const String chat = '/chat-screen';
  static const String legalDisclaimerModal = '/legal-disclaimer-modal';
  static const String splash = '/splash-screen';
  static const String documentsLibrary = '/documents-library-screen';
  static const String sourceViewer = '/source-viewer-screen';
  static const String homeDashboard = '/home-dashboard';
  static const String authentication = '/authentication-screen';
  static const String chatList = '/chat-list-screen';
  static const String draftPreviewApproval = '/draft-preview-approval-screen';
  static const String draftTypeSelection = '/draft-type-selection-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    profileSettings: (context) => const ProfileSettingsScreen(),
    chat: (context) => const ChatScreen(),
    legalDisclaimerModal: (context) => const LegalDisclaimerModal(),
    splash: (context) => const SplashScreen(),
    documentsLibrary: (context) => const DocumentsLibraryScreen(),
    sourceViewer: (context) => const SourceViewerScreen(),
    homeDashboard: (context) => const HomeDashboard(),
    authentication: (context) => const AuthenticationScreen(),
    chatList: (context) => const ChatListScreen(),
    draftPreviewApproval: (context) => const DraftPreviewApprovalScreen(),
    draftTypeSelection: (context) => const DraftTypeSelectionScreen(),
  };
}
