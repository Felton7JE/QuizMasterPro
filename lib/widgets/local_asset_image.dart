import 'package:quizmaster_pro/widgets/loading_logo.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/asset_manager_service.dart';
import '../services/api_service.dart';

class LocalAssetImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const LocalAssetImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  _LocalAssetImageState createState() => _LocalAssetImageState();
}

class _LocalAssetImageState extends State<LocalAssetImage> {
  String? _localPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalPath();
  }

  @override
  void didUpdateWidget(covariant LocalAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadLocalPath();
    }
  }

  Future<void> _loadLocalPath() async {
    setState(() {
      _isLoading = true;
    });
    
    if (widget.imageUrl.isEmpty || !widget.imageUrl.startsWith('http')) {
      setState(() {
        _isLoading = false;
        _localPath = null;
      });
      return;
    }

    try {
      final assetManager = context.read<AssetManagerService>();
      final path = await assetManager.getLocalPath(widget.imageUrl);
      if (mounted) {
        setState(() {
          _localPath = path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: LoadingLogo(size: 60),
        ),
      );
    }

    if (_localPath != null) {
      return Image.file(
        File(_localPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _fallbackImage(),
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    // If not found locally or error, fallback to network image
    if (widget.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
        errorWidget: (context, url, error) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[800],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
        placeholder: (context, url) => SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: LoadingLogo(size: 60),
          ),
        ),
      );
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
