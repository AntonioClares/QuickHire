import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/features/search/viewmodel/search_viewmodel.dart';

class SearchFilters extends StatefulWidget {
  final SearchViewModel viewModel;

  const SearchFilters({super.key, required this.viewModel});

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  late List<String> _selectedTags;
  late PayType _selectedPayType;
  late double _minSalary;
  late double _maxSalary;
  late String _selectedLocation;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTags = List<String>.from(widget.viewModel.selectedTags);
    _selectedPayType = widget.viewModel.selectedPayType;
    _minSalary = widget.viewModel.minSalary;
    _maxSalary = widget.viewModel.maxSalary;
    _selectedLocation = widget.viewModel.selectedLocation;
    _locationController.text = _selectedLocation;
    _minSalaryController.text =
        _minSalary > 0 ? _minSalary.toInt().toString() : '';
    _maxSalaryController.text =
        _maxSalary < 10000 ? _maxSalary.toInt().toString() : '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.viewModel.setTagsFilter(_selectedTags);
    widget.viewModel.setPayTypeFilter(_selectedPayType);
    widget.viewModel.setSalaryRangeFilter(_minSalary, _maxSalary);
    widget.viewModel.setLocationFilter(_selectedLocation);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedTags.clear();
      _selectedPayType = PayType.all;
      _minSalary = 0.0;
      _maxSalary = 10000.0;
      _selectedLocation = '';
      _locationController.clear();
      _minSalaryController.clear();
      _maxSalaryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 50),
      decoration: const BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobTagsSection(),
                  const SizedBox(height: 24),
                  _buildPayTypeSection(),
                  const SizedBox(height: 24),
                  _buildSalaryRangeSection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Palette.background, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filter Jobs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Palette.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Job Tags'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              widget.viewModel.availableJobTags
                  .map((tag) => _buildJobTagChip(tag))
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildPayTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Payment Type'),
        const SizedBox(height: 12),
        Column(
          children:
              PayType.values.map((type) => _buildPayTypeTile(type)).toList(),
        ),
      ],
    );
  }

  Widget _buildSalaryRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Payment Range ${_selectedPayType == PayType.hourly ? '(per hour)' : '(fixed)'}',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minSalaryController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minSalary = double.tryParse(value) ?? 0.0;
                },
                style: TextStyle(color: Palette.secondary, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Min (RM)',
                  labelStyle: TextStyle(color: Palette.subtitle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Palette.background,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Palette.background,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Palette.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxSalaryController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxSalary = double.tryParse(value) ?? 10000.0;
                },
                style: TextStyle(color: Palette.secondary, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Max (RM)',
                  labelStyle: TextStyle(color: Palette.subtitle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Palette.background,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Palette.background,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Palette.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location'),
        const SizedBox(height: 12),
        TextField(
          controller: _locationController,
          onChanged: (value) {
            setState(() {
              _selectedLocation = value;
            });
          },
          style: TextStyle(color: Palette.secondary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter state or city',
            hintStyle: TextStyle(color: Palette.subtitle),
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: Palette.subtitle,
            ),
            suffixIcon:
                _locationController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Palette.subtitle),
                      onPressed: () {
                        _locationController.clear();
                        setState(() {
                          _selectedLocation = '';
                        });
                      },
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Palette.background, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Palette.background, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Palette.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLocationSuggestions(),
      ],
    );
  }

  Widget _buildLocationSuggestions() {
    final malaysianStates = [
      'Kuala Lumpur',
      'Selangor',
      'Penang',
      'Johor',
      'Perak',
      'Pahang',
      'Kedah',
      'Kelantan',
      'Terengganu',
      'Sabah',
      'Sarawak',
      'Melaka',
      'Negeri Sembilan',
      'Perlis',
      'Putrajaya',
      'Labuan',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          malaysianStates
              .map((state) => _buildLocationSuggestionChip(state))
              .toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Palette.secondary,
      ),
    );
  }

  Widget _buildJobTagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);

    return FilterChip(
      label: Text(tag),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          if (isSelected) {
            _selectedTags.remove(tag);
          } else {
            _selectedTags.add(tag);
          }
        });
      },
      backgroundColor: Palette.white,
      selectedColor: Palette.primary.withValues(alpha: 0.1),
      checkmarkColor: Palette.primary,
      labelStyle: TextStyle(
        color: isSelected ? Palette.primary : Palette.secondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? Palette.primary : Palette.background,
        width: 1.5,
      ),
    );
  }

  Widget _buildPayTypeTile(PayType type) {
    final isSelected = _selectedPayType == type;
    final displayName = _getPayTypeDisplayName(type);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPayType = type;
          // Clear salary fields when changing pay type
          if (type != PayType.all) {
            _minSalaryController.clear();
            _maxSalaryController.clear();
            _minSalary = 0.0;
            _maxSalary = 10000.0;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Palette.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Palette.primary : Palette.background,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Radio<PayType>(
              value: type,
              groupValue: _selectedPayType,
              onChanged: (value) {
                setState(() {
                  _selectedPayType = value!;
                  // Clear salary fields when changing pay type
                  if (value != PayType.all) {
                    _minSalaryController.clear();
                    _maxSalaryController.clear();
                    _minSalary = 0.0;
                    _maxSalary = 10000.0;
                  }
                });
              },
              activeColor: Palette.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Palette.primary : Palette.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSuggestionChip(String location) {
    return InkWell(
      onTap: () {
        _locationController.text = location;
        setState(() {
          _selectedLocation = location;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Palette.imagePlaceholder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          location,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Palette.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasChanges = !_areFiltersEqual();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Palette.background, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Palette.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Palette.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: hasChanges ? _applyFilters : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasChanges ? Palette.primary : Palette.imagePlaceholder,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _areFiltersEqual() {
    return _selectedTags.length == widget.viewModel.selectedTags.length &&
        _selectedTags.every(
          (tag) => widget.viewModel.selectedTags.contains(tag),
        ) &&
        _selectedPayType == widget.viewModel.selectedPayType &&
        _minSalary == widget.viewModel.minSalary &&
        _maxSalary == widget.viewModel.maxSalary &&
        _selectedLocation == widget.viewModel.selectedLocation;
  }

  String _getPayTypeDisplayName(PayType type) {
    switch (type) {
      case PayType.all:
        return 'All Payment Types';
      case PayType.hourly:
        return 'Hourly Payment';
      case PayType.basePayment:
        return 'Fixed Payment';
    }
  }
}
