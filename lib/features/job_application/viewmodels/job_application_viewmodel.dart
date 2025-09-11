import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickhire/features/job_application/models/job_application_model.dart';
import 'package:quickhire/features/job_application/services/job_application_service.dart';
import 'package:quickhire/core/model/job_listings_model.dart';

// Provider for the service
final jobApplicationServiceProvider = Provider<JobApplicationService>((ref) {
  return JobApplicationService();
});

// State for job application form
class JobApplicationFormState {
  final String message;
  final bool isSubmitting;
  final String? error;
  final bool isSuccess;

  const JobApplicationFormState({
    this.message = '',
    this.isSubmitting = false,
    this.error,
    this.isSuccess = false,
  });

  JobApplicationFormState copyWith({
    String? message,
    bool? isSubmitting,
    String? error,
    bool? isSuccess,
  }) {
    return JobApplicationFormState(
      message: message ?? this.message,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// ViewModel for job application form
class JobApplicationFormViewModel
    extends StateNotifier<JobApplicationFormState> {
  JobApplicationFormViewModel(this._service)
    : super(const JobApplicationFormState());

  final JobApplicationService _service;

  void updateMessage(String message) {
    state = state.copyWith(message: message, error: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const JobApplicationFormState();
  }

  Future<bool> submitApplication(JobListing job) async {
    if (!_service.isValidApplicationMessage(state.message)) {
      state = state.copyWith(
        error:
            'Please enter a message of at least 10 characters explaining why you\'re interested.',
      );
      return false;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      state = state.copyWith(error: 'You must be logged in to apply for jobs.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      await _service.submitApplication(
        jobId: job.id,
        jobTitle: job.title,
        employerUid: job.posterUid,
        message: state.message,
        applicantUid: currentUser.uid,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> checkIfApplied(String jobId) async {
    try {
      return await _service.hasAppliedForJob(jobId);
    } catch (e) {
      return false;
    }
  }
}

// Provider for the form view model
final jobApplicationFormViewModelProvider = StateNotifierProvider.autoDispose<
  JobApplicationFormViewModel,
  JobApplicationFormState
>((ref) {
  final service = ref.watch(jobApplicationServiceProvider);
  return JobApplicationFormViewModel(service);
});

// Provider to check if user has applied for a specific job
final hasAppliedProvider = FutureProvider.family.autoDispose<bool, String>((
  ref,
  jobId,
) async {
  final service = ref.watch(jobApplicationServiceProvider);
  return await service.hasAppliedForJob(jobId);
});

// Provider for user's applications (no cache, auto-dispose)
final userApplicationsProvider =
    StreamProvider.autoDispose<List<JobApplication>>((ref) {
      final service = ref.watch(jobApplicationServiceProvider);
      return service.getUserApplications();
    });

// Provider for employer's applications (no cache, auto-dispose)
final employerApplicationsProvider =
    StreamProvider.autoDispose<List<JobApplication>>((ref) {
      final service = ref.watch(jobApplicationServiceProvider);
      return service.getEmployerApplications();
    });

// Provider for applications on a specific job (no cache, auto-dispose)
final jobApplicationsProvider = StreamProvider.family
    .autoDispose<List<JobApplication>, String>((ref, jobId) {
      final service = ref.watch(jobApplicationServiceProvider);
      return service.getJobApplications(jobId);
    });

// Provider for application count on a specific job (with refresh capability)
final jobApplicationCountProvider = StreamProvider.family
    .autoDispose<int, String>((ref, jobId) {
      final service = ref.watch(jobApplicationServiceProvider);
      return service
          .getJobApplications(jobId)
          .map(
            (applications) =>
                applications
                    .where((app) => app.status != ApplicationStatus.withdrawn)
                    .length,
          );
    });

// Provider for pending applications count for employer (no cache, auto-dispose)
final pendingApplicationsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final service = ref.watch(jobApplicationServiceProvider);
  return await service.getPendingApplicationsCount();
});
