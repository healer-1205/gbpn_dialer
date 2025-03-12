import 'package:intl/intl.dart';

class Common {
  static convertIntoDayTime(DateTime dateTime) {
    String day = DateFormat.EEEE().format(dateTime);
    if (dateTime.day == DateTime.now().day) {
      return "Today ${dateTime.hour}:${dateTime.minute}${dateTime.hour > 12 ? "PM" : "AM"}";
    } else if (dateTime.day == DateTime.now().day - 1) {
      return "Yesterday ${dateTime.hour}:${dateTime.minute}${dateTime.hour > 12 ? "PM" : "AM"}";
    } else {
      return "${day.substring(0, 3)} ${dateTime.hour}:${dateTime.minute}${dateTime.hour > 12 ? "PM" : "AM"}";
    }
  }

  static convertIntoDay(DateTime dateTime) {
    String day = DateFormat.EEEE().format(dateTime);
    if (dateTime.day == DateTime.now().day) {
      return "Today";
    } else if (dateTime.day == DateTime.now().day - 1) {
      return "Yesterday";
    } else if (DateTime.now().difference(dateTime).inDays > 7) {
      return "${dateTime.day} ${DateFormat("MMM").format(dateTime)} ${DateFormat.EEEE().format(dateTime)}";
    } else {
      return day.substring(0, 3);
    }
  }
}
