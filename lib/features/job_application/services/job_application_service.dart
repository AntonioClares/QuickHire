import 'package:quickhire/features/job_application/models/job_application_model.dart';
import 'package:quickhire/features/job_application/repositories/job_application_repository.dart';
import 'package:quickhire/features/notifications/services/notification_service.dart';
import 'package:quickhire/core/services/user_profile_service.dart';

class JobApplicationService {
  static final JobApplicationService _instance =
      JobApplicationService._internal();
  factory JobApplicationService() => _instance;
  JobApplicationService._internal();

  final JobApplicationRepository _repository = JobApplicationRepository();
  final UserProfileService _userProfileService = UserProfileService();

  // Submit a job application
  Future<String> submitApplication({
    required String jobId,
    required String jobTitle,
    required String employerUid,
    required String message,
    required String applicantUid,
  }) async {
    // Validate required parameters
    if (jobId.trim().isEmpty) {
      throw Exception('Job ID cannot be empty');
    }

    if (jobTitle.trim().isEmpty) {
      throw Exception('Job title cannot be empty');
    }

    if (employerUid.trim().isEmpty) {
      throw Exception('Employer ID cannot be empty');
    }

    if (message.trim().isEmpty) {
      throw Exception('Application message cannot be empty');
    }

    if (applicantUid.trim().isEmpty) {
      throw Exception('Applicant ID cannot be empty');
    }

    // Use a transaction to prevent race conditions
    final applicationId = await _repository.submitApplicationWithCheck(
      jobId: jobId,
      jobTitle: jobTitle,
      employerUid: employerUid,
      message: message,
      applicantUid: applicantUid,
    );

    try {
      // Get applicant's name for notifications
      final userProfile = await _userProfileService.getUserProfile(
        applicantUid,
      );
      final applicantName = userProfile?.name ?? 'Someone';

      // Get company name for success notification
      final employerProfile = await _userProfileService.getUserProfile(
        employerUid,
      );
      final companyName = employerProfile?.name ?? 'the company';

      // Notify employer about new application
      await NotificationService.notifyJobApplication(
        employerId: employerUid,
        applicantName: applicantName,
        jobTitle: jobTitle,
        jobId: jobId,
        applicationId: applicationId,
      );

      // Notify applicant about successful application
      await NotificationService.notifyApplicationSuccess(
        applicantId: applicantUid,
        jobTitle: jobTitle,
        companyName: companyName,
        jobId: jobId,
      );
    } catch (e) {
      // Don't fail the application if notifications fail
      print('Error sending application notifications: $e');
    }

    return applicationId;
  }

  // Check if user has applied for a job
  Future<bool> hasAppliedForJob(String jobId) async {
    return await _repository.hasAppliedForJob(jobId);
  }

  // Get user's applications
  Stream<List<JobApplication>> getUserApplications() {
    return _repository.getUserApplications();
  }

  // Get applications for employer's jobs
  Stream<List<JobApplication>> getEmployerApplications() {
    return _repository.getEmployerApplications();
  }

  // Get applications for a specific job
  Stream<List<JobApplication>> getJobApplications(String jobId) {
    return _repository.getJobApplications(jobId);
  }

  // Update application status (employer action)
  Future<void> updateApplicationStatus({
    required String jobId,
    required String applicationId,
    required ApplicationStatus status,
    String? employerMessage,
  }) async {
    // First get the application to get applicant details
    final application = await _repository.getApplicationById(
      jobId: jobId,
      applicationId: applicationId,
    );

    // Update the application status
    await _repository.updateApplicationStatus(
      jobId: jobId,
      applicationId: applicationId,
      status: status,
      employerMessage: employerMessage,
    );

    // Send notification to applicant about status change
    if (application != null) {
      try {
        await NotificationService.notifyApplicationStatusUpdate(
          applicantId: application.applicantUid,
          jobTitle: application.jobTitle,
          status: status.toString().split('.').last,
          jobId: jobId,
          applicationId: applicationId,
        );
      } catch (e) {
        // Don't fail the status update if notifications fail
        print('Error sending status update notification: $e');
      }
    }
  }

  // Withdraw application (job seeker action)
  Future<void> withdrawApplication({
    required String jobId,
    required String applicationId,
  }) async {
    await _repository.withdrawApplication(
      jobId: jobId,
      applicationId: applicationId,
    );
  }

  // Get application by ID
  Future<JobApplication?> getApplicationById({
    required String jobId,
    required String applicationId,
  }) async {
    return await _repository.getApplicationById(
      jobId: jobId,
      applicationId: applicationId,
    );
  }

  // Get application count for a job
  Future<int> getJobApplicationCount(String jobId) async {
    return await _repository.getJobApplicationCount(jobId);
  }

  // Get pending applications count for employer
  Future<int> getPendingApplicationsCount() async {
    return await _repository.getPendingApplicationsCount();
  }

  // Validate application message
  bool isValidApplicationMessage(String message) {
    final trimmedMessage = message.trim();
    return trimmedMessage.isNotEmpty && trimmedMessage.length >= 10;
  }

  // Get application status color
  static String getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return '#FFA500'; // Orange
      case ApplicationStatus.accepted:
        return '#4CAF50'; // Green
      case ApplicationStatus.rejected:
        return '#F44336'; // Red
      case ApplicationStatus.withdrawn:
        return '#9E9E9E'; // Grey
    }
  }
}
