import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Profile photo from the provider URL with an initials fallback. No images
/// are uploaded or stored by the app.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    required this.name,
    this.photoUrl,
    this.size = AppSizes.avatarMd,
    this.semanticLabel,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final String? semanticLabel;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p.characters.first.toUpperCase());
    return letters.join();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
    final url = photoUrl;
    final avatar = url == null || url.isEmpty
        ? fallback
        : ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : fallback,
            ),
          );
    return Semantics(
      label: semanticLabel ?? name,
      image: true,
      excludeSemantics: true,
      child: avatar,
    );
  }
}

/// Overlapping avatars for the tour top bar.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.people,
    this.max = 4,
    this.size = AppSizes.avatarSm,
    this.semanticLabel,
    super.key,
  });

  final List<({String name, String? photoUrl})> people;
  final int max;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = people.take(max).toList();
    final extra = people.length - shown.length;
    final overlap = size * 0.65;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: size + 4,
        width: count == 0 ? 0 : overlap * (count - 1) + size + 4,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: i * overlap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: MemberAvatar(
                    name: shown[i].name,
                    photoUrl: shown[i].photoUrl,
                    size: size,
                  ),
                ),
              ),
            if (extra > 0)
              Positioned(
                left: shown.length * overlap,
                child: Container(
                  width: size + 4,
                  height: size + 4,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
