import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/navigation/views/widgets/custom_dialog.dart';
import 'package:quickhire/features/home/employee/viewmodel/home_viewmodel.dart';
import 'package:quickhire/features/home/core/views/widgets/no_internet.dart';
import 'package:quickhire/features/home/core/views/widgets/animated_header.dart';
import 'package:quickhire/features/home/core/floating_search_bar.dart';
import 'package:quickhire/features/home/employee/views/widgets/job_sections.dart';
import 'package:quickhire/features/job_application/viewmodels/job_application_viewmodel.dart';
import 'package:quickhire/features/notifications/views/pages/notifications_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  late final HomeViewModel _viewModel;

  bool _isHeaderVisible = true;
  double _headerHeight = 0;
  final double _searchBarHeight = 74.0;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
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
      // Refresh jobs
      await _viewModel.refreshJobs();

      // Also refresh application data to ensure "My Applications" section updates
      ref.invalidate(userApplicationsProvider);
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

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    _headerHeight = MediaQuery.of(context).size.height * 0.235;

    return Scaffold(
      backgroundColor: Palette.background,
      body:
          _viewModel.hasInternetConnection
              ? _buildMainContent()
              : _buildNoInternetContent(),
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
    final recommendedJobs =
        _viewModel.isLoading
            ? _viewModel.createFakeJobListings(5)
            : _viewModel.recommendedJobs;

    final recentJobs =
        _viewModel.isLoading
            ? _viewModel.createFakeJobListings(10)
            : _viewModel.recentJobs;

    return Stack(
      children: [
        RefreshIndicator(
          color: Palette.primary,
          backgroundColor: Palette.white,
          edgeOffset: _headerHeight + _searchBarHeight / 2,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _headerHeight + _searchBarHeight / 2 + 20,
                ),
              ),
              SliverToBoxAdapter(
                child: JobSections(
                  recommendedJobs: recommendedJobs,
                  recentJobs: recentJobs,
                  isLoading: _viewModel.isLoading,
                  errorMessage: _viewModel.errorMessage,
                  onRetry: _viewModel.loadJobs,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: RecentJobsSliver(
                  recentJobs: recentJobs,
                  isLoading: _viewModel.isLoading,
                  errorMessage: _viewModel.errorMessage,
                  onRetry: _viewModel.loadJobs,
                ),
              ),
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
        FloatingSearchBar(
          isVisible: _isHeaderVisible,
          headerHeight: _headerHeight,
          searchBarHeight: _searchBarHeight,
        ),
      ],
    );
  }
}
