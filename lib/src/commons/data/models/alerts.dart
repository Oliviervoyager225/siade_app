import 'package:intl/intl.dart';

class Alert {
  String date;
  List<Map<String,dynamic>> alerts;

  Alert({
    required this.date,
    required this.alerts,
  });

  String getDateString() {

    DateTime dateTime = DateFormat("yyyy-MM-dd").parse(date);

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final inputDateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (inputDateOnly.isAtSameMomentAs(today)) {
      return 'TODAY';
    } else if (inputDateOnly.isAtSameMomentAs(yesterday)) {
      return 'YESTERDAY';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}'; 
    }
  }
}

final List<Alert> alerts = [
  Alert(
    date: "2026-11-09",
    alerts: [
      {
        "title": "Nouvelle version disponible",
        "description": "Une nouvelle version de l’application a été déployée.",
        "type": "info",
        "hour": "09:42",
      },
      {
        "title": "Erreur de synchronisation",
        "description": "Impossible de synchroniser les données.",
        "type": "error",
        "hour": "11:15",
      },
    ],
  ),
  Alert(
    date: "2026-11-08",
    alerts: [
      {
        "title": "Connexion rétablie",
        "description": "La connexion au serveur a été restaurée.",
        "type": "success",
        "hour": "08:27",
      },
      {
        "title": "Maintenance planifiée",
        "description": "Le système sera indisponible ce soir à 22h.",
        "type": "warning",
        "hour": "19:00",
      },
    ],
  ),
  Alert(
    date: "2026-11-06",
    alerts: [
      {
        "title": "Mise à jour des permissions",
        "description": "Vos permissions ont été modifiées par un administrateur.",
        "type": "info",
        "hour": "14:55",
      },
      {
        "title": "Nouvelle alerte de sécurité",
        "description": "Connexion suspecte détectée depuis un nouvel appareil.",
        "type": "critical",
        "hour": "23:41",
      },
    ],
  ),
];
