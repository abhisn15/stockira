class User {
  final int id;
  final String name;
  final String? username;
  final String email;
  final String? emailVerifiedAt;
  final int? isActive;
  final String? photoPath;
  final String? photoUrl;
  final String? createdAt;
  final String? updatedAt;
  final List<Role> roles;
  final Employee? employee;

  User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.emailVerifiedAt,
    this.isActive,
    this.photoPath,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    required this.roles,
    this.employee,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      isActive: json['is_active'] as int?,
      photoPath: json['photo_path'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      roles: (json['roles'] as List<dynamic>?)
          ?.map((role) => Role.fromJson(role as Map<String, dynamic>))
          .toList() ?? [],
      employee: json['employee'] != null 
          ? Employee.fromJson(json['employee'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'is_active': isActive,
      'photo_path': photoPath,
      'photo_url': photoUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'roles': roles.map((role) => role.toJson()).toList(),
      'employee': employee?.toJson(),
    };
  }
}

class Role {
  final int id;
  final String name;
  final String? guardName;
  final String? description;
  final int? isActive;
  final String? createdAt;
  final String? updatedAt;
  final Pivot? pivot;

  Role({
    required this.id,
    required this.name,
    this.guardName,
    this.description,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      guardName: json['guard_name'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      pivot: json['pivot'] != null ? Pivot.fromJson(json['pivot'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'guard_name': guardName,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pivot': pivot?.toJson(),
    };
  }
}

class Pivot {
  final String modelType;
  final int modelId;
  final int roleId;

  Pivot({
    required this.modelType,
    required this.modelId,
    required this.roleId,
  });

  factory Pivot.fromJson(Map<String, dynamic> json) {
    return Pivot(
      modelType: json['model_type'] as String,
      modelId: json['model_id'] as int,
      roleId: json['role_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_type': modelType,
      'model_id': modelId,
      'role_id': roleId,
    };
  }
}

class Position {
  final int id;
  final String name;
  final String slug;
  final String? description;

  Position({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
    };
  }
}

class Agency {
  final int id;
  final String name;
  final String slug;

  Agency({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

class BranchOffice {
  final int id;
  final String name;

  BranchOffice({
    required this.id,
    required this.name,
  });

  factory BranchOffice.fromJson(Map<String, dynamic> json) {
    return BranchOffice(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class City {
  final String id;
  final String code;
  final String name;
  final Meta meta;

  City({
    required this.id,
    required this.code,
    required this.name,
    required this.meta,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'meta': meta.toJson(),
    };
  }
}

class Meta {
  final String lat;
  final String longitude;

  Meta({
    required this.lat,
    required this.longitude,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      lat: json['lat'] as String,
      longitude: json['long'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'long': longitude,
    };
  }
}

class SubArea {
  final int id;
  final String name;
  final String? code;

  SubArea({
    required this.id,
    required this.name,
    this.code,
  });

  factory SubArea.fromJson(Map<String, dynamic> json) {
    return SubArea(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }
}

class Employee {
  final int id;
  final int? userId;
  final String name;
  final String nik;
  final String nikKtp;
  final String code;
  final String phone;
  final String gender;
  final String joinAt;
  final String? birthDate;
  final String? address;
  final int? isLeader;
  final dynamic leader;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? ktpUrl;
  final String? ktpPath;
  final String? bankAccountUrl;
  final String? bankAccountPath;
  final int? isAppUsed;
  final String? appVersion;
  final String? appDevice;
  final int? isResigned;
  final String? requestedResignedAt;
  final String? resignedAt;
  final String? resignedReason;
  final String? resignedNotes;
  final String? resignedPicName;
  final String? rejoinAt;
  final String? rejoinReason;
  final String? rejoinPicName;
  final String status;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final Position? position;
  final Agency? agency;
  final BranchOffice? branchOffice;
  final City? city;
  final SubArea? subArea;

  Employee({
    required this.id,
    this.userId,
    required this.name,
    required this.nik,
    required this.nikKtp,
    required this.code,
    required this.phone,
    required this.gender,
    required this.joinAt,
    this.birthDate,
    this.address,
    this.isLeader,
    this.leader,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.ktpUrl,
    this.ktpPath,
    this.bankAccountUrl,
    this.bankAccountPath,
    this.isAppUsed,
    this.appVersion,
    this.appDevice,
    this.isResigned,
    this.requestedResignedAt,
    this.resignedAt,
    this.resignedReason,
    this.resignedNotes,
    this.resignedPicName,
    this.rejoinAt,
    this.rejoinReason,
    this.rejoinPicName,
    required this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.position,
    this.agency,
    this.branchOffice,
    this.city,
    this.subArea,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String,
      nik: json['nik'] as String,
      nikKtp: json['nik_ktp'] as String,
      code: json['code'] as String,
      phone: json['phone'] as String,
      gender: json['gender'] as String,
      joinAt: json['join_at'] as String,
      birthDate: json['birth_date'] as String?,
      address: json['address'] as String?,
      isLeader: json['is_leader'] as int?,
      leader: json['leader'],
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      ktpUrl: json['ktp_url'] as String?,
      ktpPath: json['ktp_path'] as String?,
      bankAccountUrl: json['bank_account_url'] as String?,
      bankAccountPath: json['bank_account_path'] as String?,
      isAppUsed: json['is_app_used'] as int?,
      appVersion: json['app_version'] as String?,
      appDevice: json['app_device'] as String?,
      isResigned: json['is_resigned'] as int?,
      requestedResignedAt: json['requested_resigned_at'] as String?,
      resignedAt: json['resigned_at'] as String?,
      resignedReason: json['resigned_reason'] as String?,
      resignedNotes: json['resigned_notes'] as String?,
      resignedPicName: json['resigned_pic_name'] as String?,
      rejoinAt: json['rejoin_at'] as String?,
      rejoinReason: json['rejoin_reason'] as String?,
      rejoinPicName: json['rejoin_pic_name'] as String?,
      status: json['status'] as String,
      deletedAt: json['deleted_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      position: json['position'] != null ? Position.fromJson(json['position'] as Map<String, dynamic>) : null,
      agency: json['agency'] != null ? Agency.fromJson(json['agency'] as Map<String, dynamic>) : null,
      branchOffice: json['branch_office'] != null ? BranchOffice.fromJson(json['branch_office'] as Map<String, dynamic>) : null,
      city: json['city'] != null ? City.fromJson(json['city'] as Map<String, dynamic>) : null,
      subArea: json['sub_area'] != null ? SubArea.fromJson(json['sub_area'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'nik': nik,
      'nik_ktp': nikKtp,
      'code': code,
      'phone': phone,
      'gender': gender,
      'join_at': joinAt,
      'birth_date': birthDate,
      'address': address,
      'is_leader': isLeader,
      'leader': leader,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'ktp_url': ktpUrl,
      'ktp_path': ktpPath,
      'bank_account_url': bankAccountUrl,
      'bank_account_path': bankAccountPath,
      'is_app_used': isAppUsed,
      'app_version': appVersion,
      'app_device': appDevice,
      'is_resigned': isResigned,
      'requested_resigned_at': requestedResignedAt,
      'resigned_at': resignedAt,
      'resigned_reason': resignedReason,
      'resigned_notes': resignedNotes,
      'resigned_pic_name': resignedPicName,
      'rejoin_at': rejoinAt,
      'rejoin_reason': rejoinReason,
      'rejoin_pic_name': rejoinPicName,
      'status': status,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'position': position?.toJson(),
      'agency': agency?.toJson(),
      'branch_office': branchOffice?.toJson(),
      'city': city?.toJson(),
      'sub_area': subArea?.toJson(),
    };
  }
}

class ProfileResponse {
  final bool success;
  final String message;
  final User data;

  ProfileResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: User.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final LoginData data;

  LoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      message: json['message'],
      data: LoginData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class LoginData {
  final String token;
  final String type;
  final String expiresAt;
  final User user;

  LoginData({
    required this.token,
    required this.type,
    required this.expiresAt,
    required this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token'],
      type: json['type'],
      expiresAt: json['expires_at'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'type': type,
      'expires_at': expiresAt,
      'user': user.toJson(),
    };
  }
}