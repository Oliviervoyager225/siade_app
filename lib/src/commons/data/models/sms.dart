
class Sms {
  String name;
  String imagePath;
  String sendDate;
  String message;

  Sms({required this.name, required this.imagePath, required this.sendDate, required this.message});

  String convertSendDate() {
    DateTime dateTime = DateTime.parse(sendDate);

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final inputDateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (inputDateOnly.isAtSameMomentAs(today)) {
      return '${dateTime.hour}:${dateTime.minute}';
    } else if (inputDateOnly.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}'; 
    }
  }
}



final List<Sms> messages= [
  Sms(
    name: "Alice",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-09 09:15:00",
    message: "Salut ! Tu as bien reçu le document ?",
  ),
  Sms(
    name: "Bob",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-09 08:42:00",
    message: "On se retrouve à midi pour le déjeuner.",
  ),
  Sms(
    name: "Carla",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-09 07:55:00",
    message: "Bonne journée 🌞",
  ),
  Sms(
    name: "David",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-08 22:40:00",
    message: "Je t’ai envoyé le rapport par mail.",
  ),
  Sms(
    name: "Emma",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-08 19:25:00",
    message: "Tu regardes toujours la série ce soir ?",
  ),
  Sms(
    name: "Frank",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-07 15:10:00",
    message: "Réunion déplacée à 16h30.",
  ),
  Sms(
    name: "Grace",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-07 11:03:00",
    message: "Merci pour ton aide hier ! 🙏",
  ),
  Sms(
    name: "Hugo",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-06 20:45:00",
    message: "J’ai bien reçu le colis.",
  ),
  Sms(
    name: "Isabelle",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-06 18:10:00",
    message: "Penses à confirmer ton inscription demain.",
  ),
  Sms(
    name: "James",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-06 09:37:00",
    message: "Nouvelle mise à jour dispo sur l’app !",
  ),
  Sms(
    name: "Karen",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-05 23:55:00",
    message: "C’était super de te revoir 😊",
  ),
  Sms(
    name: "Léo",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-05 20:40:00",
    message: "Appelle-moi quand tu peux.",
  ),
  Sms(
    name: "Mila",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-04 17:25:00",
    message: "Le fichier est sur Google Drive.",
  ),
  Sms(
    name: "Noah",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-04 12:05:00",
    message: "On commence à 14h, ne sois pas en retard 😅",
  ),
  Sms(
    name: "Olivia",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-03 09:45:00",
    message: "As-tu vu les dernières nouvelles ?",
  ),
  Sms(
    name: "Paul",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-02 16:30:00",
    message: "Je passerai te voir demain matin.",
  ),
  Sms(
    name: "Quentin",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-02 10:00:00",
    message: "Merci encore pour ton aide 👏",
  ),
  Sms(
    name: "Rosa",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-11-01 21:05:00",
    message: "Bon week-end à toi ! 🎉",
  ),
  Sms(
    name: "Samuel",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-10-31 14:20:00",
    message: "Le projet avance bien, on en reparle lundi.",
  ),
  Sms(
    name: "Tina",
    imagePath: "assets/images/sms_avatar.png",
    sendDate: "2026-10-30 08:10:00",
    message: "N’oublie pas la réunion avec le client.",
  ),
];
