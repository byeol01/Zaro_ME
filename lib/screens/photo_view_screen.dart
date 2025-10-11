import 'package:flutter/material.dart';

class PhotoViewScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const PhotoViewScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            panEnabled: false,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
