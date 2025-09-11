import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus { pending, accepted, rejected, withdrawn }

class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String applicantUid;
  final String employerUid;
  final String message;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? updatedAt;
  final String? employerMessage; // Optional message from employer
  final Map<String, dynamic>? metadata; // Additional data

  JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.applicantUid,
    required this.employerUid,
    required this.message,
    required this.status,
    required this.appliedAt,
    this.updatedAt,
    this.employerMessage,
    this.metadata,
  });

  factory JobApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return JobApplication(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      applicantUid: data['applicantUid'] ?? '',
      employerUid: data['employerUid'] ?? '',
      message: data['message'] ?? '',
      status: _parseStatus(data['status']),
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      employerMessage: data['employerMessage'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'applicantUid': applicantUid,
      'employerUid': employerUid,
      'message': message,
      'status': status.name,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'employerMessage': employerMessage,
      'metadata': metadata,
    };
  }

  static ApplicationStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'withdrawn':
        return ApplicationStatus.withdrawn;
      default:
        return ApplicationStatus.pending;
    }
  }

  JobApplication copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? applicantUid,
    String? employerUid,
    String? message,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? updatedAt,
    String? employerMessage,
    Map<String, dynamic>? metadata,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      applicantUid: applicantUid ?? this.applicantUid,
      employerUid: employerUid ?? this.employerUid,
      message: message ?? this.message,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      employerMessage: employerMessage ?? this.employerMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isPending => status == ApplicationStatus.pending;
  bool get isAccepted => status == ApplicationStatus.accepted;
  bool get isRejected => status == ApplicationStatus.rejected;
  bool get isWithdrawn => status == ApplicationStatus.withdrawn;

  String get statusDisplayName {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Not Selected';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}
