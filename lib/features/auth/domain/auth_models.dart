import 'package:equatable/equatable.dart';
import 'package:lumacart/core/utils/json_parsing.dart';

class UserName extends Equatable {
  const UserName({required this.firstName, required this.lastName});

  factory UserName.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return UserName(
      firstName: stringValue(map['firstname']),
      lastName: stringValue(map['lastname']),
    );
  }

  final String firstName;
  final String lastName;

  String get fullName => <String>[firstName, lastName]
      .where((String part) => part.isNotEmpty)
      .join(' ');

  Map<String, Object?> toJson() => <String, Object?>{
        'firstname': firstName,
        'lastname': lastName,
      };

  @override
  List<Object?> get props => <Object?>[firstName, lastName];
}

class GeoLocation extends Equatable {
  const GeoLocation({required this.latitude, required this.longitude});

  factory GeoLocation.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return GeoLocation(
      latitude: stringValue(map['lat']),
      longitude: stringValue(map['long']),
    );
  }

  final String latitude;
  final String longitude;

  Map<String, Object?> toJson() => <String, Object?>{
        'lat': latitude,
        'long': longitude,
      };

  @override
  List<Object?> get props => <Object?>[latitude, longitude];
}

class Address extends Equatable {
  const Address({
    required this.city,
    required this.street,
    required this.number,
    required this.zipCode,
    required this.geoLocation,
  });

  factory Address.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return Address(
      city: stringValue(map['city']),
      street: stringValue(map['street']),
      number: intValue(map['number']),
      zipCode: stringValue(map['zipcode']),
      geoLocation: GeoLocation.fromJson(map['geolocation']),
    );
  }

  static const Address empty = Address(
    city: '',
    street: '',
    number: 0,
    zipCode: '',
    geoLocation: GeoLocation(latitude: '', longitude: ''),
  );

  final String city;
  final String street;
  final int number;
  final String zipCode;
  final GeoLocation geoLocation;

  String get formatted {
    final String streetLine = <String>[
      if (street.isNotEmpty) street,
      if (number > 0) number.toString(),
    ].join(' ');
    return <String>[
      streetLine,
      <String>[zipCode, city]
          .where((String part) => part.isNotEmpty)
          .join(' '),
    ].where((String part) => part.isNotEmpty).join(', ');
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'city': city,
        'street': street,
        'number': number,
        'zipcode': zipCode,
        'geolocation': geoLocation.toJson(),
      };

  @override
  List<Object?> get props => <Object?>[
        city,
        street,
        number,
        zipCode,
        geoLocation,
      ];
}

class StoreUser extends Equatable {
  const StoreUser({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory StoreUser.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return StoreUser(
      id: intValue(map['id']),
      email: stringValue(map['email']),
      username: stringValue(map['username']),
      name: UserName.fromJson(map['name']),
      address: Address.fromJson(map['address']),
      phone: stringValue(map['phone']),
    );
  }

  final int id;
  final String email;
  final String username;
  final UserName name;
  final Address address;
  final String phone;

  String get displayName => name.fullName.isEmpty ? username : name.fullName;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'email': email,
        'username': username,
        'name': name.toJson(),
        'address': address.toJson(),
        'phone': phone,
      };

  StoreUser copyWith({int? id}) => StoreUser(
        id: id ?? this.id,
        email: email,
        username: username,
        name: name,
        address: address,
        phone: phone,
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        email,
        username,
        name,
        address,
        phone,
      ];
}

class AuthToken extends Equatable {
  const AuthToken(this.value);

  factory AuthToken.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return AuthToken(stringValue(map['token']));
  }

  final String value;

  bool get isValid => value.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[value];

  @override
  bool get stringify => false;
}

class LocalAccount extends Equatable {
  const LocalAccount({
    required this.localId,
    required this.user,
    required this.passwordHash,
    required this.passwordSalt,
    required this.hashIterations,
    required this.createdAt,
  });

  factory LocalAccount.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return LocalAccount(
      localId: stringValue(map['localId']),
      user: StoreUser.fromJson(map['user']),
      passwordHash: stringValue(map['passwordHash']),
      passwordSalt: stringValue(map['passwordSalt']),
      hashIterations: intValue(map['hashIterations']),
      createdAt: DateTime.tryParse(stringValue(map['createdAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String localId;
  final StoreUser user;
  final String passwordHash;
  final String passwordSalt;
  final int hashIterations;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'localId': localId,
        'user': user.toJson(),
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt,
        'hashIterations': hashIterations,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => <Object?>[localId, user, hashIterations, createdAt];

  @override
  bool get stringify => false;
}

enum AccountType { api, local }

class AuthSession extends Equatable {
  const AuthSession({
    required this.accountKey,
    required this.user,
    required this.accountType,
    required this.signedInAt,
    this.token,
  });

  factory AuthSession.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    final String rawType = stringValue(map['accountType']);
    return AuthSession(
      accountKey: stringValue(map['accountKey']),
      user: StoreUser.fromJson(map['user']),
      accountType:
          rawType == AccountType.local.name ? AccountType.local : AccountType.api,
      signedInAt: DateTime.tryParse(stringValue(map['signedInAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      token: stringValue(map['token']).isEmpty
          ? null
          : AuthToken(stringValue(map['token'])),
    );
  }

  final String accountKey;
  final StoreUser user;
  final AccountType accountType;
  final DateTime signedInAt;
  final AuthToken? token;

  Map<String, Object?> toJson() => <String, Object?>{
        'accountKey': accountKey,
        'user': user.toJson(),
        'accountType': accountType.name,
        'signedInAt': signedInAt.toUtc().toIso8601String(),
        'token': token?.value,
      };

  @override
  List<Object?> get props => <Object?>[
        accountKey,
        user,
        accountType,
        signedInAt,
      ];

  @override
  bool get stringify => false;
}

class SignUpInput extends Equatable {
  const SignUpInput({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.phone,
    required this.city,
    required this.street,
    required this.streetNumber,
    required this.zipCode,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;
  final String confirmPassword;
  final String phone;
  final String city;
  final String street;
  final int streetNumber;
  final String zipCode;

  StoreUser toUser({int id = 0}) => StoreUser(
        id: id,
        email: email.trim(),
        username: username.trim(),
        name: UserName(
          firstName: firstName.trim(),
          lastName: lastName.trim(),
        ),
        address: Address(
          city: city.trim(),
          street: street.trim(),
          number: streetNumber,
          zipCode: zipCode.trim(),
          geoLocation: const GeoLocation(latitude: '', longitude: ''),
        ),
        phone: phone.trim(),
      );

  Map<String, Object?> toApiJson() {
    final StoreUser user = toUser();
    return <String, Object?>{
      'email': user.email,
      'username': user.username,
      'password': password,
      'name': user.name.toJson(),
      'address': user.address.toJson(),
      'phone': user.phone,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        firstName,
        lastName,
        email,
        username,
        phone,
        city,
        street,
        streetNumber,
        zipCode,
      ];

  @override
  bool get stringify => false;
}

class AuthResult extends Equatable {
  const AuthResult({required this.session, this.warning});

  final AuthSession session;
  final String? warning;

  @override
  List<Object?> get props => <Object?>[session, warning];
}
