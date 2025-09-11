import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_loading_indicator.dart';
import 'package:quickhire/features/home/employer/viewmodel/employer_home_viewmodel.dart';
import 'package:quickhire/features/home/employer/views/widgets/employer_job_card.dart';
import 'package:quickhire/features/home/employer/views/pages/job_applicants_page.dart';
import 'package:quickhire/features/home/employer/views/pages/edit_job_page.dart';
import 'package:quickhire/features/home/core/views/widgets/no_internet.dart';
import 'package:quickhire/features/home/core/views/widgets/animated_header.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/core/navigation/views/widgets/confirmation_dialog.dart';
import 'package:quickhire/core/services/loading_service.dart';
import 'package:quickhire/features/notifications/views/pages/notifications_page.dart';

class EmployerHomePage extends StatefulWidget {
  const EmployerHomePage({super.key});

  @override
  State<EmployerHomePage> createState() => _EmployerHomePageState();
}

class _EmployerHomePageState extends State<EmployerHomePage> {
  final ScrollController _scrollController = ScrollController();
  late final EmployerHomeViewModel _viewModel;

  bool _isHeaderVisible = true;
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = EmployerHomeViewModel();
    _scrollController.addListener(_scrollListener);
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final direction = _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse && _isHeaderVisible) {
      setState(() => _isHeaderVisible = false);
    } else if (direction == ScrollDirection.forward && !_isHeaderVisible) {
      setState(() => _isHeaderVisible = true);
    }
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() async {
    try {
      await _viewModel.refreshJobs();
    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context: context,
          title: 'Refresh Failed',
          message: 'Failed to refresh jobs: $e',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          buttonText: 'OK',
        );
      }
    }
  }

  void _navigateToJobPosting() {
    context.push('/job-posting');
  }

  void _navigateToJobApplicants(dynamic job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobApplicantsPage(job: job)),
    );
  }

  void _navigateToEditJob(dynamic job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditJobPage(job: job, viewModel: _viewModel),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Text(
      '$title ($count)',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3436),
      ),
    );
  }

  Future<void> _toggleJobStatus(dynamic job) async {
    try {
      await LoadingService.runWithLoading(context, () async {
        await _viewModel.updateJobListing(
          jobId: job.id,
          isActive: !job.isActive,
        );
      });

      if (mounted) {
        CustomDialog.show(
          context: context,
          title: 'Success',
          message:
              job.isActive
                  ? 'Job listing paused successfully'
                  : 'Job listing activated successfully',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          buttonText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context: context,
          title: 'Error',
          message: 'Failed to update job status: $e',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _deleteJob(dynamic job) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Job Listing',
      message:
          'Are you sure you want to delete "${job.title}"? This action cannot be undone.',
      confirmText: 'DELETE',
      cancelText: 'CANCEL',
    );

    if (confirmed == true) {
      try {
        await LoadingService.runWithLoading(context, () async {
          await _viewModel.deleteJobListing(job.id);
        });

        if (mounted) {
          CustomDialog.show(
            context: context,
            title: 'Success',
            message: 'Job listing deleted successfully',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            buttonText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomDialog.show(
            context: context,
            title: 'Error',
            message: 'Failed to delete job listing: $e',
            icon: Icons.error_outline,
            iconColor: Colors.red,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _headerHeight = MediaQuery.of(context).size.height * 0.195;

    return Scaffold(
      backgroundColor: Palette.background,
      body:
          _viewModel.hasInternetConnection
              ? _buildMainContent()
              : _buildNoInternetContent(),
      floatingActionButton:
          _viewModel.isLoading || !_viewModel.hasInternetConnection
              ? null
              : FloatingActionButton(
                onPressed: _navigateToJobPosting,
                backgroundColor: Palette.primary,
                child: const Icon(Icons.add, color: Palette.white),
              ),
    );
  }

  Widget _buildNoInternetContent() {
    return Stack(
      children: [
        RefreshIndicator(
          color: Palette.primary,
          backgroundColor: Palette.white,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: const Column(children: [Expanded(child: NoInternet())]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        // Job listings content
        RefreshIndicator(
          color: Palette.primary,
          backgroundColor: Palette.white,
          edgeOffset: _headerHeight / 2,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: _headerHeight + 20)),
              SliverToBoxAdapter(child: _buildJobListingsSection()),
              SliverPadding(padding: const EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
        AnimatedHeader(
          isVisible: _isHeaderVisible,
          height: _headerHeight,
          userName: _viewModel.userName,
          isLoading: _viewModel.isLoading,
          onNotificationTap: _navigateToNotifications,
        ),
      ],
    );
  }

  Widget _buildJobListingsSection() {
    if (_viewModel.isLoading) {
      return _buildLoadingState();
    }

    if (_viewModel.errorMessage != null) {
      return _buildErrorState();
    }

    if (_viewModel.myJobListings.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          _buildStatsHeader(),
          const SizedBox(height: 24),

          // Active jobs section
          if (_viewModel.activeJobListings.isNotEmpty) ...[
            _buildSectionHeader(
              'Active Job Listings',
              _viewModel.activeJobListings.length,
            ),
            const SizedBox(height: 16),
            ..._viewModel.activeJobListings.map(
              (job) => EmployerJobCard(
                job: job,
                onEdit: () => _navigateToEditJob(job),
                onViewApplications: () => _navigateToJobApplicants(job),
                onToggleStatus: () => _toggleJobStatus(job),
                onDelete: () => _deleteJob(job),
              ),
            ),
          ],

          // Inactive jobs section
          if (_viewModel.inactiveJobListings.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader(
              'Inactive Job Listings',
              _viewModel.inactiveJobListings.length,
            ),
            const SizedBox(height: 16),
            ..._viewModel.inactiveJobListings.map(
              (job) => EmployerJobCard(
                job: job,
                onEdit: () => _navigateToEditJob(job),
                onViewApplications: () => _navigateToJobApplicants(job),
                onToggleStatus: () => _toggleJobStatus(job),
                onDelete: () => _deleteJob(job),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final activeCount = _viewModel.activeJobListings.length;
    final inactiveCount = _viewModel.inactiveJobListings.length;
    final totalCount = _viewModel.myJobListings.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Job Listings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Total', totalCount.toString(), Palette.primary),
              const SizedBox(width: 12),
              _buildStatCard('Active', activeCount.toString(), Colors.green),
              const SizedBox(width: 12),
              _buildStatCard('Inactive', inactiveCount.toString(), Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            CustomLoadingIndicator(),
            SizedBox(height: 16),
            Text('Loading your job listings...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load job listings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewModel.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No job listings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first job listing to find great candidates',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToJobPosting,
              icon: const Icon(Icons.add),
              label: const Text('Create Job Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
