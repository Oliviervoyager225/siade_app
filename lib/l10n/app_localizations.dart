import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue à SIADE'**
  String get welcomeTitle;

  /// No description provided for @innovationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Innovation Technologique'**
  String get innovationTitle;

  /// No description provided for @innovationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Explorez les dernières avancées'**
  String get innovationSubtitle;

  /// No description provided for @networkingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Networking & Inspiration'**
  String get networkingTitle;

  /// No description provided for @networkingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous avec des experts'**
  String get networkingSubtitle;

  /// No description provided for @welcomeToSiade.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue à\nSIADE 2026'**
  String get welcomeToSiade;

  /// No description provided for @discoverTechEvent.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez l\'événement tech de l\'année'**
  String get discoverTechEvent;

  /// No description provided for @readyToStart.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à commencer\nl\'aventure ?'**
  String get readyToStart;

  /// No description provided for @joinSiadeNow.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez SIADE 2026 dès maintenant'**
  String get joinSiadeNow;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @program.
  ///
  /// In fr, this message translates to:
  /// **'Programme'**
  String get program;

  /// No description provided for @gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @location.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get location;

  /// No description provided for @live.
  ///
  /// In fr, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @restaurant.
  ///
  /// In fr, this message translates to:
  /// **'Resto SIADE'**
  String get restaurant;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètre'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @myStory.
  ///
  /// In fr, this message translates to:
  /// **'Ma story'**
  String get myStory;

  /// No description provided for @copyright.
  ///
  /// In fr, this message translates to:
  /// **'COPYRIGHT SAHANALYTICS'**
  String get copyright;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// No description provided for @speakers.
  ///
  /// In fr, this message translates to:
  /// **'Intervenants'**
  String get speakers;

  /// No description provided for @exponents.
  ///
  /// In fr, this message translates to:
  /// **'Exposants'**
  String get exponents;

  /// No description provided for @news.
  ///
  /// In fr, this message translates to:
  /// **'Actualités'**
  String get news;

  /// No description provided for @whatOnYourMind.
  ///
  /// In fr, this message translates to:
  /// **'À quoi pensez-vous ?'**
  String get whatOnYourMind;

  /// No description provided for @posts.
  ///
  /// In fr, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @comments.
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get comments;

  /// No description provided for @likes.
  ///
  /// In fr, this message translates to:
  /// **'J\'aime'**
  String get likes;

  /// No description provided for @shares.
  ///
  /// In fr, this message translates to:
  /// **'Partages'**
  String get shares;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get error;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @social.
  ///
  /// In fr, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @chat.
  ///
  /// In fr, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @alerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get alerts;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @me.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get me;

  /// No description provided for @user.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @liveEnded.
  ///
  /// In fr, this message translates to:
  /// **'Ce live est terminé.'**
  String get liveEnded;

  /// No description provided for @markAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get markAllRead;

  /// No description provided for @isLiveNow.
  ///
  /// In fr, this message translates to:
  /// **'est en live !'**
  String get isLiveNow;

  /// No description provided for @discoverInnovations.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez les dernières innovations technologiques.'**
  String get discoverInnovations;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
