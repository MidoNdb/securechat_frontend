// lib/core/widgets/avatar_widget.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool isGroup;
  final bool showOnlineIndicator;
  final bool isOnline;

  const AvatarWidget({
    Key? key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.isGroup = false,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _getGradient(),
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  ),
                )
              : _buildPlaceholder(),
        ),
        if (showOnlineIndicator && isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: size * 0.05,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials() {
    if (isGroup) return '👥';
    
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  LinearGradient _getGradient() {
    // Générer un gradient basé sur le hash du nom
    final hash = name.hashCode;
    final gradients = [
      LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFff5576c)],
      ),
      LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      ),
      LinearGradient(
        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
      ),
      LinearGradient(
        colors: [Color(0xFFfa709a), Color(0xFFfee140)],
      ),
      LinearGradient(
        colors: [Color(0xFF30cfd0), Color(0xFF330867)],
      ),
    ];

    return gradients[hash.abs() % gradients.length];
  }
}