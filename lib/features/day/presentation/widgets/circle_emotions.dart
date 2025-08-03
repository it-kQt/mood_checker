import "dart:math" as math;
import "package:flutter/material.dart";

class CircleEmotionItem {
final String id;
final String label;
final String emoji;
final Color color;

CircleEmotionItem({
required this.id,
required this.label,
required this.emoji,
required this.color,
});
}

class CircleEmotions extends StatelessWidget {
static const double _buttonSize = 56;
static const double _labelWidth = 80;
final List<CircleEmotionItem> items;
final void Function(CircleEmotionItem) onTap;
final double minRadius;
final double maxEmojiSize;

const CircleEmotions({
super.key,
required this.items,
required this.onTap,
this.minRadius = 70,
this.maxEmojiSize = 28,
});

@override
Widget build(BuildContext context) {
final count = items.length.clamp(1, 999);
final radius = minRadius + (count > 8 ? (count - 8) * 6.0 : 0.0);
final emojiSize = (maxEmojiSize - (count > 10 ? (count - 10) * 1.2 : 0))
.clamp(18, maxEmojiSize);


return Center(
  child: SizedBox(
    width: radius * 2 + 80,
    height: radius * 2 + 80,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
          ),
        ),
        for (int i = 0; i < count; i++)
          _buildItem(context, i, count, radius, items[i], emojiSize.toDouble()),
      ],
    ),
  ),
);
}

Widget _buildItem(BuildContext ctx, int index, int total, double r, CircleEmotionItem item, double emojiSize) {
  final angle = (2 * math.pi / total) * index - math.pi / 2;
  final cx = r * math.cos(angle);
  final cy = r * math.sin(angle);

  return Positioned(
    left: cx + r + 40 - (_buttonSize / 2),
    top: cy + r + 40 - (_buttonSize / 2),
    child: Tooltip(
      message: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(_buttonSize / 2),
        onTap: () => onTap(item),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _buttonSize,
              height: _buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withOpacity(0.12),
                border: Border.all(color: item.color.withOpacity(0.6)),
              ),
              alignment: Alignment.center,
              child: Text(item.emoji, style: TextStyle(fontSize: emojiSize)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: _labelWidth,
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
