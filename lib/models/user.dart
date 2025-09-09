class User {
  final int id;
  final String name;
  final String? username;
  final String email;
  final String? emailVerifiedAt;
  final int isActive;
  final String? photoPath;
  final String? photoUrl;
  final String createdAt;
  final String updatedAt;
  final List<Role> roles;
  final Employee? employee;

  User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.emailVerifiedAt,
    required this.isActive,
    this.photoPath,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.roles,
    this.employee,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      isActive: json['is_active'],
      photoPath: json['photo_path'],
      photoUrl: json['photo_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      roles: (json['roles'] as List<dynamic>?)
          ?.map((role) => Role.fromJson(role))
          .toList() ?? [],
      employee: json['employee'] != null 
          ? Employee.fromJson(json['employee']) 
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
  final String guardName;
  final String description;
  final int isActive;
  final String createdAt;
  final String updatedAt;
  final Pivot? pivot;

  Role({
    required this.id,
    required this.name,
    required this.guardName,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.pivot,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      guardName: json['guard_name'],
      description: json['description'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      pivot: json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null,
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
      modelType: json['model_type'],
      modelId: json['model_id'],
      roleId: json['role_id'],
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

class Employee {
  final int id;
  final int userId;
  final int positionId;
  final String name;
  final String nik;
  final String nikKtp;
  final String code;
  final String phone;
  final String gender;
  final String joinAt;
  final String? birthDate;
  final String? address;
  final int agencyId;
  final int branchOfficeId;
  final int cityId;
  final int subAreaId;
  final int isLeader;
  final int? leaderId;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? ktpUrl;
  final String? ktpPath;
  final String? bankAccountUrl;
  final String? bankAccountPath;
  final int isAppUsed;
  final String appVersion;
  final String appDevice;
  final int isResigned;
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
  final String createdAt;
  final String updatedAt;

  Employee({
    required this.id,
    required this.userId,
    required this.positionId,
    required this.name,
    required this.nik,
    required this.nikKtp,
    required this.code,
    required this.phone,
    required this.gender,
    required this.joinAt,
    this.birthDate,
    this.address,
    required this.agencyId,
    required this.branchOfficeId,
    required this.cityId,
    required this.subAreaId,
    required this.isLeader,
    this.leaderId,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.ktpUrl,
    this.ktpPath,
    this.bankAccountUrl,
    this.bankAccountPath,
    required this.isAppUsed,
    required this.appVersion,
    required this.appDevice,
    required this.isResigned,
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      userId: json['user_id'],
      positionId: json['position_id'],
      name: json['name'],
      nik: json['nik'],
      nikKtp: json['nik_ktp'],
      code: json['code'],
      phone: json['phone'],
      gender: json['gender'],
      joinAt: json['join_at'],
      birthDate: json['birth_date'],
      address: json['address'],
      agencyId: json['agency_id'],
      branchOfficeId: json['branch_office_id'],
      cityId: json['city_id'],
      subAreaId: json['sub_area_id'],
      isLeader: json['is_leader'],
      leaderId: json['leader_id'],
      bankName: json['bank_name'],
      bankAccountNumber: json['bank_account_number'],
      bankAccountName: json['bank_account_name'],
      ktpUrl: json['ktp_url'],
      ktpPath: json['ktp_path'],
      bankAccountUrl: json['bank_account_url'],
      bankAccountPath: json['bank_account_path'],
      isAppUsed: json['is_app_used'],
      appVersion: json['app_version'],
      appDevice: json['app_device'],
      isResigned: json['is_resigned'],
      requestedResignedAt: json['requested_resigned_at'],
      resignedAt: json['resigned_at'],
      resignedReason: json['resigned_reason'],
      resignedNotes: json['resigned_notes'],
      resignedPicName: json['resigned_pic_name'],
      rejoinAt: json['rejoin_at'],
      rejoinReason: json['rejoin_reason'],
      rejoinPicName: json['rejoin_pic_name'],
      status: json['status'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'position_id': positionId,
      'name': name,
      'nik': nik,
      'nik_ktp': nikKtp,
      'code': code,
      'phone': phone,
      'gender': gender,
      'join_at': joinAt,
      'birth_date': birthDate,
      'address': address,
      'agency_id': agencyId,
      'branch_office_id': branchOfficeId,
      'city_id': cityId,
      'sub_area_id': subAreaId,
      'is_leader': isLeader,
      'leader_id': leaderId,
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
