import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'pages/owner/approvals/warehouse_inventory_page.dart';

import 'routes.dart';
import 'auth/splash_decider.dart';
import 'auth/auth_page.dart';
import 'pages/sales/sales_dashboard_page.dart';
import 'pages/engineer/tools/engineer_tools_page.dart';

import 'pages/common/profile_page.dart';
import 'pages/common/settings/settings_page.dart';
import 'pages/common/settings/general_settings.dart';
import 'pages/common/settings/chats_settings.dart';
import 'pages/common/settings/notifications_settings.dart';
import 'pages/common/settings/accessibility_settings.dart';
import 'pages/common/settings/calls_settings.dart';
import 'pages/common/settings/about_page.dart';
import 'pages/common/settings/help_support.dart';
import 'pages/common/settings/terms_page.dart';

import 'pages/common/settings/support/faq_page.dart';
import 'pages/common/settings/support/support_chat_page.dart';
import 'pages/common/settings/support/raise_ticket_page.dart';
import 'pages/common/settings/support/track_ticket_page.dart';
import 'pages/common/settings/support/tutorials_page.dart';
import 'pages/common/settings/support/report_problem_page.dart';
import 'pages/common/settings/support/feedback_page.dart';

import 'pages/common/settings/app_settings_store.dart';

import 'nav/owner_nav.dart';
import 'nav/engineer_nav.dart';
import 'nav/client_nav.dart';

import 'pages/client/siteview/client_map_view.dart';
import 'pages/client/siteview/client_2d_view.dart';
import 'pages/client/siteview/client_3d_view.dart';

import 'pages/owner/docs/owner_proposal.dart';
import 'pages/owner/docs/owner_gst_invoice.dart';
import 'pages/owner/docs/owner_quotation.dart';
import 'pages/owner/docs/owner_purchase_order.dart';
import 'pages/owner/docs/owner_cc_page.dart';
import 'pages/owner/docs/owner_iod_page.dart';
import 'pages/owner/docs/owner_rera_page.dart';


import 'pages/client/docs/client_rera_page.dart';
import 'pages/client/docs/client_iod_page.dart';
import 'pages/client/docs/client_proposal_page.dart';
import 'pages/client/docs/client_quotation_page.dart';
import 'pages/client/docs/client_gst_invoices_page.dart';
import 'pages/client/docs/client_cc_page.dart';

import 'pages/common/assistant/assistant_chat_page.dart';
import 'pages/sales/sales_page.dart';
import 'core/locale/locale_instance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsStore.load();

  // 🔥 Load saved language
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString("lang") ?? "en";
  localeController.setLocale(lang);

  runApp(const SiteSaarthiApp());
}

class SiteSaarthiApp extends StatelessWidget {
  const SiteSaarthiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettingsStore.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettingsStore.fontScale,
          builder: (context, scale, __) {
            return AnimatedBuilder(
              animation: localeController,
              builder: (context, _) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,

                  // 🌍 LANGUAGE
                  locale: localeController.locale,
                  supportedLocales: const [
                    Locale('en'),
                    Locale('hi'),
                    Locale('mr'),
                  ],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],

                  // 🎨 THEME
                  themeMode: mode,
                  theme: ThemeData(
                    brightness: Brightness.light,
                    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
                    appBarTheme: const AppBarTheme(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
                      titleTextStyle: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  darkTheme: ThemeData(
                    brightness: Brightness.dark,
                    scaffoldBackgroundColor: const Color(0xFF0B1220),
                    appBarTheme: const AppBarTheme(
                      elevation: 0,
                      backgroundColor: Color(0xFF0F172A),
                      surfaceTintColor: Color(0xFF0F172A),
                      iconTheme: IconThemeData(color: Colors.white),
                      titleTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  // 🔠 FONT SCALE
                  builder: (context, child) {
                    final mq = MediaQuery.of(context);
                    return MediaQuery(
                      data: mq.copyWith(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: child!,
                    );
                  },

                  // 🚦 ROUTES
                  initialRoute: AppRoutes.splash,
                  routes: {
                    AppRoutes.splash: (_) => const SplashDecider(),
                    AppRoutes.auth: (_) => const AuthPage(),

                    AppRoutes.ownerHome: (_) => const OwnerNav(initialIndex: 0),
                    AppRoutes.engineerHome: (_) =>
                        const EngineerNav(initialIndex: 0),

                    AppRoutes.profile: (_) => const ProfilePage(),
                    AppRoutes.settings: (_) => const SettingsPage(),
                    AppRoutes.settingsGeneral: (_) =>
                        const GeneralSettingsPage(),
                    AppRoutes.settingsChats: (_) => const ChatsSettingsPage(),
                    AppRoutes.settingsNotifications: (_) =>
                        const NotificationsSettingsPage(),
                    AppRoutes.settingsAccessibility: (_) =>
                        const AccessibilitySettingsPage(),
                    AppRoutes.settingsCalls: (_) => const CallsSettingsPage(),
                    AppRoutes.settingsAbout: (_) => const AboutPage(),
                    AppRoutes.settingsHelp: (_) => const HelpSupportPage(),
                    AppRoutes.terms: (_) => const TermsPage(),

                    AppRoutes.supportFaq: (_) => const FaqPage(),
                    AppRoutes.supportChat: (_) => const SupportChatPage(),
                    AppRoutes.supportRaiseTicket: (_) =>
                        const RaiseTicketPage(),
                    AppRoutes.supportTrackTicket: (_) =>
                        const TrackTicketPage(),
                    AppRoutes.supportTutorials: (_) => const TutorialsPage(),
                    AppRoutes.supportReportProblem: (_) =>
                        const ReportProblemPage(),
                    AppRoutes.supportFeedback: (_) => const FeedbackPage(),

                    AppRoutes.clientMapView: (_) => const ClientMapViewPage(),
                    AppRoutes.client2DView: (_) => const Client2DViewPage(),
                    AppRoutes.client3DView: (_) => const Client3DViewPage(),

                    AppRoutes.ownerDocsProposal: (_) => const ProposalPage(),
                    AppRoutes.ownerDocsQuotation: (_) => const QuotationPage(),
                    AppRoutes.ownerDocsPurchaseOrder: (_) =>
    const OwnerPoApprovalsPage(),

                    AppRoutes.ownerDocsGstInvoice: (_) =>
                        const GstInvoicePage(),

                    AppRoutes.ownerDocsRera: (_) => const OwnerReraUploadPage(),
                    AppRoutes.ownerDocsIod: (_) => const OwnerIodUploadPage(),
                    AppRoutes.ownerDocsCc: (_) => const OwnerCcUploadPage(),

                    AppRoutes.clientDocsRera: (_) => const ClientReraPage(),
                    AppRoutes.clientDocsIod: (_) => const ClientIodPage(),
                    AppRoutes.clientDocsCc: (_) => ClientCcPage(),
                    AppRoutes.clientDocsProposal: (_) =>
                        const ClientProposalPage(),
                    AppRoutes.clientDocsQuotation: (_) =>
                        const ClientQuotationPage(),
                    AppRoutes.clientDocsGstInvoice: (_) =>
                        const ClientGstInvoicesPage(),

                    AppRoutes.assistantChat: (_) => const AssistantChatPage(),

                    // ✅ Client root routes (EXPLICIT)
                    AppRoutes.clientHome: (_) =>
                        const ClientNav(initialIndex: 0),
                    AppRoutes.clientSiteView: (_) =>
                        const ClientNav(initialIndex: 0),
                    AppRoutes.salesDashboard: (_) => const SalesDashboardPage(),
                    AppRoutes.salesPage: (_) => const SalesPage(),


                    AppRoutes.engineerTools: (_) => const EngineerToolsPage(),
                    AppRoutes.warehouseInventory: (_) =>
    const WarehouseInventoryPage(),

                    

                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
