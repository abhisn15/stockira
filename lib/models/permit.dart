import 'package:flutter/material.dart';

class Permit {
  final int id;
  final int permitTypeId;
  final String permitTypeName;
  final String startDate;
  final String endDate;
  final String reason;
  final String? imageUrl;
  final String status;
  final String? approvedBy;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;

  Permit({
    required this.id,
    required this.permitTypeId,
    required this.permitTypeName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.imageUrl,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Permit.fromJson(Map<String, dynamic> json) {
    // Determine status based on is_approved field
    String status = 'pending';
    if (json['is_approved'] == true) {
      status = 'approved';
    } else if (json['is_approved'] == false) {
      status = 'rejected';
    }

    return Permit(
      id: json['id'] ?? 0,
      permitTypeId: json['permit_type_id'] ?? 0,
      permitTypeName: json['permit_type']?['name'] ?? 'Unknown',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      reason: json['reason'] ?? '',
      imageUrl: json['image_url'],
      status: status,
      approvedBy: json['approved_by_name'],
      approvedAt: json['approved_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permit_type_id': permitTypeId,
      'permit_type_name': permitTypeName,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'image_url': imageUrl,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get status text in Indonesian
  String get statusText {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
        return 'Menunggu';
      default:
        return 'Tidak Diketahui';
    }
  }

  // Format date
  String get formattedStartDate {
    try {
      final date = DateTime.parse(startDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return startDate;
    }
  }

  String get formattedEndDate {
    try {
      final date = DateTime.parse(endDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return endDate;
    }
  }

  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }
}

class PermitType {
  final int id;
  final String name;
  final String? description;

  PermitType({
    required this.id,
    required this.name,
    this.description,
  });

  factory PermitType.fromJson(Map<String, dynamic> json) {
    return PermitType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
