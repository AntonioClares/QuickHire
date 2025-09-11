import 'package:flutter/material.dart';
import 'package:quickhire/core/services/auth_service.dart';

class PosterNameWidget extends StatefulWidget {
  final String posterUid;
  final TextStyle? style;
  final bool isLoading;

  const PosterNameWidget({
    super.key,
    required this.posterUid,
    this.style,
    this.isLoading = false,
  });

  @override
  State<PosterNameWidget> createState() => _PosterNameWidgetState();
}

class _PosterNameWidgetState extends State<PosterNameWidget> {
  final AuthService _authService = AuthService();
  String _displayName = '';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void didUpdateWidget(PosterNameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posterUid != widget.posterUid) {
      _loadUserName();
    }
  }

  Future<void> _loadUserName() async {
    if (widget.isLoading) {
      setState(() {
        _displayName = 'Company Name';
        _isLoadingName = false;
      });
      return;
    }

    try {
      final userName = await _authService.getUserNameByUid(widget.posterUid);
      if (mounted) {
        setState(() {
          _displayName = userName;
          _isLoadingName = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _displayName = widget.posterUid; // Fallback to UID
          _isLoadingName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingName) {
      return Text(
        'Loading...',
        style:
            widget.style ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      );
    }

    return Text(
      _displayName,
      style:
          widget.style ??
          const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );
  }
}
