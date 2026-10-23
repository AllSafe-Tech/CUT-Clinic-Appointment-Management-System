import 'package:flutter/material.dart';

import '../core/brand.dart';

/// Compact rounded "pill" button that wraps its content (not full width).
/// Soft tinted style by default; [filled] gives a solid style with a shadow.
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = CutColors.blue,
    this.filled = false,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;
  final bool busy;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final fg = widget.filled ? Colors.white : widget.color;
    final bg = widget.filled ? widget.color : widget.color.withAlpha(22);

    return Opacity(
      opacity: (enabled || widget.busy) ? 1 : 0.5,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: widget.filled
                ? [
                    BoxShadow(
                      color: widget.color.withAlpha(70),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: bg,
            clipBehavior: Clip.antiAlias,
            shape: StadiumBorder(
              side: BorderSide(
                color: widget.filled ? Colors.transparent : widget.color.withAlpha(90),
              ),
            ),
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.busy)
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                      )
                    else
                      Icon(widget.icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}