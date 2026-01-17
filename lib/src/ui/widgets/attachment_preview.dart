import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../feeddo_client.dart';

class AttachmentPreview extends StatefulWidget {
  final String url;
  final String? contentType;
  final String? fileName;

  const AttachmentPreview({
    super.key,
    required this.url,
    this.contentType,
    this.fileName,
  });

  @override
  State<AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<AttachmentPreview> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _initializeVideo();
    }
  }

  bool get _isVideo {
    if (widget.contentType != null) {
      return widget.contentType!.startsWith('video/');
    }
    final ext = widget.fileName?.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'webm'].contains(ext);
  }

  bool get _isImage {
    if (widget.contentType != null) {
      return widget.contentType!.startsWith('image/');
    }
    final ext = widget.fileName?.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  Future<void> _initializeVideo() async {
    try {
      // If URL is relative, prepend base URL
      final videoUrl = widget.url.startsWith('http') 
          ? widget.url 
          : '${FeeddoInternal.instance.apiService.apiUrl.replaceAll('/api', '')}${widget.url}';

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {'x-api-key': FeeddoInternal.instance.apiService.apiKey},
      );
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      // If URL is relative, prepend base URL
      final imageUrl = widget.url.startsWith('http') 
          ? widget.url 
          : '${FeeddoInternal.instance.apiService.apiUrl.replaceAll('/api', '')}${widget.url}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          headers: {'x-api-key': FeeddoInternal.instance.apiService.apiKey},
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _buildErrorWidget(),
        ),
      );
    }

    if (_isVideo) {
      if (_error != null) {
        return _buildErrorWidget();
      }
      if (!_isInitialized) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      return Container(
        width: 200,
        height: 200 / _videoController!.value.aspectRatio,
        constraints: const BoxConstraints(maxHeight: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Chewie(
            controller: _chewieController!,
          ),
        ),
      );
    }

    // Fallback for other file types
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.fileName ?? 'Attachment',
              style: const TextStyle(color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(height: 8),
          Text(
            widget.fileName ?? 'Error loading file',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
