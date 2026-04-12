class ApiConstants {
  static const String baseUrl = 'https://siade.ci';

  // Auth
  static const String login = '$baseUrl/api/login/';
  static const String tokenObtain = '$baseUrl/api/token/';
  static const String tokenRefresh = '$baseUrl/api/token/refresh/';
  static const String passwordReset = '$baseUrl/api/reset_password/';

  // Endpoints
  static const String sponsors = '$baseUrl/api/sponsors/';
  static const String articles = '$baseUrl/api/articles/';
  static const String partners = '$baseUrl/api/partners/';
  static const String program = '$baseUrl/api/program/';
  static const String statistique = '$baseUrl/api/statistique/';
  static const String testimonials = '$baseUrl/api/testimonials/';
  static const String registrations = '$baseUrl/api/registration_siade/';
  static const String users = '$baseUrl/api/users/';
  static const String accreditations = '$baseUrl/api/accreditation_siade/';
  static const String summaries = '$baseUrl/api/summary_siade/';
  static const String dashboard = '$baseUrl/api/dashboard/';
  static const String partnerCompanies = '$baseUrl/api/partner_company/';
  static const String hackaton = '$baseUrl/api/hackaton/';
  static const String bestStartup = '$baseUrl/api/best_startup/';
  static const String exposants = '$baseUrl/api/exhibitors/';
  static const String caterers = '$baseUrl/api/caterers/';
  static const String gallery = '$baseUrl/api/gallery/';
  static const String notificationsRegister = '$baseUrl/api/notifications/register/';
  static const String notificationsLive = '$baseUrl/api/notifications/history/notify-live/';
  static const String notificationsCall = '$baseUrl/api/notifications/history/notify-call/';

  // Dates réelles de l'événement SIADE 2026 (modifier ici si les dates changent)
  static const String eventDay1 = '2026-04-09'; // Jour 1
  static const String eventDay2 = '2026-04-10'; // Jour 2

  // Media
  static const String mediaUrl = '$baseUrl/media/';
}
