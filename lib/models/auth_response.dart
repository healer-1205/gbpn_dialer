class AuthResponse {
  final String token;
  final String twilioAccessToken;
  final User user;
  final List<Team> teams;
  final String status;
  final String message;

  AuthResponse({
    required this.token,
    required this.twilioAccessToken,
    required this.user,
    required this.teams,
    required this.status,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      twilioAccessToken: json['twilio_access_token'],
      user: User.fromJson(json['user']),
      teams: (json['teams'] as List)
          .map((team) => Team.fromJson(team))
          .toList(),
      status: json['status'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'twilio_access_token': twilioAccessToken,
      'user': user.toJson(),
      'teams': teams.map((team) => team.toJson()).toList(),
      'status': status,
      'message': message,
    };
  }
}

class User {
  final String name;
  final String profilePhotoUrl;

  User({
    required this.name,
    required this.profilePhotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'profile_photo_url': profilePhotoUrl,
    };
  }
}

class Team {
  final int id;
  final String name;
  final List<PhoneNumber> phoneNumbers;

  Team({
    required this.id,
    required this.name,
    required this.phoneNumbers,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      phoneNumbers: (json['phone_numbers'] as List)
          .map((phone) => PhoneNumber.fromJson(phone))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_numbers': phoneNumbers.map((phone) => phone.toJson()).toList(),
    };
  }
}

class PhoneNumber {
  final int id;
  final String name;
  final String phoneNumber;
  final String friendlyName;

  PhoneNumber({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.friendlyName,
  });

  factory PhoneNumber.fromJson(Map<String, dynamic> json) {
    return PhoneNumber(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      friendlyName: json['friendly_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'friendly_name': friendlyName,
    };
  }
}